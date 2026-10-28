import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'pet_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _filtroStatus = 'Todos';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Buscar pets'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Campo de texto para pesquisa
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, raça ou local',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filtro de Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filtroStatus,
                    isExpanded: true,
                    items: ['Todos', 'Perdido', 'Para Adoção']
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _filtroStatus = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Lista de resultados em tempo real do Firebase
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('pets').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.orange));
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Erro ao carregar os dados.'));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // 1. Converte os documentos do Firebase para PetModel
                    final List<PetModel> todosPets = docs.map((doc) {
                      final petData = doc.data() as Map<String, dynamic>;
                      return PetModel(
                        id: doc.id,
                        nome: petData['nome'] ?? 'Sem nome',
                        raca: petData['raca'] ?? 'Desconhecida',
                        status: petData['status'] ?? 'Indefinido',
                        local: petData['local'] ?? 'Desconhecido',
                        resumo: petData['resumo'] ?? '',
                        foto: petData['foto'] ?? '',
                      );
                    }).toList();

                    // 2. Aplica o filtro de texto e status localmente
                    final textoPesquisa = _controller.text.trim().toLowerCase();
                    final petsFiltrados = todosPets.where((pet) {
                      final atendeStatus = _filtroStatus == 'Todos' || pet.status == _filtroStatus;
                      final atendeTexto = textoPesquisa.isEmpty ||
                          pet.nome.toLowerCase().contains(textoPesquisa) ||
                          pet.local.toLowerCase().contains(textoPesquisa) ||
                          pet.raca.toLowerCase().contains(textoPesquisa);
                      return atendeStatus && atendeTexto;
                    }).toList();

                    if (petsFiltrados.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum pet encontrado.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    // 3. Renderiza a lista filtrada
                    return ListView.separated(
                      itemCount: petsFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pet = petsFiltrados[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PetDetailScreen(pet: pet),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    bottomLeft: Radius.circular(18),
                                  ),
                                  child: Image.network(
                                    pet.foto.isNotEmpty ? pet.foto : 'https://via.placeholder.com/150',
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pet.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Color(0xFF1F2937),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pet.raca,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                pet.local,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: pet.status == 'Perdido'
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      pet.status,
                                      style: TextStyle(
                                        color: pet.status == 'Perdido'
                                            ? Colors.red.shade700
                                            : Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}