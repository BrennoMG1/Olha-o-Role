// lib/profile_setup_screen.dart (VERSÃO ATUALIZADA COM ESTILO)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// Imports relativos corrigidos (assumindo que estão na raiz)
import '/auth/auth_service.dart'; 
import 'event_list_screen.dart';
import '/services/storage_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final User user;

  const ProfileSetupScreen({super.key, required this.user});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // --- CONSTANTES DE ESTILO ---
  static const Color _primaryColor = Color.fromARGB(255, 211, 173, 92); // Amarelo Queimado
  static const Color _backgroundColor = Color.fromARGB(255, 230, 210, 185); // Bege/Areia
  static const Color _textColor = Color.fromARGB(255, 63, 39, 28); // Marrom Escuro
  // -----------------------------

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

  // --- LÓGICA DE NAVEGAÇÃO E UPLOAD ---

  Future<void> _handleBackPress() async {
    // 1. Apaga a conta recém-criada no Firebase Auth para permitir o re-registro
    try {
      await widget.user.delete();
      await _authService.signOut(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Conta temporária deletada. Corrija seu registro.'),
            backgroundColor: Colors.orange),
      );
    } catch (e) {
      print('Erro ao deletar usuário temporário: $e');
    }

    // 2. Volta para a tela de Registro/Login
    if (mounted) {
      Navigator.pop(context);
    }
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
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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
      backgroundColor: _backgroundColor, // <-- BG CORRIGIDO
      appBar: AppBar(
        title: const Text('Crie seu Perfil', style: TextStyle(color: _textColor, fontFamily: 'Itim')), // <-- TEXTO E ESTILO CORRIGIDOS
        backgroundColor: _primaryColor, // <-- BARRA CORRIGIDA
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textColor), // <-- ÍCONE CORRIGIDO
          onPressed: _handleBackPress, // <-- LÓGICA DE DELETAR/VOLTAR
        ), 
      ),

      body: Container( // <-- ADICIONADO CONTAINER PARA BACKGROUND
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/background.png"),
              fit: BoxFit.cover,
              opacity: 0.18),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              
              // --- AVATAR ---
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                        radius: 80,
                        backgroundColor: _primaryColor.withOpacity(0.5), // <-- COR CORRIGIDA
                        // Mostra a foto escolhida (prévia)
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (googlePhoto != null)
                                ? NetworkImage(googlePhoto)
                                : null as ImageProvider?,
                        // Se não tiver nem prévia nem foto do Google, mostra o ícone
                        child: (_pickedImage == null && googlePhoto == null)
                            ? const Icon(
                                Icons.person,
                                size: 100,
                                color: _textColor, // <-- COR CORRIGIDA
                              )
                            : null,
                    ),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _textColor, // <-- COR CORRIGIDA
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // --- CAMPO DE NOME ---
              TextField(
                controller: _displayNameController,
                style: const TextStyle(color: _textColor, fontFamily: 'Itim'), // <-- ESTILO CORRIGIDO
                decoration: InputDecoration(
                  labelText: 'Nome de exibição:',
                  labelStyle: TextStyle(color: _textColor.withOpacity(0.8), fontFamily: 'Itim'), // <-- ESTILO CORRIGIDO
                  helperText: 'Como os outros usuários verão você.',
                  helperStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),
              
              // --- BOTÃO ---
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _textColor, // <-- COR CORRIGIDA
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Cadastrar e Entrar', style: TextStyle(fontFamily: 'Itim', fontSize: 18)), // <-- ESTILO CORRIGIDO
              ),
            ],
          ),
        ),
      ),
    );
  }
}