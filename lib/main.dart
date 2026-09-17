import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Importa o arquivo que você acabou de gerar
import 'screens/auth_screen.dart';

void main() async {
  // Garante a inicialização correta dos widgets do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase usando as configurações da plataforma atual (Web, Android, etc.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Pet',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const AuthScreen(),
    );
  }
}
