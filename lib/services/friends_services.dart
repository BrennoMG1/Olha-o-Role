// lib/services/friends_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  /// Retorna um Stream dos convites de amizade PENDENTES.
  Stream<QuerySnapshot> getFriendInvitesStream() {
    if (_currentUser == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friend_invites')
        .snapshots();
  }

  /// Retorna um Stream dos amigos ACEITOS.
  Stream<QuerySnapshot> getFriendsStream() {
    if (_currentUser == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friends')
        .snapshots();
  }

  /// Envia um convite de amizade para um usuário (usando o friendCode)
  Future<String> sendFriendInvite(String friendCode) async {
    if (_currentUser == null) return "Erro: Usuário não logado.";

    try {
      // 1. Encontra o usuário pelo friendCode
      final query = await _firestore
          .collection('users')
          .where('friendCode', isEqualTo: friendCode.toUpperCase().trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return "Erro: Nenhum usuário encontrado com esse ID.";
      }

      final targetUserDoc = query.docs.first;
      final targetUserId = targetUserDoc.id;

      // 2. Verifica se não está adicionando a si mesmo
      if (targetUserId == _currentUser!.uid) {
        return "Você não pode adicionar a si mesmo!";
      }

      // 3. (Opcional) Verifica se já não são amigos ou se já há um convite
      // (Esta lógica pode ser adicionada depois)

      // 4. Cria o documento de convite na sub-coleção DO OUTRO USUÁRIO
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('friend_invites')
          .doc(_currentUser!.uid) // O ID do doc é o NOSSO UID
          .set({
        'senderName': _currentUser!.displayName ?? _currentUser!.email,
        'senderFriendCode': (await _firestore
                .collection('users')
                .doc(_currentUser!.uid)
                .get())
            .data()?['friendCode'],
        'sentAt': FieldValue.serverTimestamp(),
      });

      return "Convite enviado com sucesso!";
    } catch (e) {
      print("Erro ao enviar convite: $e");
      return "Erro: Ocorreu um problema ao enviar o convite.";
    }
  }

  /// Aceita um convite de amizade
  Future<void> acceptFriendInvite(String senderId, String senderName,
      String? senderFriendCode) async {
    if (_currentUser == null) return;

    final myUid = _currentUser!.uid;
    final myName = _currentUser!.displayName ?? _currentUser!.email;
    final myFriendCode =
        (await _firestore.collection('users').doc(myUid).get())
            .data()?['friendCode'];

    // Usa um BATCH para garantir que as duas operações funcionem
    WriteBatch batch = _firestore.batch();

    // 1. Adiciona o remetente à MINHA lista de amigos
    batch.set(
      _firestore.collection('users').doc(myUid).collection('friends').doc(senderId),
      {
        'displayName': senderName,
        'friendCode': senderFriendCode,
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    // 2. Adiciona o usuário atual (EU) à lista de amigos DO REMETENTE
    batch.set(
      _firestore.collection('users').doc(senderId).collection('friends').doc(myUid),
      {
        'displayName': myName,
        'friendCode': myFriendCode,
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    // 3. Exclui o convite pendente
    batch.delete(
      _firestore
          .collection('users')
          .doc(myUid)
          .collection('friend_invites')
          .doc(senderId),
    );

    // Executa a transação
    await batch.commit();
  }

  /// Recusa um convite de amizade
  Future<void> declineFriendInvite(String senderId) async {
    if (_currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('friend_invites')
        .doc(senderId)
        .delete();
  }
}