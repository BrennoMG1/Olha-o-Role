import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'event_list_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3D4A9C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Olha o rolê',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'Login:',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Lógica de login com Google
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Login com Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                   // Lógica de login com E-mail
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                icon: const Icon(Icons.email),
                label: const Text('Login com E-mail'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  // Navega para a tela principal sem autenticação
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                child: const Text(
                  'Acessar como convidado',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 40),
              const Text(
                'Cadastre-se:',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
                icon: const Icon(Icons.email),
                label: const Text('Cadastre-se com E-mail'),
                 style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                   shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}