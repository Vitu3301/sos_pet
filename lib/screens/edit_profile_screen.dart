import 'package:flutter/material.dart';
import '../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _cidadeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.user.nome);
    _telefoneController = TextEditingController(text: widget.user.telefone);
    _cidadeController = TextEditingController(text: 'Recife, PE');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        _nomeController.text.isNotEmpty
                            ? _nomeController.text[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nomeController,
                      decoration: _inputDecoration('Nome', Icons.person),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Telefone', Icons.phone),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _cidadeController,
                      decoration: _inputDecoration('Cidade', Icons.location_on),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedUser = UserModel(
                            uid: widget.user.uid,
                            nome: _nomeController.text.trim().isEmpty
                                ? widget.user.nome
                                : _nomeController.text.trim(),
                            email: widget.user.email,
                            telefone: _telefoneController.text.trim().isEmpty
                                ? widget.user.telefone
                                : _telefoneController.text.trim(),
                            fotoUrl: widget.user.fotoUrl,
                            criadoEm: widget.user.criadoEm,
                          );

                          Navigator.pop(context, updatedUser);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Salvar alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.orange.shade700),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }
}
