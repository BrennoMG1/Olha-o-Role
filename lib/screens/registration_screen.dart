import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Olha_o_Role/auth/auth_service.dart';

import 'profile_setup_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Constantes de cor para o estilo rústico (Reintroduzidas)
  static const Color _primaryColor = Color.fromARGB(255, 211, 173, 92); // Amarelo Queimado
  static const Color _backgroundColor = Color.fromARGB(255, 230, 210, 185); // Bege
  static const Color _textColor = Color.fromARGB(255, 63, 39, 28); // Marrom Escuro

  final _formKey = GlobalKey<FormState>();
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Lógica de Cadastro
  Future<void> _signUp() async {
    // 1. Validação de formulário (campos vazios)
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // 2. Validação de senhas
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('As senhas não coincidem.');
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signUpWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        if (userCredential != null && userCredential.user != null) {
          // SUCESSO: Navega para a tela de configuração de perfil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(user: userCredential.user!),
            ),
          );
        } else {
          // FALHA: O serviço retornou null (erro já deve ter sido logado pelo AuthService)
          _showError(
              'Falha ao registrar. Verifique o e-mail ou se a senha é válida.');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      // Catch genérico (embora o AuthService já deva tratar a maioria)
       _showError('Ocorreu um erro inesperado: ${e.toString()}');
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Criar sua conta',
          style: TextStyle(
            color: _textColor,
            fontFamily: 'Itim',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _backgroundColor,
        iconTheme: const IconThemeData(color: _textColor),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Cadastre-se para começar o rolê:',
                  style: TextStyle(
                    fontSize: 24,
                    color: _textColor,
                    fontFamily: 'Itim',
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextField(
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Digite seu e-mail';
                    // Adicionar validação de formato de e-mail aqui
                    return null;
                    String pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
                    RegExp regex = RegExp(pattern);
                    if (!regex.hasMatch(value)) {
                      return 'Insira um formato de e-mail válido.';
                    }
                  },
                ),
                const SizedBox(height: 15),

                _buildTextField(
                  controller: _passwordController,
                  label: 'Senha (mín. 6 caracteres)',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirme a senha',
                  icon: Icons.lock_reset,
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),

                _buildAuthButton(
                  onPressed: _signUp,
                  label: 'Criar conta',
                  icon: const Icon(Icons.arrow_forward),
                  backgroundColor: _primaryColor,
                  textColor: _textColor,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // --- Widgets Auxiliares (Copiados de LoginScreen para consistência) ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: _textColor, fontFamily: 'Itim'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textColor.withOpacity(0.8), fontFamily: 'Itim'),
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

  Widget _buildAuthButton({
    required VoidCallback onPressed,
    required String label,
    required Icon icon,
    required Color backgroundColor,
    required Color textColor,
    bool isLoading = false,
    Color? borderColor,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _textColor, strokeWidth: 3))
          : icon,
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