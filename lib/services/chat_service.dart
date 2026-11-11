import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String conversationId({
    required String petId,
    required String currentUid,
    required String ownerUid,
  }) {
    final participants = [currentUid, ownerUid]..sort();
    final identity = jsonEncode([petId, ...participants]);
    return base64Url.encode(utf8.encode(identity)).replaceAll('=', '');
  }

  Future<String> openConversation({
    required String petId,
    required String petName,
    required String petPhoto,
    required String currentUid,
    required String currentName,
    required String ownerUid,
    required String ownerName,
  }) async {
    final id = conversationId(
      petId: petId,
      currentUid: currentUid,
      ownerUid: ownerUid,
    );
    final conversation = _firestore.collection('chats').doc(id);
    final participants = [currentUid, ownerUid];

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversation);
      final unreadCounts = Map<String, dynamic>.from(
        snapshot.data()?['unreadCountByUid'] as Map<dynamic, dynamic>? ?? {},
      )..[currentUid] = 0;
      transaction.set(
        conversation,
        {
          'participantIds': participants,
          'participantNames': {
            currentUid: currentName,
            ownerUid: ownerName,
          },
          'petId': petId,
          'petName': petName,
          'petPhoto': petPhoto,
          'unreadCountByUid': unreadCounts,
          if (!snapshot.exists) ...{
            'lastMessage': '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessageAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    });

    return id;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderUid,
    required String senderName,
    required String text,
  }) async {
    final conversation = _firestore.collection('chats').doc(conversationId);
    final message = conversation.collection('messages').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversation);
      if (!snapshot.exists) {
        throw StateError('A conversa não existe mais.');
      }

      final data = snapshot.data()!;
      final participants = (data['participantIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList();
      if (!participants.contains(senderUid)) {
        throw StateError('O usuário não participa desta conversa.');
      }

      final unreadCounts = Map<String, dynamic>.from(
        data['unreadCountByUid'] as Map<dynamic, dynamic>? ?? {},
      );
      for (final participant in participants) {
        unreadCounts[participant] = participant == senderUid
            ? 0
            : ((unreadCounts[participant] as num?)?.toInt() ?? 0) + 1;
      }

      transaction.set(
        message,
        {
          'senderId': senderUid,
          'senderName': senderName,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      transaction.set(
        conversation,
        {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'lastMessageSenderId': senderUid,
          'unreadCountByUid': unreadCounts,
          'hiddenFor': [],
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> hideConversationForUser({
    required String conversationId,
    required String userUid,
  }) async {
    final conversation = _firestore.collection('chats').doc(conversationId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversation);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final participants =
          (data['participantIds'] as List<dynamic>? ?? []).whereType<String>();
      if (!participants.contains(userUid)) {
        throw StateError('O usuário não participa desta conversa.');
      }

      final hiddenFor = (data['hiddenFor'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toSet()
        ..add(userUid);
      final unreadCounts = Map<String, dynamic>.from(
        data['unreadCountByUid'] as Map<dynamic, dynamic>? ?? {},
      )..[userUid] = 0;

      transaction.set(
        conversation,
        {
          'hiddenFor': hiddenFor.toList(),
          'unreadCountByUid': unreadCounts,
        },
        SetOptions(merge: true),
      );
    });
  }
}
