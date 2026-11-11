import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../models/user_model.dart';
import '../services/user_service.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  String? _firebaseUid;
  bool _checkedConversationNotifications = false;

  @override
  void initState() {
    super.initState();
    _carregarUsuarioAtual();
    _firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnreadConversationNotifications();
    });
  }

  Future<void> _showUnreadConversationNotifications() async {
    final uid = _firebaseUid;
    if (_checkedConversationNotifications || uid == null) return;
    _checkedConversationNotifications = true;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participantIds', arrayContains: uid)
          .get();
      final unreadConversations = snapshot.docs.where((conversation) {
        final data = conversation.data();
        final hiddenFor =
            (data['hiddenFor'] as List<dynamic>? ?? []).whereType<String>();
        final unreadCounts = data['unreadCountByUid'];
        final unreadCount = unreadCounts is Map
            ? (unreadCounts[uid] as num?)?.toInt() ?? 0
            : 0;
        return !hiddenFor.contains(uid) && unreadCount > 0;
      }).toList()
        ..sort((a, b) {
          final aDate = a.data()['lastMessageAt'];
          final bDate = b.data()['lastMessageAt'];
          final aTime = aDate is Timestamp ? aDate.toDate() : DateTime(1970);
          final bTime = bDate is Timestamp ? bDate.toDate() : DateTime(1970);
          return bTime.compareTo(aTime);
        });

      if (!mounted || unreadConversations.isEmpty) return;

      final openInbox = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mark_chat_unread_outlined, color: Color(0xFFE97832)),
              SizedBox(width: 10),
              Expanded(child: Text('Novas respostas')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadConversations.length == 1
                      ? 'Você recebeu uma resposta em uma conversa:'
                      : 'Você recebeu respostas em ${unreadConversations.length} conversas:',
                ),
                const SizedBox(height: 12),
                ...unreadConversations.take(4).map((conversation) {
                  final data = conversation.data();
                  final names = data['participantNames'];
                  final participantNames = names is Map
                      ? Map<String, dynamic>.from(names)
                      : <String, dynamic>{};
                  final participants =
                      (data['participantIds'] as List<dynamic>? ?? [])
                          .whereType<String>();
                  final otherUid = participants.firstWhere(
                    (participant) => participant != uid,
                    orElse: () => '',
                  );
                  final responder =
                      (participantNames[otherUid] ?? 'Responsável').toString();
                  final petName = (data['petName'] ?? 'pet').toString();
                  final lastMessage =
                      (data['lastMessage'] ?? '').toString().trim();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '$responder respondeu sobre $petName'
                      '${lastMessage.isEmpty ? '' : ': $lastMessage'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                if (unreadConversations.length > 4)
                  Text(
                    'E mais ${unreadConversations.length - 4} conversas...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Depois'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ver conversas'),
            ),
          ],
        ),
      );

      if (openInbox == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ConversationsScreen(),
          ),
        );
      }
    } catch (error) {
      debugPrint('Erro ao buscar respostas não lidas: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível verificar novas respostas.'),
          ),
        );
      }
    }
  }

  Future<void> _carregarUsuarioAtual() async {
    final usuario = await UserSessionService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = usuario;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F3),
      appBar: AppBar(
        title: Text(
          _currentUser != null
              ? 'Olá, ${_currentUser!.nome.split(' ').first}'
              : 'SOS Pet',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: Color(0xFF28231F),
          ),
        ),
        backgroundColor: const Color(0xFFFFF9F3),
        foregroundColor: const Color(0xFF51473F),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Conversas',
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConversationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Conta',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (value == 'logout') {
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Meu perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // StreamBuilder escutando as mudanças no Firestore em tempo real
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pets')
              .orderBy('dataAtualizacao', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE97832)),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível carregar os pets agora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF655B53)),
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            // Calcula os totais dinamicamente baseados no banco de dados!
            int totalPerdidos = docs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['status'] == 'Perdido')
                .length;
            int totalAdocao = docs
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['status'] ==
                    'Para Adoção')
                .length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFAA61), Color(0xFFE97832)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE97832).withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'COMUNIDADE SOS PET',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Todo pet merece\num final feliz.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    height: 1.12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ajude a encontrar, adotar e cuidar de quem precisa.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _summaryChip(
                              '$totalPerdidos perdidos', Colors.red.shade50),
                          const SizedBox(width: 10),
                          _summaryChip(
                              '$totalAdocao para adoção', Colors.green.shade50),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perto de você',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: Color(0xFF28231F),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Pets da nossa comunidade',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF85796F),
                            ),
                          ),
                        ],
                      ),
                      if (docs.isNotEmpty)
                        Text(
                          '${docs.length} ${docs.length == 1 ? 'pet' : 'pets'}',
                          style: const TextStyle(
                            color: Color(0xFF9A6A4D),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                if (docs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1E8DF)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1E5),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            color: Color(0xFFE97832),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Ainda não há pets por aqui',
                          style: TextStyle(
                            color: Color(0xFF39312B),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Seja o primeiro a compartilhar um anúncio com a comunidade.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF85796F),
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...docs.map((doc) {
                  final petData = doc.data() as Map<String, dynamic>;
                  final String docId = doc.id;
                  final pet = PetModel.fromMap(docId, petData);

                  // Verifica se o usuário atual é o dono deste pet
                  final bool isDono =
                      _firebaseUid != null && _firebaseUid == pet.donoUid;

                  return _buildPetCard(pet, docId, isDono);
                }),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarPet,
        backgroundColor: const Color(0xFFE97832),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Anunciar pet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _summaryChip(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: bgColor == Colors.red.shade50
                  ? const Color(0xFFE65A53)
                  : const Color(0xFF4E9A68),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF51473F),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PetFormScreen()),
    );
    // Não é necessário usar setState ou atualizar lista, o StreamBuilder atualiza a tela automaticamente!
  }

  Future<void> _editarPet(PetModel pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetFormScreen(petParaEditar: pet),
      ),
    );
  }

  void _removerPet(PetModel pet, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover animal'),
        content: const Text(
            'Deseja realmente remover este pet da lista? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Fecha o dialog

              try {
                // 1. Apaga do Firestore
                await FirebaseFirestore.instance
                    .collection('pets')
                    .doc(docId)
                    .delete();

                // 2. Apaga a imagem do Supabase
                if (pet.foto.contains('supabase.co') &&
                    pet.foto.contains('pets_images/')) {
                  final partes = pet.foto.split('pets_images/');
                  if (partes.length > 1) {
                    final caminhoArquivo = partes[1].split('?').first;
                    await Supabase.instance.client.storage
                        .from('pets_images')
                        .remove([caminhoArquivo]);
                  }
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${pet.nome} foi removido com sucesso!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao remover: $e')),
                  );
                }
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(PetModel pet, String docId, bool isDono) {
    final isPerdido = pet.status == 'Perdido';
    final statusColor =
        isPerdido ? const Color(0xFFD95650) : const Color(0xFF438B5A);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF1E8DF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              kIsWeb || pet.foto.startsWith('http')
                  ? Image.network(
                      pet.foto.isNotEmpty
                          ? pet.foto
                          : 'https://via.placeholder.com/400x220',
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _imagePlaceholder(),
                    )
                  : Image.file(
                      File(pet.foto),
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _imagePlaceholder(),
                    ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPerdido
                            ? Icons.search_rounded
                            : Icons.favorite_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        pet.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Color(0xFF28231F),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 15,
                      color: Color(0xFFB07D5F),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        pet.raca,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF776B62),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFFB07D5F),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        pet.local,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF776B62),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1E8DF)),
                const SizedBox(height: 7),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 2,
                  runSpacing: 0,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetDetailScreen(pet: pet),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Ver detalhes'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE97832),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (isDono) ...[
                      TextButton.icon(
                        onPressed: () => _editarPet(pet),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6D777D),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _removerPet(pet, docId),
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Remover'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD95650),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 210,
      width: double.infinity,
      color: const Color(0xFFFFF1E5),
      child: const Center(
        child: Icon(
          Icons.pets_rounded,
          color: Color(0xFFE4B89A),
          size: 46,
        ),
      ),
    );
  }
}
