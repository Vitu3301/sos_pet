import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toCache() => {
        'id': id,
        'name': name,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'type': type.name,
        'address': address,
        'phone': phone,
        'website': website,
      };

  static NearbyPlace? fromCache(Map<String, dynamic> map) {
    final latitude = map['latitude'];
    final longitude = map['longitude'];
    if (latitude is! num || longitude is! num) return null;

    final type = map['type'] == 'adoption'
        ? NearbyPlaceType.adoption
        : NearbyPlaceType.shelter;

    return NearbyPlace(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Abrigo de animais',
      position: LatLng(latitude.toDouble(), longitude.toDouble()),
      type: type,
      distanceKm: 0,
      address: map['address']?.toString(),
      phone: map['phone']?.toString(),
      website: map['website']?.toString(),
    );
  }

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

class _NearbyPlacesCache {
  const _NearbyPlacesCache(this.timestamp, this.places);

  final DateTime timestamp;
  final List<NearbyPlace> places;
}

class NearbyPlacesService {
  NearbyPlacesService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _freshCacheDuration = Duration(hours: 24);
  static const Duration _staleCacheDuration = Duration(days: 7);

  Future<List<NearbyPlace>> findNear(LatLng origin) async {
    final cacheKey = _cacheKey(origin);
    final cached = await _readCache(cacheKey);
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _freshCacheDuration) {
      return _placesForOrigin(cached.places, origin);
    }

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

    const endpoints = [
      'overpass-api.de',
      'overpass.kumi.systems',
    ];
    int? lastStatusCode;
    Object? lastNetworkError;

    for (final host in endpoints) {
      http.Response response;
      try {
        response = await _client.post(
          Uri.https(host, '/api/interpreter'),
          headers: const {'User-Agent': 'SOSPet/1.0'},
          body: {'data': query},
        ).timeout(const Duration(seconds: 20));
      } on TimeoutException catch (error) {
        lastNetworkError = error;
        continue;
      } on http.ClientException catch (error) {
        lastNetworkError = error;
        continue;
      }

      if (response.statusCode != 200) {
        lastStatusCode = response.statusCode;
        if (response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504) {
          continue;
        }
        continue;
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
      places.sort(
          (first, second) => first.distanceKm.compareTo(second.distanceKm));
      await _writeCache(cacheKey, places);
      return places;
    }

    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _staleCacheDuration) {
      return _placesForOrigin(cached.places, origin);
    }

    if (lastStatusCode != null) {
      throw NearbyPlacesException(
        'Os serviços de mapas estão temporariamente indisponíveis '
        '(código $lastStatusCode). Tente novamente em instantes.',
      );
    }
    throw NearbyPlacesException(
      lastNetworkError == null
          ? 'Não foi possível conectar aos serviços de mapas.'
          : 'Não foi possível conectar aos serviços de mapas. '
              'Verifique sua conexão e tente novamente.',
    );
  }

  String _cacheKey(LatLng origin) {
    final latGrid = (origin.latitude / 0.1).round();
    final lonGrid = (origin.longitude / 0.1).round();
    return 'nearby_places_${latGrid}_$lonGrid';
  }

  Future<_NearbyPlacesCache?> _readCache(String cacheKey) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(cacheKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final timestamp =
          DateTime.tryParse(decoded['timestamp']?.toString() ?? '');
      final rawPlaces = decoded['places'];
      if (timestamp == null || rawPlaces is! List) return null;

      final places = <NearbyPlace>[];
      for (final rawPlace in rawPlaces) {
        if (rawPlace is! Map) continue;
        final place =
            NearbyPlace.fromCache(Map<String, dynamic>.from(rawPlace));
        if (place != null) places.add(place);
      }
      return _NearbyPlacesCache(timestamp, places);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String cacheKey,
    List<NearbyPlace> places,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = {
      'timestamp': DateTime.now().toIso8601String(),
      'places': places.map((place) => place.toCache()).toList(),
    };
    await preferences.setString(cacheKey, jsonEncode(payload));
  }

  List<NearbyPlace> _placesForOrigin(
    List<NearbyPlace> places,
    LatLng origin,
  ) {
    final recalculated = places
        .map(
          (place) => NearbyPlace(
            id: place.id,
            name: place.name,
            position: place.position,
            type: place.type,
            distanceKm: NearbyPlace._distanceInKilometers(
              origin.latitude,
              origin.longitude,
              place.position.latitude,
              place.position.longitude,
            ),
            address: place.address,
            phone: place.phone,
            website: place.website,
          ),
        )
        .toList()
      ..sort((first, second) => first.distanceKm.compareTo(second.distanceKm));
    return recalculated;
  }

  void dispose() => _client.close();
}
