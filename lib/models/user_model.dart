import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final DateTime? criadoEm;
  final String? fotoUrl;

  const UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.telefone,
    this.criadoEm,
    this.fotoUrl,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    final timestamp = map['criadoEm'];

    return UserModel(
      uid: uid,
      nome: (map['nome'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      telefone: (map['telefone'] ?? '').toString(),
      criadoEm: timestamp is Timestamp ? timestamp.toDate() : null,
      fotoUrl: map['fotoUrl']?.toString(),
    );
  }

  factory UserModel.fromFirebaseUser(User user, {String telefone = ''}) {
    return UserModel(
      uid: user.uid,
      nome: user.displayName ?? '',
      email: user.email ?? '',
      telefone: telefone,
      criadoEm: user.metadata.creationTime ?? DateTime.now(),
      fotoUrl: user.photoURL,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'fotoUrl': fotoUrl,
      'criadoEm': criadoEm != null
          ? Timestamp.fromDate(criadoEm!)
          : FieldValue.serverTimestamp(),
    };
  }
}

class PetModel {
  final String? id;
  final String nome;
  final String raca;
  final String local;
  final String status;
  final String foto;
  final String resumo;
  final DateTime? dataAtualizacao;

  const PetModel({
    this.id,
    required this.nome,
    required this.raca,
    required this.local,
    required this.status,
    required this.foto,
    this.resumo = '',
    this.dataAtualizacao,
  });

  factory PetModel.fromMap(String? id, Map<String, dynamic> map) {
    final timestamp = map['dataAtualizacao'];

    return PetModel(
      id: id,
      nome: (map['nome'] ?? '').toString(),
      raca: (map['raca'] ?? '').toString(),
      local: (map['local'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      foto: (map['foto'] ?? '').toString(),
      resumo: (map['resumo'] ?? '').toString(),
      dataAtualizacao: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'raca': raca,
      'local': local,
      'status': status,
      'foto': foto,
      'resumo': resumo,
      'dataAtualizacao': dataAtualizacao != null
          ? Timestamp.fromDate(dataAtualizacao!)
          : FieldValue.serverTimestamp(),
    };
  }
}
