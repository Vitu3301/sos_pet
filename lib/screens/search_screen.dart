import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import 'pet_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _filtroStatus = 'Todos';
  bool _mostrarMapa = false;
  final MapController _mapController = MapController();
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
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.list_rounded),
                          label: Text('Lista'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.map_outlined),
                          label: Text('Mapa'),
                        ),
                      ],
                      selected: {_mostrarMapa},
                      onSelectionChanged: (selection) {
                        setState(() => _mostrarMapa = selection.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista ou mapa dos resultados em tempo real do Firebase
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('pets').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.orange));
                    }

                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Erro ao carregar os dados.'));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // 1. Converte os documentos do Firebase para PetModel
                    final List<PetModel> todosPets = docs.map((doc) {
                      final petData = doc.data() as Map<String, dynamic>;
                      return PetModel.fromMap(doc.id, petData);
                    }).toList();

                    // 2. Aplica o filtro de texto e status localmente
                    final textoPesquisa = _controller.text.trim().toLowerCase();
                    final petsFiltrados = todosPets.where((pet) {
                      final atendeStatus = _filtroStatus == 'Todos' ||
                          pet.status == _filtroStatus;
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

                    if (_mostrarMapa) {
                      final petsComLocalizacao =
                          petsFiltrados.where((pet) =>
                              pet.latitude != null && pet.longitude != null).toList();
                      if (petsComLocalizacao.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhum dos resultados possui localização no mapa.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      final center = LatLng(
                        petsComLocalizacao.first.latitude!,
                        petsComLocalizacao.first.longitude!,
                      );
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: center,
                                initialZoom: 12,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'sos_pet',
                                ),
                                MarkerLayer(
                                  markers: petsComLocalizacao
                                      .map(
                                        (pet) => Marker(
                                          point: LatLng(
                                            pet.latitude!,
                                            pet.longitude!,
                                          ),
                                          width: 48,
                                          height: 48,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PetDetailScreen(pet: pet),
                                                ),
                                              );
                                            },
                                            child: Icon(
                                              Icons.pets,
                                              color: pet.status == 'Perdido'
                                                  ? Colors.red
                                                  : Colors.green,
                                              size: 42,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                            const Positioned(
                              left: 8,
                              bottom: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white70,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  child: Text(
                                    '© OpenStreetMap contributors',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                    pet.foto.isNotEmpty
                                        ? pet.foto
                                        : 'https://via.placeholder.com/150',
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey),
                                    ),
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
