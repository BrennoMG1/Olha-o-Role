// lib/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/auth/auth_service.dart'; // Importe seu AuthService

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

  // Controladores e Variáveis de Estado
  final _nameController = TextEditingController();
  User? _currentUser;
  String? _email;
  String? _photoURL;
  String? _friendCode;
  bool _isLoading = true; // Começa como true para carregar os dados
  bool _isSaving = false; // Para o botão de salvar
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
      return; // Sai se não houver usuário
    }

    // 1. Carrega dados do FirebaseAuth
    _nameController.text = _currentUser!.displayName ?? '';
    _email = _currentUser!.email ?? '';
    _photoURL = _currentUser!.photoURL;

    if (_currentUser!.providerData
        .any((provider) => provider.providerId == 'password')) {
      _isEmailUser = true;
    }

    // 2. Carrega dados do Firestore (para o friendCode)
    try {
      final docSnap =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (docSnap.exists) {
        _friendCode = docSnap.data()?['friendCode'];
      }
    } catch (e) {
      print("Erro ao carregar friendCode: $e");
    }

    setState(() => _isLoading = false);
  }

  /// Salva as alterações do perfil
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
      // 1. Chama o método do seu AuthService
      await _authService.updateUserProfile(
        _currentUser!,
        _nameController.text,
        // photoURL: _newPhotoUrl, // TODO: Implementar upload de foto
      );

      // 2. Recarrega os dados do usuário (para atualizar a foto, se mudou)
      await _currentUser!.reload();
      _currentUser = _auth.currentUser;

      if (mounted) {
        setState(() {
          _photoURL = _currentUser!.photoURL; // Atualiza a foto na UI
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

  /// TODO: Implementar a lógica de escolher e enviar foto
  void _editPhoto() {
    // Isso exigirá os pacotes 'image_picker' e 'firebase_storage'
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função de editar foto ainda não implementada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- O design é copiado do seu app ---
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
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
                    // --- Avatar com Botão de Edição ---
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor:
                                const Color.fromARGB(255, 211, 173, 92),
                            backgroundImage: (_photoURL != null)
                                ? NetworkImage(_photoURL!)
                                : null,
                            child: (_photoURL == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Color.fromARGB(255, 63, 39, 28),
                                  )
                                : null,
                          ),
                          // Botão de editar flutuante
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
                            onPressed: _editPhoto,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Card de Informações ---
                    Card(
                      elevation: 2.0,
                      color:
                          const Color.fromARGB(255, 245, 235, 220),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // --- Nome de Exibição (Editável) ---
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome de Exibição',
                                labelStyle: TextStyle(fontFamily: 'Itim'),
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // --- Email (Apenas Leitura) ---
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

                            // --- ID de Amigo (Apenas Leitura com Cópia) ---
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
                                          content:
                                              Text('ID copiado!'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                },
                              ),
                            ),
                            if (_isEmailUser) // SÓ MOSTRA SE FOR LOGIN POR E-MAIL
                      Column(
                        children: [
                          const Divider(indent: 16, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.lock_outline,
                                color: Colors.black54),
                            title: const Text('Alterar Senha',
                                style: TextStyle(
                                    fontFamily: 'Itim', fontSize: 16)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () async {
                              if (_email == null) return;

                              // Mostra um feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enviando link de redefinição...'),
                                ),
                              );

                              // Chama o mesmo serviço
                              final result = await _authService.sendPasswordResetEmail(_email!);

                              if (mounted) {
                                if (result == "Sucesso") {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Link enviado! Verifique seu e-mail.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
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