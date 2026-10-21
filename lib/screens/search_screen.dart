import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'pet_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final List<PetModel> _pets = [
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
    const PetModel(
      nome: 'Luna',
      raca: 'Poodle',
      status: 'Para Adoção',
      local: 'Olinda',
      resumo:
          'Poodle encantadora, muito sociável e adora brincar com outros animais.',
      foto:
          'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?auto=format&fit=crop&w=900&q=80',
    ),
    const PetModel(
      nome: 'Thor',
      raca: 'Pastor Alemão',
      status: 'Perdido',
      local: 'Jaboatão',
      resumo:
          'Muito dócil e atento, costuma responder ao nome e sempre usa guia.',
      foto:
          'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=900&q=80',
    ),
  ];

  String _filtroStatus = 'Todos';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PetModel> get _petsFiltrados {
    final texto = _controller.text.trim().toLowerCase();

    return _pets.where((pet) {
      final atendeStatus =
          _filtroStatus == 'Todos' || pet.status == _filtroStatus;
      final atendeTexto = texto.isEmpty ||
          pet.nome.toLowerCase().contains(texto) ||
          pet.local.toLowerCase().contains(texto) ||
          pet.raca.toLowerCase().contains(texto);
      return atendeStatus && atendeTexto;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pets = _petsFiltrados;

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
              Expanded(
                child: pets.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum pet encontrado.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: pets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final pet = pets[index];
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
                                      pet.foto,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pet.nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pet.raca,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                            ),
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
                                              Text(
                                                pet.local,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
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
                                        borderRadius:
                                            BorderRadius.circular(999),
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
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
