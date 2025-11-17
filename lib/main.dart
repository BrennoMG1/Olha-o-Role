import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // Importe o Firebase Core
import 'firebase_options.dart'; // Importe as opções geradas
import 'models/event.dart';
import 'auth/auth_gate.dart'; // Importe o AuthGate

void main() async {
  // 1. Garante que o Flutter está pronto
  WidgetsFlutterBinding.ensureInitialized();

  // 2. INICIALIZA O FIREBASE (Esta é a linha que corrige seu erro)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Inicializa o Hive
  await Hive.initFlutter();
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(ItemAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olha o Rolê',
      theme: ThemeData(
        // Você pode manter seu tema aqui
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D4A9C)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // 4. Inicia no AuthGate, e não mais na EventListScreen
      home: const AuthGate(),
    );
  }
}

