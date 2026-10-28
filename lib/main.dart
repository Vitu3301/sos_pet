import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Garante a inicialização correta dos widgets do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase usando as configurações da plataforma atual (Web, Android, etc.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o Supabase (Substitua pelas chaves reais do seu projeto no Supabase)
  await Supabase.initialize(
    url: 'https://zstuvejdhfkfsqwqlheu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpzdHV2ZWpkaGZrZnNxd3FsaGV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI1Mzg1MDgsImV4cCI6MjEwODExNDUwOH0.rqQ1vYhtQKA1B9B2FErqZB1ZL6ugtY9F0c90sAf7WgM',
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
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
