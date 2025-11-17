// lib/profile_screen.dart (VERSÃO ATUALIZADA)

import 'dart:io'; // <-- 1. NOVO IMPORT
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // <-- 2. NOVO IMPORT
import '/auth/auth_service.dart';
import '/services/storage_service.dart'; // <-- 3. NOVO IMPORT

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Serviços
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService(); // <-- 4. NOVO SERVIÇO
  final _picker = ImagePicker();

  // Controladores e Variáveis de Estado
  final _nameController = TextEditingController();
  User? _currentUser;
  String? _email;
  String? _photoURL; // A foto ATUAL (da rede)
  String? _friendCode;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _pickedImage; // A NOVA foto (prévia local)
  bool _isEmailUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Carrega os dados do usuário (do Auth e do Firestore)
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    _nameController.text = _currentUser!.displayName ?? '';
    _email = _currentUser!.email ?? '';
    _photoURL = _currentUser!.photoURL; // Carrega a foto da rede
    
    if (_currentUser!.providerData
        .any((provider) => provider.providerId == 'password')) {
      _isEmailUser = true;
    }

    try {
      final docSnap =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (docSnap.exists) {
        _friendCode = docSnap.data()?['friendCode'];
        // Garante que o photoURL do Firestore (mais atual) seja usado
        _photoURL = docSnap.data()?['photoURL'] ?? _photoURL;
      }
    } catch (e) {
      print("Erro ao carregar friendCode: $e");
    }

    setState(() => _isLoading = false);
  }

  /// 5. NOVA FUNÇÃO para escolher a imagem
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  /// 6. FUNÇÃO _saveProfile ATUALIZADA
  Future<void> _saveProfile() async {
    if (_currentUser == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O nome não pode ficar em branco.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? newPhotoURL = _photoURL; // Começa com a foto antiga

      // 1. Se uma nova foto foi escolhida, faz o upload
      if (_pickedImage != null) {
        newPhotoURL = await _storageService.uploadProfilePicture(
          _pickedImage!,
          _currentUser!.uid,
        );
      }

      // 2. Chama o método do AuthService (que atualiza Auth e Firestore)
      await _authService.updateUserProfile(
        _currentUser!,
        _nameController.text,
        photoURL: newPhotoURL, // Passa a URL (nova ou antiga)
      );

      // 3. Atualiza a UI
      if (mounted) {
        setState(() {
          _pickedImage = null; // Limpa a prévia
          _photoURL = newPhotoURL; // Define a nova foto da rede
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil salvo com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar perfil: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        // ... (seu AppBar) ...
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(
              color: Color.fromARGB(255, 63, 39, 28),
              fontFamily: 'Itim',
              fontSize: 30),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/background.png"),
              fit: BoxFit.cover,
              opacity: 0.18),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // --- 7. AVATAR ATUALIZADO (mostra a prévia) ---
                          CircleAvatar(
                            radius: 70,
                            backgroundColor:
                                const Color.fromARGB(255, 211, 173, 92),
                            // Se tiver uma foto nova (prévia), usa FileImage
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                // Senão, usa a foto da rede (antiga)
                                : (_photoURL != null)
                                    ? NetworkImage(_photoURL!)
                                    : null as ImageProvider?,
                            // Se não tiver NENHUMA foto, mostra o ícone
                            child: (_pickedImage == null && _photoURL == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Color.fromARGB(255, 63, 39, 28),
                                  )
                                : null,
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: const CircleBorder(
                                side: BorderSide(
                                    color: Colors.black26, width: 1),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined,
                                color: Color.fromARGB(255, 63, 39, 28)),
                            onPressed: _pickImage, // <-- 8. CHAMA A FUNÇÃO
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Card de Informações ---
                    Card(
                      elevation: 2.0,
                      color: const Color.fromARGB(255, 245, 235, 220),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // ... (seu TextField de Nome)
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome de Exibição',
                                labelStyle: TextStyle(fontFamily: 'Itim'),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // ... (seu ListTile de E-mail)
                            ListTile(
                              leading: const Icon(Icons.email_outlined,
                                  color: Colors.black54),
                              title: Text(
                                _email ?? 'Carregando...',
                                style: const TextStyle(
                                    fontFamily: 'Itim', fontSize: 16),
                              ),
                              subtitle: const Text('E-mail (não pode ser alterado)',
                                  style: TextStyle(fontFamily: 'Itim')),
                            ),

                            // ... (seu ListTile de ID de Amigo)
                            ListTile(
                              leading: const Icon(Icons.badge_outlined,
                                  color: Colors.black54),
                              title: Text(
                                _friendCode ?? 'Carregando...',
                                style: const TextStyle(
                                    fontFamily: 'Itim',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Seu ID de Amigo',
                                  style: TextStyle(fontFamily: 'Itim')),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () {
                                  if (_friendCode != null) {
                                    Clipboard.setData(
                                        ClipboardData(text: _friendCode!));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('ID copiado!'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                },
                              ),
                            ),
                            
                            // ... (seu ListTile de Alterar Senha)
                            if (_isEmailUser)
                              Column(
                                children: [
                                  const Divider(indent: 16, endIndent: 16),
                                  ListTile(
                                    leading: const Icon(Icons.lock_outline,
                                        color: Colors.black54),
                                    title: const Text('Alterar Senha',
                                        style: TextStyle(
                                            fontFamily: 'Itim', fontSize: 16)),
                                    trailing: const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                    onTap: () async {
                                      if (_email == null) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Enviando link de redefinição...'),
                                        ),
                                      );
                                      final result = await _authService
                                          .sendPasswordResetEmail(_email!);
                                      if (mounted) {
                                        if (result == "Sucesso") {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Link enviado! Verifique seu e-mail.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(result),
                                                backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Botão Salvar ---
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      // ... (estilo do botão)
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 63, 39, 28),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              'Salvar Alterações',
                              style:
                                  TextStyle(fontFamily: 'Itim', fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}