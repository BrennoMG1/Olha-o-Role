import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// CORREÇÃO AQUI: Mudando para um caminho relativo
import '/auth/auth_service.dart'; 
import 'event_list_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '/services/storage_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final User user;

  const ProfileSetupScreen({super.key, required this.user});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _displayNameController = TextEditingController();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  bool _isLoading = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    if (widget.user.displayName != null) {
      _displayNameController.text = widget.user.displayName!;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um nome de exibição.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.user.reload();

      if (!widget.user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, verifique seu e-mail antes de continuar.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      String? photoURL = widget.user.photoURL;

      if (_pickedImage != null) {
        photoURL = await _storageService.uploadProfilePicture(
          _pickedImage!,
          widget.user.uid,
        );
      }

      await widget.user.updateDisplayName(_displayNameController.text);
      if (photoURL != null) {
        await widget.user.updatePhotoURL(photoURL);
      }

      final String fullHex = widget.user.uid.hashCode
          .abs()
          .toRadixString(16)
          .padLeft(8, '0')
          .toUpperCase();
      final String friendCode = fullHex.substring(fullHex.length - 8);

      await _authService.saveUserToFirestore(
        widget.user,
        _displayNameController.text,
        friendCode,
        photoURL,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const EventListScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? googlePhoto = widget.user.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Perfil'),
        backgroundColor: const Color(0xFF3D4A9C),

        // 🔙 **BOTÃO DE VOLTAR**
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // volta para a tela de registro
          },
        ),
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
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (googlePhoto != null
                          ? NetworkImage(googlePhoto)
                          : null) as ImageProvider?,
                  child: (_pickedImage == null && googlePhoto == null)
                      ? const Icon(Icons.person, size: 100, color: Color(0xFF4A3F99))
                      : null,
                ),
                IconButton(
                  onPressed: _pickImage,
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
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nome de exibição:',
                helperText: 'Como os outros usuários verão você.',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
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
