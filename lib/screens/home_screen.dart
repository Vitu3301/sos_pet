import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'pet_form_add.dart';
import 'dart:io';

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
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _petsMock.length,
        itemBuilder: (context, index) {
          final pet = _petsMock[index];
          return _buildPetCard(pet);
        },
      ),

      // BOTÃO EXPANSÍVEL (SpeedDial)
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        activeBackgroundColor: Colors.red,
        activeForegroundColor: Colors.white,
        spacing: 10,
        spaceBetweenChildren: 8,
        children: [
          // 1. Cadastrar
          SpeedDialChild(
            child: const Icon(Icons.add),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Cadastrar Animal',
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            onTap: () async {
              // Navega para a tela de formulário e ESPERA o resultado voltar
              final novoPet = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PetFormScreen()),
              );

              // Se retornou um pet (o usuário não cancelou/voltou pelo botão de voltar)
              if (novoPet != null) {
                setState(() {
                  _petsMock.add(novoPet); // Adiciona na lista
                });

                // Exibe uma mensagem de sucesso na parte inferior da tela
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${novoPet['nome']} cadastrado com sucesso!')),
                  );
                }
              }
            },
          ),
          // 2. Editar
          SpeedDialChild(
            child: const Icon(Icons.edit),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Editar Animal',
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            onTap: () {
              _showEditPetDialog(context);
            },
          ),
          // 3. Remover
          SpeedDialChild(
            child: const Icon(Icons.delete),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: 'Remover Animal',
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            onTap: () {
              _showRemovePetDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    Color statusColor = pet['status'] == 'Perdido' ? Colors.red : Colors.green;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pet['foto'].toString().startsWith('http')
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          ),
        ],
      ),
    );
  }

  // Função do popup de remoção que criamos anteriormente
  void _showRemovePetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione um animal para remover'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _petsMock.length,
              itemBuilder: (context, index) {
                final pet = _petsMock[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(pet['foto']),
                  ),
                  title: Text(pet['nome'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pet['raca']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // Remove o item da lista Mock atualizando a tela
                      setState(() {
                        _petsMock.removeAt(index);
                      });

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('${pet['nome']} removido com sucesso!')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  // Função para exibir o Popup de edição
  void _showEditPetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Selecione um animal para editar'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _petsMock.length,
              itemBuilder: (context, index) {
                final pet = _petsMock[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: pet['foto'].toString().startsWith('http')
                        ? NetworkImage(pet['foto']) as ImageProvider
                        : FileImage(File(pet['foto'])),
                  ),
                  title: Text(pet['nome'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(pet['raca']),
                  trailing: const Icon(Icons.edit, color: Colors.blue),
                  onTap: () async {
                    // 1. Fecha o popup de seleção
                    Navigator.of(dialogContext).pop();

                    // 2. Abre a tela de formulário passando os dados do pet selecionado
                    final petEditado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetFormScreen(petParaEditar: pet),
                      ),
                    );

                    // 3. Se o usuário salvou e voltou com dados novos, atualiza a lista!
                    if (petEditado != null) {
                      setState(() {
                        _petsMock[index] =
                            petEditado; // Substitui o pet antigo pelo novo na mesma posição
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${petEditado['nome']} atualizado com sucesso!')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }
}
