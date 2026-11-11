import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final PetModel pet;
  final String ownerUid;
  final String? ownerName;

  const ChatScreen({
    super.key,
    required this.pet,
    required this.ownerUid,
    this.ownerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  String? _conversationId;
  String? _currentUid;
  String _currentName = 'Usuário';
  String _ownerName = 'Responsável';
  String? _initializationError;
  bool _isInitializing = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    setState(() {
      _isInitializing = true;
      _initializationError = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isInitializing = false;
        _initializationError = 'Entre na sua conta para acessar as conversas.';
      });
      return;
    }

    if (widget.pet.id == null || widget.ownerUid == user.uid) {
      setState(() {
        _isInitializing = false;
        _initializationError = 'Não foi possível iniciar esta conversa.';
      });
      return;
    }

    _currentUid = user.uid;

    try {
      final currentProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final currentData = currentProfile.data();
      _currentName = _nameFrom(
        currentData?['nome'],
        user.displayName,
        'Usuário',
      );

      if (widget.ownerName != null && widget.ownerName!.trim().isNotEmpty) {
        _ownerName = widget.ownerName!.trim();
      }

      final id = await ChatService.instance.openConversation(
        petId: widget.pet.id!,
        petName: widget.pet.nome,
        petPhoto: widget.pet.foto,
        currentUid: user.uid,
        currentName: _currentName,
        ownerUid: widget.ownerUid,
        ownerName: _ownerName,
      );

      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _isInitializing = false;
      });
    } catch (error) {
      debugPrint('Erro ao iniciar conversa: $error');
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initializationError =
            'Não foi possível carregar a conversa. Tente novamente.';
      });
    }
  }

  String _nameFrom(
    Object? profileName,
    String? displayName,
    String fallback,
  ) {
    for (final candidate in [profileName, displayName]) {
      final name = candidate?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    return fallback;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final senderUid = _currentUid;
    final conversationId = _conversationId;
    if (text.isEmpty ||
        senderUid == null ||
        conversationId == null ||
        _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      await ChatService.instance.sendMessage(
        conversationId: conversationId,
        senderUid: senderUid,
        senderName: _currentName,
        text: text,
      );
      if (mounted && _messageController.text.trim() == text) {
        _messageController.clear();
      }
    } catch (error) {
      debugPrint('Erro ao enviar mensagem: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar a mensagem.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
            Text(
              'Sobre ${widget.pet.nome}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : _initializationError != null
                ? _buildInitializationError()
                : Column(
                    children: [
                      Expanded(child: _buildMessages()),
                      _buildMessageComposer(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInitializationError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _initializationError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _initializeConversation,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    final conversationId = _conversationId;
    if (conversationId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Não foi possível carregar as mensagens.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        final messages = snapshot.data?.docs ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Envie uma mensagem para iniciar a conversa sobre ${widget.pet.nome}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data();
            final isMine = message['senderId'] == _currentUid;
            final text = (message['text'] ?? '').toString();
            final timestamp = message['createdAt'];
            final sentAt = timestamp is Timestamp ? timestamp.toDate() : null;

            return Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                ),
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine ? Colors.orange : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: isMine ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 15,
                      ),
                    ),
                    if (sentAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        TimeOfDay.fromDateTime(sentAt).format(context),
                        style: TextStyle(
                          color: isMine ? Colors.white70 : Colors.grey.shade500,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Escreva uma mensagem...',
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
