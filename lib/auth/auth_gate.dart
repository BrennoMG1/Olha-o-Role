import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/event_list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_setup_screen.dart'; // Importe a tela de setup

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se ainda não tem dados, mostra um loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF3D4A9C), // Cor de fundo da sua tela de login
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Se o usuário está logado (snapshot tem dados)
        if (snapshot.hasData) {
          final user = snapshot.data!;

          // --- NOVA LÓGICA ---
          // Verificamos se o usuário já tem um nome de exibição.
          // O login com Email/Senha não define um nome por padrão.
          // Se o nome for nulo OU vazio, significa que é um novo usuário
          // que precisa configurar o perfil.
          if (user.displayName == null || user.displayName!.isEmpty) {
            // Envia para a tela de setup de perfil, passando o usuário
            return ProfileSetupScreen(user: user);
          }
          // --- FIM DA NOVA LÓGICA ---

          // Se o usuário já tem um nome, vai para a tela principal
          return const EventListScreen();
        }

        // Se o usuário está deslogado (snapshot NÃO tem dados)
        return const LoginScreen();
      },
    );
  }
}

