import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'notifications_screen.dart';
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

  final List<PetModel> _petsMock = [
    const PetModel(
      nome: 'Rex',
      raca: 'Golden Retriever',
      status: 'Perdido',
      local: 'Camaragibe',
      resumo:
          'Cão muito amigável, usa coleira azul e foi visto perto do bairro.',
      foto:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=900&q=80',
    ),
    const PetModel(
      nome: 'Mimi',
      raca: 'SRD (Vira-lata)',
      status: 'Para Adoção',
      local: 'Recife',
      resumo:
          'Gata carinhosa, porte pequeno, muito tranquila com crianças e outros pets.',
      foto:
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carregarUsuarioAtual();
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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          _currentUser != null
              ? 'Olá, ${_currentUser!.nome.split(' ').first}'
              : 'SOS Pet',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                // CORREÇÃO: Removido o 'const'
                MaterialPageRoute(builder: (_) => SearchScreen()),
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
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                // CORREÇÃO: Removido o 'const'
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Animais em destaque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.favorite,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ajude a localizar, adotar e cuidar de pets em situação vulnerável.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _summaryChip('2 perdidos', Colors.red.shade50),
                      const SizedBox(width: 10),
                      _summaryChip('1 para adoção', Colors.green.shade50),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Pets da comunidade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            ...List.generate(_petsMock.length, (index) {
              final pet = _petsMock[index];
              return _buildPetCard(pet, index);
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarPet,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  Widget _summaryChip(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _adicionarPet() async {
    final novoPet = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PetFormScreen()),
    );

    if (!mounted) return;

    if (novoPet != null) {
      setState(() {
        _petsMock.add(novoPet);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${novoPet.nome} registrado com sucesso!')),
      );
    }
  }

  Future<void> _editarPet(PetModel pet, int index) async {
    final petEditado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetFormScreen(petParaEditar: pet),
      ),
    );

    if (!mounted) return;

    if (petEditado != null) {
      setState(() {
        _petsMock[index] = petEditado;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${petEditado.nome} atualizado com sucesso!')),
      );
    }
  }

  void _removerPet(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover animal'),
        content: const Text('Deseja realmente remover este pet da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final petRemovido = _petsMock[index];
              setState(() {
                _petsMock.removeAt(index);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${petRemovido.nome} foi removido!')),
              );
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(PetModel pet, int index) {
    final statusColor = pet.status == 'Perdido' ? Colors.red : Colors.green;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              kIsWeb || pet.foto.startsWith('http')
                  ? Image.network(
                      pet.foto,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(pet.foto),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pet.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // CORREÇÃO: Trocado pet['nome'] por pet.nome
                          pet.nome,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // CORREÇÃO: Removido formatação quebrada do git e usado atributos corretos
                          '${pet.raca} • ${pet.local}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        // CORREÇÃO: Trocado pet['status'] por pet.status
                        pet.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Detalhes'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _editarPet(pet, index),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _removerPet(index),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remover'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}