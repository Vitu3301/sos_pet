import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum NearbyPlaceType { adoption, shelter }

class NearbyPlace {
  const NearbyPlace({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    required this.distanceKm,
    this.address,
    this.phone,
    this.website,
  });

  final String id;
  final String name;
  final LatLng position;
  final NearbyPlaceType type;
  final double distanceKm;
  final String? address;
  final String? phone;
  final String? website;

  static NearbyPlace? fromOverpass(
    Map<String, dynamic> element,
    LatLng origin,
  ) {
    final rawTags = element['tags'];
    if (rawTags is! Map) return null;
    final tags = rawTags.map<String, String>(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
    String? firstNonEmptyTag(List<String> keys) {
      for (final key in keys) {
        final value = tags[key]?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final latitude = element['lat'] ??
        (element['center'] is Map ? element['center']['lat'] : null);
    final longitude = element['lon'] ??
        (element['center'] is Map ? element['center']['lon'] : null);
    if (latitude is! num || longitude is! num) return null;

    final shelterType = (tags['animal_shelter'] ?? '').toLowerCase();
    final isAdoption = tags['animal_adoption'] == 'yes' ||
        tags['adoption'] == 'yes' ||
        shelterType.contains('adoption');
    final street = tags['addr:street'];
    final houseNumber = tags['addr:housenumber'];
    final neighborhood = tags['addr:suburb'];
    final city = tags['addr:city'];
    final addressParts = [
      if (street != null && street.isNotEmpty)
        [street, houseNumber]
            .whereType<String>()
            .where((part) => part.isNotEmpty)
            .join(', '),
      if (neighborhood != null && neighborhood.isNotEmpty) neighborhood,
      if (city != null && city.isNotEmpty) city,
    ];

    return NearbyPlace(
      id: '${element['type']}/${element['id']}',
      name: tags['name'] ?? tags['official_name'] ?? 'Abrigo de animais',
      position: LatLng(latitude.toDouble(), longitude.toDouble()),
      type: isAdoption ? NearbyPlaceType.adoption : NearbyPlaceType.shelter,
      distanceKm: _distanceInKilometers(
        origin.latitude,
        origin.longitude,
        latitude.toDouble(),
        longitude.toDouble(),
      ),
      address: addressParts.isEmpty ? null : addressParts.join(' - '),
      phone: firstNonEmptyTag(
          ['phone', 'contact:phone', 'mobile', 'contact:mobile']),
      website: firstNonEmptyTag(['website', 'contact:website', 'url']),
    );
  }

  static double _distanceInKilometers(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _toRadians(latitude2 - latitude1);
    final longitudeDelta = _toRadians(longitude2 - longitude1);
    final a = math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_toRadians(latitude1)) *
            math.cos(_toRadians(latitude2)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}

class NearbyPlacesException implements Exception {
  const NearbyPlacesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NearbyPlacesService {
  NearbyPlacesService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<NearbyPlace>> findNear(LatLng origin) async {
    final latitude = origin.latitude;
    final longitude = origin.longitude;
    final query = '''
[out:json][timeout:25];
(
  nwr(around:15000,$latitude,$longitude)["amenity"="animal_shelter"];
  nwr(around:15000,$latitude,$longitude)["social_facility"="animal_shelter"];
  nwr(around:15000,$latitude,$longitude)["animal_shelter"];
  nwr(around:15000,$latitude,$longitude)["animal_adoption"="yes"];
);
out center tags;
''';

    final response = await _client.post(
      Uri.https('overpass-api.de', '/api/interpreter'),
      headers: const {'User-Agent': 'SOSPet/1.0'},
      body: {'data': query},
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw NearbyPlacesException(
        'O serviço de mapas respondeu com o código ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
      throw const NearbyPlacesException(
          'O serviço de mapas retornou dados inválidos.');
    }

    final places = <NearbyPlace>[];
    final seenIds = <String>{};
    for (final element in decoded['elements'] as List) {
      if (element is! Map<String, dynamic>) continue;
      final place = NearbyPlace.fromOverpass(element, origin);
      if (place != null && seenIds.add(place.id)) places.add(place);
    }
    places
        .sort((first, second) => first.distanceKm.compareTo(second.distanceKm));
    return places;
  }

  void dispose() => _client.close();
}
