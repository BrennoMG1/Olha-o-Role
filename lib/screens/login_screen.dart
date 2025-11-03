  import 'package:flutter/material.dart';
  import 'registration_screen.dart';
  import 'event_list_screen.dart';
  import '../auth/auth_service.dart'; // Importe o serviço

  class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
  }

  class _LoginScreenState extends State<LoginScreen> {
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
          backgroundColor: Colors.red,
        ),
      );
    }

    // --- Lógica de Login com Google ---
    Future<void> _loginWithGoogle() async {
      setState(() => _isLoading = true);
      try {
        final userCredential = await _authService.signInWithGoogle();
        if (userCredential == null && mounted) {
          _showError('Login com Google cancelado ou falhou.');
        }
        // O AuthGate cuidará da navegação se o login for bem-sucedido
      } catch (e) {
        _showError('Erro ao fazer login com Google: ${e.toString()}');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    // --- Lógica de Login com Email ---
    Future<void> _loginWithEmail() async {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _isLoading = true);
        try {
          final userCredential = await _authService.signInWithEmailPassword(
            _emailController.text,
            _passwordController.text,
          );
          if (userCredential == null && mounted) {
            _showError('Email ou senha inválidos.');
          }
        } catch (e) {
          _showError('Erro ao fazer login: ${e.toString()}');
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
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
                const SizedBox(height: 40),

                // --- Formulário de Login ---
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'E-mail'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value?.isEmpty ?? true) ? 'Digite seu e-mail' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Senha'),
                        obscureText: true,
                        validator: (value) => (value?.isEmpty ?? true) ? 'Digite sua senha' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  // --- Botões de Ação ---
                  ElevatedButton.icon(
                    onPressed: _loginWithEmail,
                    icon: const Icon(Icons.email),
                    label: const Text('Login com E-mail'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: const Icon(Icons.login), // Ícone do Google (precisa de font_awesome_flutter para o ícone real)
                    label: const Text('Login com Google'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      // Navega para a tela principal sem autenticação
                      // ESTA LÓGICA NÃO FUNCIONARÁ MAIS por causa do AuthGate.
                      // O AuthGate FORÇARÁ o usuário de volta para o Login.
                      // Você pode remover este botão ou mantê-lo e ele
                      // simplesmente não fará nada.
                      // Para implementar "Acesso de Convidado", precisaríamos
                      // de "Login Anônimo" do Firebase.
                      print("Acesso de convidado precisa de login anônimo do Firebase");
                    },
                    child: const Text(
                      'Acessar como convidado (Desativado)',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cadastre-se:',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Cadastre-se com E-mail'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
}
