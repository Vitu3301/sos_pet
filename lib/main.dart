import 'package:flutter/material.dart';
import 'package:sos_pet/screens/auth_screen.dart';

void main() {
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
