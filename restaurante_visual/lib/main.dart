import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // El archivo que se está creando justo ahora
import 'pantallas/login_screen.dart';

void main() async {
  // Asegura que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa la conexión con Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MrPulpoApp());
}

class MrPulpoApp extends StatelessWidget {
  const MrPulpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mr. Pulpo POS',
      home: const LoginScreen(),
    );
  }
}