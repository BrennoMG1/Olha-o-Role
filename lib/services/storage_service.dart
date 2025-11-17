// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Faz o upload de uma foto de perfil e retorna a URL de download
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    try {
      // Cria uma referência única para o arquivo no Storage
      // Ex: 'profile_pictures/uid_do_usuario.jpg'
      Reference ref =
          _storage.ref().child('profile_pictures').child('$userId.jpg');

      // Faz o upload do arquivo
      UploadTask uploadTask = ref.putFile(imageFile);

      // Espera o upload ser concluído
      TaskSnapshot snapshot = await uploadTask;

      // Pega a URL de download pública
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
      
    } catch (e) {
      print("Erro no upload da foto: $e");
      rethrow; // Lança o erro para a tela tratar
    }
  }
}