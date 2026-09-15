import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 1. Importando o pacote de Autenticação
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading =
      false; // Variável para mostrar um ícone de "carregando" enquanto o Firebase processa

  // Função que envia os dados para o Firebase
  void _submit() async {
    // 1. Valida se os campos estão corretos
    if (!_formKey.currentState!.validate()) return;

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
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: senha,
        );
      }

      // Se der certo, navega para a tela principal e remove a tela de login do histórico
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (error) {
      // Tratamento de Erros do Firebase (ex: senha fraca, e-mail já cadastrado, senha incorreta)
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

      // Mostra o erro na tela usando um SnackBar (aviso na parte inferior)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemErro),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      print(error);
    } finally {
      // Desliga o "carregando" independentemente de dar certo ou errado
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
                const SizedBox(height: 24),

                // Botão Principal com indicador de carregamento
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange))
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
                      _isLogin = !_isLogin;
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
    );
  }
}
