import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_pet/models/user_model.dart';

void main() {
  group('PetModel.fromMap', () {
    test('uses safe defaults when optional data is missing', () {
      final pet = PetModel.fromMap(null, {});

      expect(pet.id, isNull);
      expect(pet.nome, isEmpty);
      expect(pet.raca, isEmpty);
      expect(pet.local, isEmpty);
      expect(pet.status, isEmpty);
      expect(pet.foto, isEmpty);
      expect(pet.resumo, isEmpty);
      expect(pet.latitude, isNull);
      expect(pet.longitude, isNull);
      expect(pet.dataAtualizacao, isNull);
      expect(pet.toMap()['dataAtualizacao'], isA<FieldValue>());
    });

    test('converts integer coordinates and Firestore timestamps', () {
      final updatedAt = DateTime(2025, 3, 10, 12, 30);
      final pet = PetModel.fromMap('pet-1', {
        'latitude': -8,
        'longitude': -34,
        'dataAtualizacao': Timestamp.fromDate(updatedAt),
      });

      expect(pet.latitude, -8.0);
      expect(pet.longitude, -34.0);
      expect(pet.dataAtualizacao, updatedAt);
      expect(pet.toMap()['dataAtualizacao'], Timestamp.fromDate(updatedAt));
    });
  });
}
