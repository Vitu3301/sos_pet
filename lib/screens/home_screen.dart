import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'pet_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // DADOS FALSOS (Mock)
  final List<Map<String, dynamic>> _petsMock = [
    {
      'nome': 'Rex',
      'raca': 'Golden Retriever',
      'status': 'Perdido',
      'local': 'Camaragibe',
      'foto':
          'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=300&q=80',
    },
    {
      'nome': 'Mimi',
      'raca': 'SRD (Vira-lata)',
      'status': 'Para Adoção',
      'local': 'Recife',
      'foto':
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=300&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('SOS Pet',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _petsMock.length,
        itemBuilder: (context, index) {
          final pet = _petsMock[index];
          // Agora passamos o index para saber qual animal estamos a manipular
          return _buildPetCard(pet, index);
        },
      ),
      // Botão Flutuante Simples (apenas para adicionar novo pet)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onPressed: _adicionarPet,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- FUNÇÕES DE NAVEGAÇÃO E AÇÃO ---

  Future<void> _adicionarPet() async {
    final novoPet = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PetFormScreen()),
    );

    if (novoPet != null) {
      setState(() {
        _petsMock.add(novoPet);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${novoPet['nome']} registado com sucesso!')),
      );
    }
  }

  Future<void> _editarPet(Map<String, dynamic> pet, int index) async {
    final petEditado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetFormScreen(petParaEditar: pet),
      ),
    );

    if (petEditado != null) {
      setState(() {
        _petsMock[index] = petEditado;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${petEditado['nome']} atualizado com sucesso!')),
      );
    }
  }

  void _removerPet(int index) {
    // Diálogo de confirmação antes de remover
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Animal'),
        content:
            const Text('Tem a certeza de que deseja remover este registo?'),
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
              Navigator.pop(ctx); // Fecha o diálogo
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${petRemovido['nome']} foi removido!')),
              );
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DO CARTÃO ---

  Widget _buildPetCard(Map<String, dynamic> pet, int index) {
    Color statusColor = pet['status'] == 'Perdido' ? Colors.red : Colors.green;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Foto do Pet (Internet, Galeria ou Web)
          kIsWeb || pet['foto'].toString().startsWith('http')
              ? Image.network(
                  pet['foto'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(pet['foto']),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

          // 2. Área de Texto e Ações
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Informações Principais
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet['nome'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet['raca']} • ${pet['local']}',
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
                        pet['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(
                    height:
                        30), // Uma linha subtil para separar a info dos botões

                // Botões de Ação (Editar e Remover)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text('Editar',
                          style: TextStyle(color: Colors.blue)),
                      onPressed: () => _editarPet(pet, index),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Remover',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => _removerPet(index),
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
