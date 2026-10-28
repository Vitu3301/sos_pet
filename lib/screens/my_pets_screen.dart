import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;import '../models/user_model.dart';
import 'pet_detail_screen.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  final User? _usuarioAtual = FirebaseAuth.instance.currentUser;

  // Função para deletar o pet do Firestore e a imagem do Supabase
  Future<void> _deletarPet(String petId, String urlImagem) async {
    try {
      // 1. Apaga os dados do banco de dados (Firebase)
      await FirebaseFirestore.instance.collection('pets').doc(petId).delete();

      // 2. Apaga a imagem do armazenamento (Supabase)
      if (urlImagem.contains('supabase.co') && urlImagem.contains('pets_images/')) {
        // Extrai o caminho exato do arquivo (ex: "UID/nome_da_imagem.jpg")
        final partes = urlImagem.split('pets_images/');
        if (partes.length > 1) {
          final caminhoArquivo = partes[1].split('?').first;
          await Supabase.instance.client.storage
              .from('pets_images')
              .remove([caminhoArquivo]);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet removido com sucesso.')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao excluir pet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir pet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Meus pets'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _usuarioAtual == null
          ? const Center(
              child: Text(
                'Você precisa estar logado para ver seus pets.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : SafeArea(
              child: StreamBuilder<QuerySnapshot>(
                // Escuta as alterações no banco em tempo real, filtrando pelo UID do dono
                stream: FirebaseFirestore.instance
                    .collection('pets')
                    .where('dono_uid', isEqualTo: _usuarioAtual!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.orange));
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Erro ao carregar os dados.'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Card de Resumo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total cadastrado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${docs.length} pets',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.pets,
                                    color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista de Pets
                        Expanded(
                          child: docs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Você ainda não cadastrou nenhum pet.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final petData = docs[index].data() as Map<String, dynamic>;
                                    final docId = docs[index].id;

                                    // Converte o Map do Firebase para o seu PetModel
                                    final pet = PetModel(
                                      id: docId,
                                      nome: petData['nome'] ?? 'Sem nome',
                                      raca: petData['raca'] ?? 'Desconhecida',
                                      status: petData['status'] ?? 'Indefinido',
                                      local: petData['local'] ?? 'Desconhecido',
                                      resumo: petData['resumo'] ?? '',
                                      foto: petData['foto'] ?? '',
                                    );

                                    // Permite deslizar para a esquerda para excluir
                                    return Dismissible(
                                      key: Key(docId),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade400,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(Icons.delete, color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir Pet?'),
                                            content: const Text('Tem certeza que deseja apagar este pet? Esta ação não pode ser desfeita.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (direction) {
                                        _deletarPet(docId, pet.foto);
                                      },
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PetDetailScreen(pet: pet),
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
                                                      : 'https://via.placeholder.com/150', // Imagem de fallback
                                                  width: 110,
                                                  height: 110,
                                                  fit: BoxFit.cover,
                                                  // Tratamento para caso a imagem demore a carregar ou dê erro
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Container(
                                                    width: 110,
                                                    height: 110,
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
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
                                                      const SizedBox(height: 8),
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
                                                padding: const EdgeInsets.only(
                                                    right: 12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 7,
                                                  ),
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
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}