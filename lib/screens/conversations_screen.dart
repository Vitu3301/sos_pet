import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Conversas'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: currentUser == null
          ? const Center(
              child: Text('Entre na sua conta para ver as conversas.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participantIds', arrayContains: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Não foi possível carregar as conversas.'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                final conversations =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  snapshot.data?.docs ?? [],
                )..sort((a, b) {
                        final aDate = _dateFrom(a.data()['lastMessageAt']);
                        final bDate = _dateFrom(b.data()['lastMessageAt']);
                        return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0))
                            .compareTo(
                          aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
                        );
                      });
                conversations.removeWhere((conversation) {
                  final hiddenFor =
                      (conversation.data()['hiddenFor'] as List<dynamic>? ?? [])
                          .whereType<String>();
                  return hiddenFor.contains(currentUser.uid);
                });

                if (conversations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Suas conversas com responsáveis por pets aparecerão aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final document = conversations[index];
                    final data = document.data();
                    final participantIds =
                        (data['participantIds'] as List<dynamic>? ?? [])
                            .whereType<String>()
                            .toList();
                    final ownerUid = participantIds.firstWhere(
                      (id) => id != currentUser.uid,
                      orElse: () => '',
                    );
                    final petId = (data['petId'] ?? '').toString();
                    final petName = (data['petName'] ?? 'Pet').toString();
                    final names = data['participantNames'];
                    final participantNames = names is Map
                        ? Map<String, dynamic>.from(names)
                        : <String, dynamic>{};
                    final ownerName =
                        (participantNames[ownerUid] ?? 'Responsável')
                            .toString();
                    final lastMessage =
                        (data['lastMessage'] ?? '').toString().trim();
                    final unreadCounts = data['unreadCountByUid'];
                    final unreadCount = unreadCounts is Map
                        ? (unreadCounts[currentUser.uid] as num?)?.toInt() ?? 0
                        : 0;

                    return Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        leading:
                            _petAvatar((data['petPhoto'] ?? '').toString()),
                        title: Text(
                          ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage.isEmpty
                              ? 'Conversa sobre $petName'
                              : '$petName · $lastMessage',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (unreadCount > 0)
                              Container(
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              tooltip: 'Opções da conversa',
                              onSelected: (action) {
                                if (action == 'delete') {
                                  _confirmAndHideConversation(
                                    context,
                                    document.id,
                                    currentUser.uid,
                                    ownerName,
                                    petName,
                                  );
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Excluir conversa'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: ownerUid.isEmpty
                            ? null
                            : () {
                                final pet = PetModel(
                                  id: petId,
                                  nome: petName,
                                  raca: '',
                                  local: '',
                                  status: '',
                                  foto: (data['petPhoto'] ?? '').toString(),
                                  donoUid: ownerUid,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      pet: pet,
                                      ownerUid: ownerUid,
                                      ownerName: ownerName,
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _petAvatar(String photoUrl) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.orange.shade50,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? const Icon(Icons.pets, color: Colors.orange)
          : null,
    );
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Future<void> _confirmAndHideConversation(
    BuildContext context,
    String conversationId,
    String userUid,
    String otherName,
    String petName,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conversa?'),
        content: Text(
          'A conversa sobre $petName será ocultada apenas para você. '
          '$otherName ainda poderá vê-la e enviar uma nova mensagem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    try {
      await ChatService.instance.hideConversationForUser(
        conversationId: conversationId,
        userUid: userUid,
      );
    } catch (error) {
      debugPrint('Erro ao ocultar conversa: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir a conversa.')),
        );
      }
    }
  }
}
