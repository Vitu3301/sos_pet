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
}
