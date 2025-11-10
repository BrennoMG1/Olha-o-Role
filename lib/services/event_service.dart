import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/event_item.dart';
import '../models/contributor.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna um Stream de eventos onde o usuário atual é participante.
  Stream<QuerySnapshot> getEventsStreamForUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('events')
        .where('participants', arrayContains: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Cria um novo evento no Firestore
  Future<void> createEvent(
      String name,
      String? description,
      String? eventDate,
      int? peopleCount,
      List<EventItem> items) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum usuário logado para criar o evento.');
    }

    final List<Map<String, dynamic>> itemsAsMaps =
        items.map((item) => item.toMap()).toList();
    final newEventRef = _firestore.collection('events').doc();

    final Map<String, dynamic> eventData = {
      'id': newEventRef.id,
      'name': name,
      'description': description,
      'eventDate': eventDate,
      'peopleCount': peopleCount,
      'createdAt': FieldValue.serverTimestamp(),
      'hostId': user.uid,
      'hostName': user.displayName ?? user.email,
      'participants': [user.uid],
      'items': itemsAsMaps,
      'pendingInvites': [], // Inicializa array de convites pendentes
    };
    await newEventRef.set(eventData);
  }

  /// Atualiza um evento existente no Firestore
  Future<void> updateEvent(
      String eventId,
      String name,
      String? description,
      String? eventDate,
      int? peopleCount,
      List<EventItem> items) async {
    try {
      final List<Map<String, dynamic>> itemsAsMaps =
          items.map((item) => item.toMap()).toList();
      final eventRef = _firestore.collection('events').doc(eventId);
      await eventRef.update({
        'name': name,
        'description': description,
        'eventDate': eventDate,
        'peopleCount': peopleCount,
        'items': itemsAsMaps,
      });
    } catch (e) {
      print("Erro ao ATUALIZAR evento: $e");
      rethrow;
    }
  }

  /// Exclui um evento do Firestore
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      print("Erro ao excluir evento: $e");
    }
  }

  // --- MÉTODOS DE CONVITE DE EVENTO ---

  Stream<QuerySnapshot> getEventInvitesStream() {
    final User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('event_invites')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  Future<void> sendEventInvite({
    required String eventId,
    required Map<String, dynamic> eventData,
    required String friendId,
  }) async {
    if (_auth.currentUser == null) return;
    WriteBatch batch = _firestore.batch();
    final inviteRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('event_invites')
        .doc(eventId);
    batch.set(inviteRef, {
      'eventName': eventData['name'],
      'eventDate': eventData['eventDate'],
      'hostName': eventData['hostName'],
      'sentAt': FieldValue.serverTimestamp(),
    });
    final eventRef = _firestore.collection('events').doc(eventId);
    batch.update(eventRef, {
      'pendingInvites': FieldValue.arrayUnion([friendId])
    });
    await batch.commit();
  }

  Future<void> acceptEventInvite(QueryDocumentSnapshot invite) async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    final String eventId = invite.id;
    final String myUid = user.uid;
    WriteBatch batch = _firestore.batch();
    final eventRef = _firestore.collection('events').doc(eventId);
    batch.update(eventRef, {
      'participants': FieldValue.arrayUnion([myUid]),
      'pendingInvites': FieldValue.arrayRemove([myUid])
    });
    batch.delete(invite.reference);
    await batch.commit();
  }

  Future<bool> declineEventInvite(String inviteId) async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      WriteBatch batch = _firestore.batch();

      // 1. Remove o convite da lista do usuário
      final inviteRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('event_invites')
          .doc(inviteId);
      batch.delete(inviteRef);

      // 2. Remove do 'pendingInvites' no evento
      final eventRef = _firestore.collection('events').doc(inviteId);
      batch.update(eventRef, {
        'pendingInvites': FieldValue.arrayRemove([user.uid])
      });

      await batch.commit();
      return true; // Sucesso
    } catch (e) {
      print("Erro ao recusar convite de evento: $e");
      return false; // Falha
    }
  }
  // --- MÉTODOS DE INGRESSO E ITENS (CORRIGIDOS) ---

  Future<String> joinEventById(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário não logado.";
    try {
      final eventRef = _firestore.collection('events').doc(eventId.trim());
      await eventRef.update({
        'participants': FieldValue.arrayUnion([user.uid])
      });
      return "Sucesso";
    } catch (e) {
      print("Erro ao ingressar com ID: $e");
      return "Erro: Evento não encontrado ou falha ao ingressar.";
    }
  }

  Future<String> claimItemPortion(String eventId, String itemName,
      int quantityToClaim, User user) async {
    final eventRef = _firestore.collection('events').doc(eventId);
    try {
      await _firestore.runTransaction((transaction) async {
        final docSnap = await transaction.get(eventRef);
        if (!docSnap.exists) {
          throw Exception('Evento não encontrado');
        }
        final eventData = docSnap.data() as Map<String, dynamic>;
        final List<EventItem> items =
            (eventData['items'] as List<dynamic>? ?? [])
                .map((map) => EventItem.fromMap(map))
                .toList();

        final int itemIndex = items.indexWhere((item) => item.name == itemName);
        if (itemIndex == -1) {
          throw Exception('Item não encontrado na lista');
        }
        final EventItem item = items[itemIndex];
        final int available = item.quantityAvailable;
        if (quantityToClaim > available) {
          throw Exception(
              'Apenas $available itens estão disponíveis. Você tentou pegar $quantityToClaim.');
        }

        final int existingContributorIndex =
            item.contributors.indexWhere((c) => c.uid == user.uid);

        if (existingContributorIndex != -1) {
          final existingContributor = item.contributors[existingContributorIndex];
          final int newQuantity =
              existingContributor.quantityTaken + quantityToClaim;
          final updatedContributor = Contributor(
            uid: existingContributor.uid,
            name: existingContributor.name,
            photoUrl: existingContributor.photoUrl,
            quantityTaken: newQuantity,
          );
          item.contributors[existingContributorIndex] = updatedContributor;
        } else {
          final newContributor = Contributor(
            uid: user.uid,
            name: user.displayName ?? user.email ?? 'Usuário',
            photoUrl: user.photoURL,
            quantityTaken: quantityToClaim,
          );
          item.contributors.add(newContributor);
        }
        items[itemIndex] = item;
        final List<Map<String, dynamic>> itemsAsMaps =
            items.map((i) => i.toMap()).toList();
        transaction.update(eventRef, {'items': itemsAsMaps});
      });
      return "Item reivindicado com sucesso!";
    } catch (e) {
      print("Erro ao reivindicar item: $e");
      return "Erro: ${e.toString()}";
    }
  }

  Future<String> releaseMyClaim(String eventId, String itemName, User user) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    try {
      await _firestore.runTransaction((transaction) async {
        final docSnap = await transaction.get(eventRef);
        if (!docSnap.exists) {
          throw Exception('Evento não encontrado');
        }

        final eventData = docSnap.data() as Map<String, dynamic>;
        final List<EventItem> items =
            (eventData['items'] as List<dynamic>? ?? [])
                .map((map) => EventItem.fromMap(map))
                .toList();

        final int itemIndex = items.indexWhere((item) => item.name == itemName);
        if (itemIndex == -1) {
          throw Exception('Item não encontrado');
        }

        // Remove o contribuidor da lista (pelo UID)
        items[itemIndex].contributors.removeWhere((c) => c.uid == user.uid);

        // Salva a lista de itens atualizada de volta no Firestore
        final List<Map<String, dynamic>> itemsAsMaps =
            items.map((i) => i.toMap()).toList();
        transaction.update(eventRef, {'items': itemsAsMaps});
      });
      return "Item liberado com sucesso!";
    } catch (e) {
      print("Erro ao liberar item: $e");
      return "Erro: ${e.toString()}";
    }
  }
  
  // VVVVVV O MÉTODO QUE ESTAVA FALTANDO VVVVVV

  /// Permite que um participante saia de um evento
  /// Isso remove o participante da lista E libera os itens que ele pegou.
  Future<String> leaveEvent(String eventId, User user) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    try {
      await _firestore.runTransaction((transaction) async {
        final docSnap = await transaction.get(eventRef);
        if (!docSnap.exists) {
          throw Exception('Evento não encontrado');
        }

        final eventData = docSnap.data() as Map<String, dynamic>;
        
        final List<EventItem> items =
            (eventData['items'] as List<dynamic>? ?? [])
                .map((map) => EventItem.fromMap(map))
                .toList();
                
        final List<String> participants =
            List<String>.from(eventData['participants'] ?? []);

        // 1. Libera os Itens
        for (var item in items) {
          item.contributors.removeWhere((c) => c.uid == user.uid);
        }
        final List<Map<String, dynamic>> itemsAsMaps =
            items.map((i) => i.toMap()).toList();

        // 2. Remove o Participante
        participants.removeWhere((uid) => uid == user.uid);

        // 3. Atualiza o Documento
        transaction.update(eventRef, {
          'items': itemsAsMaps,
          'participants': participants,
        });
      });
      return "Sucesso";
    } catch (e) {
      print("Erro ao sair do evento: $e");
      return "Erro: ${e.toString()}";
    }
  }
}