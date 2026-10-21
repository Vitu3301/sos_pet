<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_screen.dart';
=======
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'edit_profile_screen.dart';
import 'my_pets_screen.dart';
import 'settings_screen.dart';
>>>>>>> 1f6f5ee7409e3b7767ba4e266ce56780899c5eef

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
<<<<<<< HEAD
  final _nameController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isSaving = false;
=======
  UserModel? _user;
  bool _isLoading = true;
>>>>>>> 1f6f5ee7409e3b7767ba4e266ce56780899c5eef

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _nameController.text = _auth.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await _auth.currentUser?.updateDisplayName(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome atualizado com sucesso.')),
      );
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar o nome.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email == null) return;

    await _auth.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-mail de redefinição enviado.')),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
=======
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final usuario = await UserSessionService.instance.getCurrentUser();

    if (!mounted) return;

    setState(() {
      _user = usuario ??
          const UserModel(
            uid: 'demo-user',
            nome: 'Pet Lover',
            email: 'petlover@sospet.com',
            telefone: '(81) 99999-0000',
          );
      _isLoading = false;
    });
>>>>>>> 1f6f5ee7409e3b7767ba4e266ce56780899c5eef
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final user = _auth.currentUser;
    final email = user?.email ?? 'E-mail não informado';
    final initial =
        (user?.displayName?.isNotEmpty == true ? user!.displayName! : email)
            .substring(0, 1)
            .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.orange.shade100,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.deepOrange,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : 'Olá, tutor!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(email, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveName,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Salvar nome'),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          ),
          const Divider(height: 40),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_reset, color: Colors.orange),
            title: const Text('Redefinir senha'),
            subtitle: const Text('Receber um link por e-mail'),
            onTap: _resetPassword,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair'),
            onTap: _signOut,
=======
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final nome = _user?.nome ?? 'Pet Lover';
    final email = _user?.email ?? 'petlover@sospet.com';
    final telefone = _user?.telefone ?? '(81) 99999-0000';
    final fotoUrl = _user?.fotoUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.orange.shade100,
                    backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                        ? NetworkImage(fotoUrl)
                        : null,
                    child: fotoUrl == null || fotoUrl.isEmpty
                        ? Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statCard('Pets', '12', Colors.orange.shade50,
                      Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard('Ajudas', '8', Colors.green.shade50,
                      Colors.green.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.phone, 'Telefone', telefone),
                  const Divider(height: 24),
                  _infoRow(Icons.location_on, 'Cidade', 'Recife, PE'),
                  const Divider(height: 24),
                  _infoRow(Icons.volunteer_activism, 'Status', 'Voluntário'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.pets, color: Colors.orange),
                    title: const Text('Meus pets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyPetsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.orange),
                    title: const Text('Editar perfil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final updatedUser = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: _user!),
                        ),
                      );

                      if (!mounted || updatedUser == null) return;

                      setState(() => _user = updatedUser);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.orange),
                    title: const Text('Configurações'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.help_outline, color: Colors.orange),
                    title: const Text('Ajuda e suporte'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, Color bgColor, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
>>>>>>> 1f6f5ee7409e3b7767ba4e266ce56780899c5eef
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
>>>>>>> 1f6f5ee7409e3b7767ba4e266ce56780899c5eef
}
