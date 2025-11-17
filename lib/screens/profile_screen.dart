import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // CORRIGIDO: Importação do Storage adicionada
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io'; 

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
  final FirebaseStorage _storage = FirebaseStorage.instance; // INSTÂNCIA AGORA RECONHECIDA
  final AuthService _authService = AuthService();

  // Controladores e Variáveis de Estado
  final _nameController = TextEditingController();
  User? _currentUser;
  String? _email;
  String? _photoURL;
  String? _friendCode;
  bool _isLoading = true; 
  bool _isSaving = false; 
  bool _isEmailUser = false;
  
  // Variáveis para upload de foto
  File? _newPhotoFile; 
  bool _isUploadingPhoto = false; 

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

  /// Salva as alterações do perfil (Nome e, se houver, a nova Foto)
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
    String? finalPhotoURL = _photoURL; 

    try {
      // 1. Verifica se há um novo arquivo de foto local para upload
      if (_newPhotoFile != null) {
        finalPhotoURL = await _uploadPhotoToStorage(_newPhotoFile!);
      }

      // 2. Chama o método do seu AuthService para atualizar Nome e/ou Foto
      await _authService.updateUserProfile(
        _currentUser!,
        _nameController.text,
        photoURL: finalPhotoURL, 
      );

      // 3. Recarrega os dados do usuário (para atualizar a foto no Auth)
      await _currentUser!.reload();
      _currentUser = _auth.currentUser;

      if (mounted) {
        setState(() {
          _photoURL = _currentUser!.photoURL; 
          _newPhotoFile = null; 
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

  /// NOVO: Lógica de upload do arquivo para o Firebase Storage
  Future<String> _uploadPhotoToStorage(File file) async {
    setState(() => _isUploadingPhoto = true);
    final uid = _currentUser!.uid;
    // Cria uma referência única para a foto de perfil do usuário
    final storageRef = _storage.ref().child('user_photos/$uid/profile.jpg');

    try {
      // 1. Inicia o upload
      final uploadTask = storageRef.putFile(file);
      
      // 2. Aguarda a conclusão do upload
      final snapshot = await uploadTask.whenComplete(() => null);
      
      // 3. Obtém a URL pública
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto enviada com sucesso!'), backgroundColor: Colors.orange),
        );
      }
      return downloadUrl;
      
    } catch (e) {
      print("Erro durante o upload da foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar foto: $e'), backgroundColor: Colors.red),
        );
      }
      rethrow; 
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  /// Lógica de escolha de foto (requer image_picker)
  void _editPhoto() async {
    // ESTA FUNÇÃO REQUER O PACOTE 'image_picker'
    
    // O código real para seleção de imagem usando 'image_picker' ficaria assim:
    /*
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (pickedFile != null) {
      setState(() {
        _newPhotoFile = File(pickedFile.path); // Armazena o arquivo local para prévia
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto selecionada! Pressione "Salvar Alterações" para atualizar.'),
            duration: Duration(seconds: 3)
          ),
        );
      }
    }
    */
    
    // Mensagem de aviso real da simulação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função de selecionar foto requer o pacote "image_picker".'),
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
                            // Se houver arquivo local selecionado, usa-o para prévia
                            backgroundImage: (_newPhotoFile != null)
                                ? FileImage(_newPhotoFile!)
                                : (_photoURL != null ? NetworkImage(_photoURL!) : null) as ImageProvider?,
                            child: (_photoURL == null && _newPhotoFile == null)
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
                      // Desabilita se estiver salvando OU fazendo upload de foto
                      onPressed: (_isSaving || _isUploadingPhoto) ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 63, 39, 28),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: (_isSaving || _isUploadingPhoto)
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            )
                          : Text(
                              // Mudar texto para indicar que a foto está pendente
                              (_newPhotoFile != null)
                                  ? 'Salvar Alterações (inclui nova foto)'
                                  : 'Salvar Alterações',
                              style:
                                  const TextStyle(fontFamily: 'Itim', fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}