import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // DADOS FALSOS (Mock) - Para visualizar a interface antes do Firebase
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
      backgroundColor:
          Colors.grey[100], // Fundo levemente cinza para destacar os cards
      appBar: AppBar(
        title: const Text('SOS Pet',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        actions: [
          // Botão de Sair (Logout)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Futuramente aqui chamaremos o FirebaseAuth para deslogar
              Navigator.pop(context); // Volta para a tela de login por enquanto
            },
          )
        ],
      ),

      // O ListView.builder é a melhor forma de criar listas no Flutter
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _petsMock.length, // Quantidade de itens na nossa lista falsa
        itemBuilder: (context, index) {
          final pet = _petsMock[index];
          return _buildPetCard(pet); // Chama a função que desenha o card
        },
      ),

      // Botão Flutuante (Floating Action Button) - O "Create" do CRUD
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          // Futuramente: Navigator.push para a tela pet_form_screen
          print("Navegar para a tela de cadastrar pet");
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- WIDGET PERSONALIZADO PARA O CARD ---
  // Separar isso do "build" principal deixa o código muito mais organizado e fácil de ler
  Widget _buildPetCard(Map<String, dynamic> pet) {
    // Regra visual: Vermelho para perdido, Verde para adoção
    Color statusColor = pet['status'] == 'Perdido' ? Colors.red : Colors.green;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip
          .antiAlias, // Corta a imagem para respeitar as bordas arredondadas do card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Foto do Pet usando imagem da internet
          Image.network(
            pet['foto'],
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover, // Preenche todo o espaço sem distorcer
          ),

          // 2. Área de Texto
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Coluna com Nome e Raça/Local
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

                // Etiqueta de Status (Perdido/Adoção)
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
}
