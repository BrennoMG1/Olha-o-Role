import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'event_list_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Cores baseadas no EventListScreen para manter a coerência
  static const Color _primaryColor = Color.fromARGB(255, 211, 173, 92); // Amarelo Queimado/Ouro
  static const Color _backgroundColor = Color.fromARGB(255, 230, 210, 185); // Bege
  static const Color _textColor = Color.fromARGB(255, 63, 39, 28); // Marrom Escuro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Olha o rolê',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 56, // Tamanho maior
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: 'Itim', // Usando a fonte do app
                  shadows: [
                    Shadow( 
                      blurRadius: 2.0,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
              
              // 3. Seção Login
              const Text(
                'Acesse sua conta:',
                style: TextStyle(
                  fontSize: 24,
                  color: _textColor,
                  fontFamily: 'Itim',
                ),
              ),
              const SizedBox(height: 20),

              // Botão Login com Google (Estilo do App)
              _buildAuthButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                label: 'Login com Google',
                icon: const Icon(Icons.login),
                backgroundColor: _primaryColor,
                textColor: _textColor,
              ),
              const SizedBox(height: 10),

              // Botão Login com E-mail
              _buildAuthButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                label: 'Login com E-mail',
                icon: const Icon(Icons.email),
                backgroundColor: _primaryColor, 
                textColor: _textColor,
              ),
              const SizedBox(height: 10),

              // Botão Convidado (TextButton)
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const EventListScreen()),
                  );
                },
                child: const Text(
                  'Acessar como convidado',
                  style: TextStyle(
                    color: _textColor,
                    decoration: TextDecoration.underline,
                    fontFamily: 'Itim',
                  ),
                ),
              ),

              const SizedBox(height: 60),
              
              // 4. Seção Cadastre-se
              const Text(
                'Novo por aqui?',
                style: TextStyle(
                  fontSize: 24,
                  color: _textColor,
                  fontFamily: 'Itim',
                ),
              ),
              const SizedBox(height: 20),

              // Botão Cadastre-se com E-mail
              _buildAuthButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
                label: 'Criar uma conta',
                icon: const Icon(Icons.person_add),
                backgroundColor: const Color.fromARGB(255, 255, 240, 200),
                textColor: _textColor,
                // Borda mais escura para dar contraste
                borderColor: _textColor.withOpacity(0.5), 
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir botões de autenticação com o novo estilo
  Widget _buildAuthButton({
    required VoidCallback onPressed,
    required String label,
    required Icon icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Itim',
          fontSize: 18,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 2)
              : BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}