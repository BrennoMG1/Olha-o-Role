import 'package:Olha_o_Role/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_setup_screen.dart';

// 1. Convertido para StatefulWidget
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // 2. Controladores e estado de loading
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. Função para mostrar erros
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // 4. Lógica de Cadastro
  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('As senhas não coincidem.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tenta criar o usuário
      final userCredential = await _authService.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      // SUCESSO! Agora navega para a tela de perfil
      if (userCredential != null && userCredential.user != null && mounted) {
        // --- ESTA É A CORREÇÃO ---
        // Passamos o userCredential.user para a ProfileSetupScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(user: userCredential.user!),
          ),
        );
        // -------------------------
      }
    } on FirebaseAuthException catch (e) {
      _showError('Erro ao registrar: ${e.message}');
    } catch (e) {
      _showError('Ocorreu um erro: ${e.toString()}');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crie sua conta'),
        backgroundColor: const Color(0xFF3D4A9C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail:',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha:',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirme a senha:',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF3D4A9C),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Avançar'),
            ),
          ],
        ),
      ),
    );
  }
}

