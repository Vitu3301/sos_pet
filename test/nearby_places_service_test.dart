import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sos_pet/services/nearby_places_service.dart';

void main() {
  const origin = LatLng(-8.05, -34.9);

  group('NearbyPlace.fromOverpass', () {
    test('parses adoption locations and calculates their distance', () {
      final place = NearbyPlace.fromOverpass(
        {
          'type': 'node',
          'id': 42,
          'lat': -8.06,
          'lon': -34.91,
          'tags': {
            'name': 'Projeto Patas',
            'animal_adoption': 'yes',
            'addr:street': 'Rua das Flores',
            'addr:housenumber': '10',
            'addr:city': 'Recife',
            'phone': '81999990000',
          },
        },
        origin,
      );

      expect(place, isNotNull);
      expect(place!.name, 'Projeto Patas');
      expect(place.type, NearbyPlaceType.adoption);
      expect(place.address, 'Rua das Flores, 10 - Recife');
      expect(place.phone, '81999990000');
      expect(place.distanceKm, greaterThan(0));
    });

    test('uses the center coordinates for buildings and defaults to shelter',
        () {
      final place = NearbyPlace.fromOverpass(
        {
          'type': 'way',
          'id': 7,
          'center': {'lat': -8.05, 'lon': -34.9},
          'tags': {'amenity': 'animal_shelter'},
        },
        origin,
      );

      expect(place, isNotNull);
      expect(place!.name, 'Abrigo de animais');
      expect(place.type, NearbyPlaceType.shelter);
      expect(place.distanceKm, 0);
    });

    test('ignores incomplete map elements', () {
      expect(NearbyPlace.fromOverpass({'id': 1}, origin), isNull);
      expect(
        NearbyPlace.fromOverpass(
          {
            'id': 2,
            'tags': <String, String>{'name': 'Sem coordenadas'}
          },
          origin,
        ),
        isNull,
      );
    });
  });

  group('NearbyPlacesService.findNear', () {
    test('uses the backup endpoint after a temporary gateway error', () async {
      final requestedHosts = <String>[];
      final service = NearbyPlacesService(
        client: MockClient((request) async {
          requestedHosts.add(request.url.host);
          if (requestedHosts.length == 1) {
            return http.Response('temporarily unavailable', 502);
          }
          return http.Response('{"elements":[]}', 200);
        }),
      );
      addTearDown(service.dispose);

      final places = await service.findNear(origin);

      expect(places, isEmpty);
      expect(requestedHosts, [
        'overpass-api.de',
        'overpass.kumi.systems',
      ]);
    });

    test('reports an error when both endpoints return gateway errors',
        () async {
      final service = NearbyPlacesService(
        client: MockClient(
          (_) async => http.Response('temporarily unavailable', 502),
        ),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.findNear(origin),
        throwsA(
          isA<NearbyPlacesException>().having(
            (error) => error.message,
            'message',
            contains('código 502'),
          ),
        ),
      );
    });

    test('sorts results by distance and removes duplicate OpenStreetMap ids',
        () async {
      final service = NearbyPlacesService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'elements': [
                {
                  'type': 'node',
                  'id': 1,
                  'lat': -8.06,
                  'lon': -34.9,
                  'tags': {'name': 'Mais distante'},
                },
                {
                  'type': 'node',
                  'id': 2,
                  'lat': -8.051,
                  'lon': -34.9,
                  'tags': {'name': 'Mais próxima'},
                },
                {
                  'type': 'node',
                  'id': 2,
                  'lat': -8.07,
                  'lon': -34.9,
                  'tags': {'name': 'Duplicada'},
                },
              ],
            }),
            200,
          ),
        ),
      );
      addTearDown(service.dispose);

      final places = await service.findNear(origin);

      expect(places.map((place) => place.name), [
        'Mais próxima',
        'Mais distante',
      ]);
      expect(places.map((place) => place.id), ['node/2', 'node/1']);
    });

    test('does not retry a non-temporary response error', () async {
      final requestedHosts = <String>[];
      final service = NearbyPlacesService(
        client: MockClient((request) async {
          requestedHosts.add(request.url.host);
          return http.Response('bad request', 400);
        }),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.findNear(origin),
        throwsA(
          isA<NearbyPlacesException>().having(
            (error) => error.message,
            'message',
            contains('código 400'),
          ),
        ),
      );
      expect(requestedHosts, ['overpass-api.de']);
    });

    test('rejects a successful response with an invalid payload', () async {
      final service = NearbyPlacesService(
        client: MockClient(
          (_) async => http.Response('{"elements":{}}', 200),
        ),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.findNear(origin),
        throwsA(
          isA<NearbyPlacesException>().having(
            (error) => error.message,
            'message',
            contains('dados inválidos'),
          ),
        ),
      );
    });
  });
}
