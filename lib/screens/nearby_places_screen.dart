import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/nearby_places_service.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final MapController _mapController = MapController();
  final NearbyPlacesService _placesService = NearbyPlacesService();

  LatLng? _userLocation;
  List<NearbyPlace> _places = [];
  bool _isLoading = true;
  bool _permissionPermanentlyDenied = false;
  String? _errorMessage;
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  @override
  void dispose() {
    _placesService.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _permissionPermanentlyDenied = false;
      _userLocation = null;
      _places = [];
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const NearbyPlacesException(
          'Ative a localização do aparelho para encontrar locais próximos.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const NearbyPlacesException(
          'A permissão de localização é necessária para buscar locais próximos.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        _permissionPermanentlyDenied = true;
        throw const NearbyPlacesException(
          'A localização foi bloqueada. Habilite a permissão nas configurações do aparelho.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final location = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _userLocation = location);

      final places = await _placesService.findNear(location);
      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'A busca demorou demais. Verifique a conexão e tente novamente.';
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  List<NearbyPlace> get _filteredPlaces => _places.where((place) {
        switch (_selectedFilter) {
          case 'Adoção':
            return place.type == NearbyPlaceType.adoption;
          case 'Acolhimento':
            return place.type == NearbyPlaceType.shelter;
          default:
            return true;
        }
      }).toList();

  @override
  Widget build(BuildContext context) {
    final places = _filteredPlaces;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Locais próximos'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adoção e acolhimento de animais',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sua posição é consultada pelo OpenStreetMap (sem ser salva no SOS Pet) para buscar locais em até 15 km.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Para animais de rua ou que não possa manter, confirme antes se o local recebe animais; não deixe o pet sem autorização.',
                    style: TextStyle(color: Colors.brown, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['Todos', 'Adoção', 'Acolhimento'].map((filter) {
                      return ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        selectedColor: Colors.orange.shade100,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (_isLoading) const LinearProgressIndicator(color: Colors.orange),
            Expanded(
              child: _userLocation == null
                  ? _buildLocationState()
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _userLocation!,
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'sos_pet',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _userLocation!,
                                  width: 42,
                                  height: 42,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                ),
                                ...places.map(_buildPlaceMarker),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: FloatingActionButton.small(
                            heroTag: 'my-location',
                            tooltip: 'Voltar para minha localização',
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepOrange,
                            onPressed: () =>
                                _mapController.move(_userLocation!, 14),
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                        if (_errorMessage != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: _errorBanner(),
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
            ),
            _buildPlacesList(places),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationState() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_searching,
                color: Colors.orange, size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Não foi possível acessar sua localização.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_permissionPermanentlyDenied)
              const OutlinedButton(
                onPressed: Geolocator.openAppSettings,
                child: Text('Abrir configurações'),
              ),
            ElevatedButton.icon(
              onPressed: _loadNearbyPlaces,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Expanded(
                child:
                    Text(_errorMessage!, style: const TextStyle(fontSize: 12))),
            TextButton(
              onPressed: _loadNearbyPlaces,
              child: const Text('Tentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList(List<NearbyPlace> places) {
    if (_isLoading && places.isEmpty) {
      return const SizedBox(
        height: 86,
        child: Center(child: Text('Buscando abrigos e locais de adoção...')),
      );
    }
    if (places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Text(
          _errorMessage == null
              ? 'Nenhum local encontrado nesta categoria. A cobertura depende dos cadastros do OpenStreetMap.'
              : 'Não foi possível carregar os locais. Tente novamente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final place = places[index];
          final color = _placeColor(place);
          return SizedBox(
            width: 250,
            child: Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _mapController.move(place.position, 16);
                  _showPlaceDetails(place);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pets, color: color, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              place.type == NearbyPlaceType.adoption
                                  ? 'Adoção'
                                  : 'Acolhimento',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('${place.distanceKm.toStringAsFixed(1)} km'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (place.address != null)
                        Text(
                          place.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12),
                        ),
                      const Spacer(),
                      const Text(
                        'Toque para ver detalhes',
                        style:
                            TextStyle(color: Colors.deepOrange, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Marker _buildPlaceMarker(NearbyPlace place) {
    final color = _placeColor(place);
    return Marker(
      point: place.position,
      width: 46,
      height: 52,
      child: GestureDetector(
        onTap: () => _showPlaceDetails(place),
        child: Column(
          children: [
            Icon(Icons.location_on, color: color, size: 38),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _placeColor(NearbyPlace place) => place.type == NearbyPlaceType.adoption
      ? Colors.green.shade700
      : Colors.deepOrange;

  void _showPlaceDetails(NearbyPlace place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                place.type == NearbyPlaceType.adoption
                    ? 'Adoção de animais'
                    : 'Abrigo / acolhimento',
                style: TextStyle(
                    color: _placeColor(place), fontWeight: FontWeight.w600),
              ),
              if (place.address != null) ...[
                const SizedBox(height: 10),
                Text(place.address!),
              ],
              if (place.phone != null) ...[
                const SizedBox(height: 6),
                SelectableText('Telefone: ${place.phone}'),
              ],
              if (place.website != null) ...[
                const SizedBox(height: 6),
                SelectableText(place.website!),
              ],
              const SizedBox(height: 12),
              const Text(
                'Confirme por telefone ou site se o local está aberto e recebe animais antes de se deslocar. Não deixe o animal sem autorização.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Dados colaborativos do OpenStreetMap · ${place.distanceKm.toStringAsFixed(1)} km de você',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
