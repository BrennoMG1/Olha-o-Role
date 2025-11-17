import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// CORREÇÃO AQUI: Mudando para um caminho relativo
import '/auth/auth_service.dart'; // Importe seu AuthService
import 'event_list_screen.dart';

// 1. Mude para StatefulWidget para podermos usar TextControllers e o AuthService
class ProfileSetupScreen extends StatefulWidget {
  // 2. Recebe o usuário que acabou de ser criado
  final User user;

  const ProfileSetupScreen({super.key, required this.user});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _displayNameController = TextEditingController();
  final _authService = AuthService(); // Instância do nosso serviço
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Se o usuário logou com o Google, ele pode já ter um nome.
    // Vamos pré-preencher o campo para ele.
    if (widget.user.displayName != null) {
      _displayNameController.text = widget.user.displayName!;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  /// Salva o perfil do usuário
  Future<void> _saveProfile() async {
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, insira um nome de exibição.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
  // 1. Atualiza o nome de exibição no Firebase Auth
  await widget.user.updateDisplayName(_displayNameController.text);

  // --- 2. GERE O CÓDIGO DE AMIGO AQUI ---
  // Isso pega o hashCode do UID, converte para hexadecimal,
  // garante 8 dígitos (com '0' à esquerda) e pega os últimos 8.
  final String fullHex = widget.user.uid.hashCode
      .abs()
      .toRadixString(16)
      .padLeft(8, '0')
      .toUpperCase();
  final String friendCode = fullHex.substring(fullHex.length - 8);
  // Exemplo de resultado: "F1C4A3D9"

  // 3. PASSE O CÓDIGO AO SALVAR (AGORA COM 3 ARGUMENTOS)
  await _authService.saveUserToFirestore(
    widget.user,
    _displayNameController.text,
    friendCode, // <-- O argumento que faltava
  );

  // 4. Navega para a tela principal, removendo todas as telas anteriores
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const EventListScreen()),
      (Route<dynamic> route) => false,
    );
  }
} on FirebaseAuthException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('Erro ao salvar perfil: ${e.message}')),
  );
} catch (e) {
  // Pega outros erros
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('Erro ao salvar no Firestore: ${e.toString()}'),
        backgroundColor: Colors.red),
  );
    } finally {
  if (mounted) {
    setState(() => _isLoading = false);
  }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crie sua conta'),
        backgroundColor: const Color(0xFF3D4A9C),
        automaticallyImplyLeading: false, // Remove a seta de "voltar"
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: const Color(0xFFD3CFF8),
                  // 4. Mostra a foto do usuário (se tiver, ex: vinda do Google)
                  backgroundImage: widget.user.photoURL != null
                      ? NetworkImage(widget.user.photoURL!)
                      : null,
                  child: widget.user.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 100,
                          color: Color(0xFF4A3F99),
                        )
                      : null,
                ),
                IconButton(
                  onPressed: () {
                    // Lógica para editar a foto de perfil (requer ImagePicker e Storage)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Upload de foto ainda não implementado.')),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3D4A9C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextField(
              // 5. Usa o controller
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nome de exibição:',
                helperText: 'Como os outros usuários verão você.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              // 6. Chama a função de salvar
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF3D4A9C),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Cadastrar e Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}

