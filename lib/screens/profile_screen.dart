import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  bool _isSaving = false;
  bool _isUpdatingPassword = false;
  bool _isLoadingProfile = false;
  String _selectedPreference = 'Qualquer';
  String _photoUrl = '';
  XFile? _pickedPhoto;

  final List<String> _adoptionOptions = [
    'Qualquer',
    'Filhotes',
    'Adultos',
    'Idosos',
    'Porte pequeno',
    'Porte médio',
    'Porte grande',
  ];

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController.text = user?.displayName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _emailController.text = user?.email ?? '';
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _initialLetter {
    final user = _auth.currentUser;
    final base = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.trim().isNotEmpty == true ? user!.email! : 'T');

    return base.substring(0, 1).toUpperCase();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoadingProfile = true);

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        _selectedPreference = 'Qualquer';
        return;
      }

      final data = doc.data() ?? {};
      final profileName = (data['name'] ?? '').toString();
      final profilePhone = (data['phone'] ?? '').toString();
      final profileEmail = (data['email'] ?? user.email ?? '').toString();
      final profilePreference = (data['preference'] ?? 'Qualquer').toString();
      final profilePhotoUrl = (data['photoUrl'] ?? '').toString();

      if (mounted) {
        _nameController.text =
            profileName.isNotEmpty ? profileName : user.displayName ?? '';
        _phoneController.text = profilePhone;
        _emailController.text = profileEmail;
        _selectedPreference = profilePreference;
        _photoUrl = profilePhotoUrl;
        setState(() {});
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os dados do perfil.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _changeProfilePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _pickedPhoto = pickedFile;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome para continuar.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String uploadedPhotoUrl = _photoUrl;
      if (_pickedPhoto != null) {
        final file = File(_pickedPhoto!.path);
        final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
        await ref.putFile(file);
        uploadedPhotoUrl = await ref.getDownloadURL();
      }

      if (name != (user.displayName ?? '')) {
        await user.updateDisplayName(name);
      }

      if (email.isNotEmpty && email != (user.email ?? '')) {
        await user.verifyBeforeUpdateEmail(email);
      }

      final profileData = {
        'name': name,
        'phone': phone,
        'email': email,
        'preference': _selectedPreference,
        'photoUrl': uploadedPhotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(
            profileData,
            SetOptions(merge: true),
          );

      _photoUrl = uploadedPhotoUrl;
      await user.reload();

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            email != (user.email ?? '')
                ? 'Perfil salvo. Verifique seu e-mail para confirmar a troca.'
                : 'Perfil atualizado com sucesso.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      String message = 'Não foi possível atualizar o perfil.';

      if (error.code == 'requires-recent-login') {
        message = 'Faça login novamente para alterar seu e-mail.';
      } else if (error.code == 'invalid-email') {
        message = 'Informe um e-mail válido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o perfil no Firestore.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A nova senha deve ter no mínimo 6 caracteres.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await user.updatePassword(password);
      _passwordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      String message = 'Não foi possível alterar a senha.';

      if (error.code == 'weak-password') {
        message = 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      } else if (error.code == 'requires-recent-login') {
        message = 'Faça login novamente para trocar sua senha.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('E-mail não disponível para redefinição.')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de redefinição enviado.')),
      );
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar o e-mail de redefinição.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAdoptionPreference() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Preferência para adoção'),
          children: _adoptionOptions
              .map(
                (option) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, option),
                  child: Text(option),
                ),
              )
              .toList(),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedPreference = selected);
    }
  }

  Future<void> _contactUs() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contato: suporte@sospet.app'),
      ),
    );
  }

  Future<void> _privacyPolicy() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Política de privacidade em desenvolvimento.'),
      ),
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Widget _buildAvatar() {
    if (_pickedPhoto != null) {
      return ClipOval(
        child: Image.file(
          File(_pickedPhoto!.path),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _photoUrl,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initialLetter,
          style: const TextStyle(
            color: Colors.deepOrange,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'E-mail não informado';
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Olá, tutor!';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Meu perfil'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Stack(
                      children: [
                        _buildAvatar(),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.orange,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: _changeProfilePhoto,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Editar perfil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Salvar perfil'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Segurança',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUpdatingPassword
                                      ? null
                                      : _updatePassword,
                                  icon: const Icon(Icons.lock_reset),
                                  label: const Text('Alterar senha'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: _resetPassword,
                                  icon: const Icon(Icons.email_outlined),
                                  label: const Text('Recuperar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.pets, color: Colors.orange),
                          title: const Text('Meus animais'),
                          subtitle:
                              const Text('Gerenciar seus pets cadastrados'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lista de pets em breve.'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.favorite_border,
                              color: Colors.orange),
                          title: const Text('Preferência para adoção'),
                          subtitle: Text(_selectedPreference),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickAdoptionPreference,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.support_agent_outlined,
                            color: Colors.orange,
                          ),
                          title: const Text('Contact us'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _contactUs,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.privacy_tip_outlined,
                            color: Colors.orange,
                          ),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _privacyPolicy,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Sair da conta'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
