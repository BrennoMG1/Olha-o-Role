import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'event_list_screen.dart'; 
import '../auth/auth_service.dart'; // Importe o serviço
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Constantes de cor para o estilo rústico (Reintroduzidas)
  static const Color _primaryColor = Color.fromARGB(255, 211, 173, 92); // Amarelo Queimado
  static const Color _backgroundColor = Color.fromARGB(255, 230, 210, 185); // Bege
  static const Color _textColor = Color.fromARGB(255, 63, 39, 28); // Marrom Escuro

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null && mounted) {
        _showError('Login com Google cancelado ou falhou.');
      }
      // Se o login for bem-sucedido, o AuthGate/StreamBuilder deve navegar
    } catch (e) {
      _showError('Erro ao fazer login com Google: ${e.toString()}');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmailPassword(
          _emailController.text,
          _passwordController.text,
        );
        // Se o login for bem-sucedido, o AuthGate/StreamBuilder deve navegar
      } catch (e) {
        _showError('Erro ao fazer login. Verifique seu e-mail e senha.');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: 'Itim',
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

              // --- Formulário de Login ---
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Acesse sua conta:',
                      style: TextStyle(
                        fontSize: 24,
                        color: _textColor,
                        fontFamily: 'Itim',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value?.isEmpty ?? true) ? 'Digite seu e-mail' : null,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => (value?.isEmpty ?? true) ? 'Digite sua senha' : null,
                    ),
                  ],
                ),
              ),
              
              // Esqueceu a senha
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Esqueceu a senha?',
                      style: TextStyle(
                        fontFamily: 'Itim',
                        color: _textColor.withOpacity(0.8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),

              if (_isLoading)
                Center(child: CircularProgressIndicator(color: _primaryColor))
              else ...[
                // Botão de Login com E-mail
                _buildAuthButton(
                  onPressed: _loginWithEmail,
                  label: 'Fazer Login',
                  icon: const Icon(Icons.login),
                  backgroundColor: _primaryColor,
                  textColor: _textColor,
                ),
                const SizedBox(height: 15),

                // Botão de Login com Google
                _buildAuthButton(
                  onPressed: _loginWithGoogle,
                  label: 'Login com Google',
                  icon: const Icon(Icons.search), // Usando ícone padrão para Google
                  backgroundColor: _primaryColor,
                  textColor: _textColor,
                ),

                const SizedBox(height: 40),
                const Text(
                  'Novo por aqui?',
                  style: TextStyle(fontSize: 24, color: _textColor, fontFamily: 'Itim'),
                ),
                const SizedBox(height: 10),

                // Botão de Cadastro
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
                  borderColor: _textColor.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares ---

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