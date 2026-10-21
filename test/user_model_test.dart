import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sos_pet/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create model from Firestore map', () {
      final createdAt = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));

      final user = UserModel.fromMap('abc123', {
        'nome': 'Maria',
        'email': 'maria@email.com',
        'telefone': '(81) 99999-0000',
        'criadoEm': createdAt,
        'fotoUrl': 'https://example.com/avatar.png',
      });

      expect(user.uid, 'abc123');
      expect(user.nome, 'Maria');
      expect(user.email, 'maria@email.com');
      expect(user.telefone, '(81) 99999-0000');
      expect(user.criadoEm, createdAt.toDate());
      expect(user.fotoUrl, 'https://example.com/avatar.png');
    });

    test('should convert model to map', () {
      final user = UserModel(
        uid: 'abc123',
        nome: 'Maria',
        email: 'maria@email.com',
        telefone: '(81) 99999-0000',
        criadoEm: DateTime(2024, 1, 15, 10, 30),
        fotoUrl: 'https://example.com/avatar.png',
      );

      final map = user.toMap();

      expect(map['nome'], 'Maria');
      expect(map['email'], 'maria@email.com');
      expect(map['telefone'], '(81) 99999-0000');
      expect(map['fotoUrl'], 'https://example.com/avatar.png');
      expect(map['criadoEm'], isA<Timestamp>());
    });
  });

  group('PetModel', () {
    test('should create pet from map and convert back to map', () {
      final pet = PetModel.fromMap('pet-1', {
        'nome': 'Rex',
        'raca': 'Golden Retriever',
        'local': 'Recife',
        'status': 'Perdido',
        'foto': 'https://example.com/rex.png',
        'resumo': 'Cão muito carinhoso e muito atento ao dono.',
      });

      expect(pet.id, 'pet-1');
      expect(pet.nome, 'Rex');
      expect(pet.status, 'Perdido');
      expect(pet.resumo, 'Cão muito carinhoso e muito atento ao dono.');
      expect(pet.toMap()['local'], 'Recife');
      expect(
          pet.toMap()['resumo'], 'Cão muito carinhoso e muito atento ao dono.');
    });
  });
}
