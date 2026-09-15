import 'package:flutter/material.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 1. Chave do Formulário (usada para validar os campos)
  final _formKey = GlobalKey<FormState>();

  // 2. Controladores (eles "capturam" o que o usuário digita)
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  // 3. Variável de Estado (define se a tela é de Login ou Cadastro)
  bool _isLogin = true;

  // Função que será chamada ao clicar no botão principal
  // Não esqueça de importar a tela nova no topo do auth_screen.dart:
  // import 'package:seu_projeto/screens/home_screen.dart';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Quando clicar em Entrar/Cadastrar e não tiver erro,
      // ele pula para a tela principal (HomeScreen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
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
            key: _formKey, // Conectando a chave ao formulário
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone ou Logo do App
                const Icon(
                  Icons.pets,
                  size: 100,
                  color: Colors.orange,
                ),
                const SizedBox(height: 32),

                // Título dinâmico (muda dependendo se é login ou cadastro)
                Text(
                  _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                  obscureText: true, // Esconde a senha com "bolinhas"
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

                // Botão Principal (Entrar ou Cadastrar)
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                    _isLogin ? 'ENTRAR' : 'CADASTRAR',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                // Botão para alternar entre Login e Cadastro
                TextButton(
                  onPressed: () {
                    // O setState reconstrói a tela com a nova variável
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
