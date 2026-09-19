import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto originais
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // NOVOS controladores para o Cadastro
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _aceitouTermos = false; // Controle do Checkbox

  @override
  void dispose() {
    // É uma boa prática limpar os controladores da memória ao fechar a tela
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // Função que envia os dados para o Firebase
  void _submit() async {
    // 1. Valida se os campos estão corretos
    if (!_formKey.currentState!.validate()) return;

    // 2. Validação extra para os Termos de Uso no Cadastro
    if (!_isLogin && !_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Você precisa aceitar os Termos de Uso para se cadastrar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    // Ativa o "carregando" e redesenha a tela
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // --- FLUXO DE LOGIN ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: senha,
        );
      } else {
        // --- FLUXO DE CADASTRO ---
        UserCredential credencial =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: senha,
        );

        // Salva o nome do usuário no perfil do Firebase Auth
        await credencial.user!.updateDisplayName(_nomeController.text.trim());

        // DICA: O telefone (_telefoneController.text) e outros dados extras
        // geralmente são salvos no banco de dados (Firestore) nesta etapa!
      }

      // Se der certo, navega para a tela principal e remove a tela de login do histórico
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (error) {
      String mensagemErro = 'Ocorreu um erro. Verifique seus dados.';

      if (error.code == 'user-not-found') {
        mensagemErro = 'Nenhum usuário encontrado com este e-mail.';
      } else if (error.code == 'wrong-password') {
        mensagemErro = 'Senha incorreta.';
      } else if (error.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está cadastrado.';
      } else if (error.code == 'weak-password') {
        mensagemErro = 'A senha é muito fraca (mínimo de 6 caracteres).';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErro),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      print(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // ConstrainedBox limita a largura para a tela não ficar gigante no PC (Web)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pets, size: 100, color: Colors.orange),
                  const SizedBox(height: 32),
                  Text(
                    _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // --- CAMPOS EXCLUSIVOS DE CADASTRO (Aparecem no topo) ---
                  if (!_isLogin) ...[
                    // Campo de Nome
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Insira seu nome.'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Campo de Telefone/WhatsApp
                    TextFormField(
                      controller: _telefoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone / WhatsApp',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Insira seu telefone.'
                              : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // --- CAMPOS PADRÃO (Sempre visíveis) ---

                  // Campo de E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Por favor, insira um e-mail válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de Senha
                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'A senha deve ter no mínimo 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- CAMPOS EXCLUSIVOS DE CADASTRO (Parte inferior) ---
                  if (!_isLogin) ...[
                    // Campo de Confirmar Senha
                    TextFormField(
                      controller: _confirmarSenhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value != _senhaController.text) {
                          return 'As senhas não coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Checkbox de Termos de Uso
                    CheckboxListTile(
                      value: _aceitouTermos,
                      onChanged: (bool? value) {
                        setState(() {
                          _aceitouTermos = value ?? false;
                        });
                      },
                      title: const Text(
                        'Aceito os termos de uso e política de privacidade',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botão Principal
                  _isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: Colors.orange))
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.orange,
                          ),
                          child: Text(
                            _isLogin ? 'ENTRAR' : 'CADASTRAR',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Botão para alternar entre Login e Cadastro
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin; // Inverte a tela
                        _formKey.currentState
                            ?.reset(); // Limpa os erros de validação
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Ainda não tem conta? Cadastre-se'
                          : 'Já tem uma conta? Faça login',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
