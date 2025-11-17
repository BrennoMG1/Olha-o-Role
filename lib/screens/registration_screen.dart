import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});
  static const Color _primaryColor = Color.fromARGB(255, 211, 173, 92);
  static const Color _backgroundColor = Color.fromARGB(255, 230, 210, 185);
  static const Color _textColor = Color.fromARGB(255, 63, 39, 28);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Crie sua conta',
          style: TextStyle(
            color: _textColor,
            fontFamily: 'Itim',
            fontSize: 24,
          ),
        ),
        foregroundColor: _textColor,
        backgroundColor: _primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.png"), 
            fit: BoxFit.cover,
            opacity: 0.18,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Insira seus dados para começar o rolê:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: _textColor,
                  fontFamily: 'Itim',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                label: 'E-mail:',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Senha:',
                obscureText: true,
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Confirme a senha:',
                obscureText: true,
                icon: Icons.lock_reset,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: _primaryColor,
                  foregroundColor: _textColor,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Cadastrar e Avançar',
                  style: TextStyle(
                    fontFamily: 'Itim',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTextField({
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required IconData icon,
  }) {
    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: _textColor, fontFamily: 'Itim'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textColor, fontFamily: 'Itim'),
        prefixIcon: Icon(icon, color: _textColor.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: _textColor, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: _textColor.withOpacity(0.5), width: 1.0),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
      ),
    );
  }
}