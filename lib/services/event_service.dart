// lib/services/event_service.dart
import 'package:Olha_o_Role/models/contributor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Olha_o_Role/services/event_item.dart'; // Precisamos criar este modelo

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna um Stream de eventos onde o usuário atual é participante.
  Stream<QuerySnapshot> getEventsStreamForUser() {
    final User? user = _auth.currentUser;
    if (user == null) {
      // Retorna um stream vazio se o usuário não estiver logado
      return const Stream.empty();
    }

    return _firestore
        .collection('events')
        .where('participants',
            arrayContains: user.uid) // A mágica está aqui!
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> inviteFriendToEvent(String eventId, String friendId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);

      // FieldValue.arrayUnion() é a forma segura de adicionar um item
      // a um array no Firestore, garantindo que não haja duplicatas.
      await eventRef.update({
        'participants': FieldValue.arrayUnion([friendId])
      });
    } catch (e) {
      print("Erro ao convidar amigo: $e");
    }
  }
  Future<void> updateEvent(
      String eventId,
      String name,
      String? description,
      String? eventDate,
      int? peopleCount,
      List<EventItem> items) async {
    try {
      // Converte a lista de EventItem para uma lista de Mapas
      final List<Map<String, dynamic>> itemsAsMaps =
          items.map((item) => item.toMap()).toList();

      // Pega a referência do documento
      final eventRef = _firestore.collection('events').doc(eventId);

      // Usa .update() para alterar os campos
      await eventRef.update({
        'name': name,
        'description': description,
        'eventDate': eventDate,
        'peopleCount': peopleCount,
        'items': itemsAsMaps,
        // Nota: Não atualizamos o host, data de criação ou participantes aqui.
      });
    } catch (e) {
      print("Erro ao ATUALIZAR evento: $e");
      rethrow; // Lança o erro para a tela tratar
    }
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

    // Converte a lista de EventItem para uma lista de Mapas
    final List<Map<String, dynamic>> itemsAsMaps =
        items.map((item) => item.toMap()).toList();

    // Cria a referência do novo documento
    final newEventRef = _firestore.collection('events').doc();

    // Cria o mapa de dados
    final Map<String, dynamic> eventData = {
      'id': newEventRef.id, // Salva o ID dentro do próprio doc
      'name': name,
      'description': description,
      'eventDate': eventDate,
      'peopleCount': peopleCount,
      'createdAt': FieldValue.serverTimestamp(),
      'hostId': user.uid,
      'hostName': user.displayName ?? user.email,
      'participants': [user.uid], // O criador é o primeiro participante
      'items': itemsAsMaps,
    };

    // Envia para o Firestore
    await newEventRef.set(eventData);
  }

  /// Exclui um evento do Firestore
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      print("Erro ao excluir evento: $e");
    }
  }
// (SUBSTITUA ESTE MÉTODO INTEIRO)

  /// Reivindica uma 'porção' de um item (ex: 2 dos 10 refrigerantes)
  /// Usa uma transação para garantir segurança contra 'disputas'
  Future<String> claimItemPortion(String eventId, String itemName,
      int quantityToClaim, User user) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    try {
      await _firestore.runTransaction((transaction) async {
        final docSnap = await transaction.get(eventRef);

        if (!docSnap.exists) {
          throw Exception('Evento não encontrado');
        }

        // Pega a lista de itens atual
        final eventData = docSnap.data() as Map<String, dynamic>;
        final List<EventItem> items =
            (eventData['items'] as List<dynamic>? ?? [])
                .map((map) => EventItem.fromMap(map))
                .toList();

        // Encontra o item específico que queremos alterar
        final int itemIndex = items.indexWhere((item) => item.name == itemName);
        if (itemIndex == -1) {
          throw Exception('Item não encontrado na lista');
        }

        final EventItem item = items[itemIndex];

        // --- Lógica de Validação ---
        final int available = item.quantityAvailable;
        if (quantityToClaim > available) {
          throw Exception(
              'Apenas $available itens estão disponíveis. Você tentou pegar $quantityToClaim.');
        }

        // --- INÍCIO DA CORREÇÃO ---
        
        // Verifica se o usuário já está na lista
        final int existingContributorIndex =
            item.contributors.indexWhere((c) => c.uid == user.uid);

        if (existingContributorIndex != -1) {
          // Se já existe, ATUALIZA A QUANTIDADE
          final existingContributor = item.contributors[existingContributorIndex];
          final int newQuantity =
              existingContributor.quantityTaken + quantityToClaim;

          // Cria um NOVO objeto Contributor com a soma
          final updatedContributor = Contributor(
            uid: existingContributor.uid,
            name: existingContributor.name,
            photoUrl: existingContributor.photoUrl,
            quantityTaken: newQuantity, // A nova quantidade somada
          );

          // Substitui o antigo pelo novo na lista
          item.contributors[existingContributorIndex] = updatedContributor;
        } else {
          // Se não existe, ADICIONA um novo
          final newContributor = Contributor(
            uid: user.uid,
            name: user.displayName ?? user.email ?? 'Usuário',
            photoUrl: user.photoURL,
            quantityTaken: quantityToClaim, // A quantidade inicial
          );
          item.contributors.add(newContributor);
        }
        
        // --- FIM DA CORREÇÃO ---

        // Atualiza o item dentro da lista de itens
        items[itemIndex] = item;

        // Converte a lista de EventItem de volta para lista de Mapas
        final List<Map<String, dynamic>> itemsAsMaps =
            items.map((i) => i.toMap()).toList();

        // Salva a lista de itens *inteira* de volta no documento
        transaction.update(eventRef, {'items': itemsAsMaps});
      });
      return "Item reivindicado com sucesso!";
    } catch (e) {
      print("Erro ao reivindicar item: $e");
      return "Erro: ${e.toString()}";
    }
  }
  /// Retorna um Stream de convites de evento PENDENTES.
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
  Future<String> joinEventById(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return "Usuário não logado.";

    try {
      final eventRef = _firestore.collection('events').doc(eventId.trim());
      
      // Verifica se o evento existe
      final docSnap = await eventRef.get();
      if (!docSnap.exists) {
        return "Erro: Evento não encontrado.";
      }
      
      // Adiciona o usuário ao array 'participants'
      // A regra de segurança que vamos adicionar permitirá isso.
      await eventRef.update({
        'participants': FieldValue.arrayUnion([user.uid])
      });
      return "Sucesso"; // Retorna sucesso
      
    } catch (e) {
      print("Erro ao ingressar com ID: $e");
      return "Erro: Falha ao ingressar no evento.";
    }
  }

  /// Anfitrião envia um convite de evento para um amigo.
 Future<void> sendEventInvite({
    required String eventId,
    required Map<String, dynamic> eventData, 
    required String friendId,
  }) async {
    if (_auth.currentUser == null) return;

    WriteBatch batch = _firestore.batch();

    // 1. Cria o convite na sub-coleção do amigo (como antes)
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

    // 2. (NOVO) Adiciona o ID do amigo ao array 'pendingInvites' no evento
    final eventRef = _firestore.collection('events').doc(eventId);
    batch.update(eventRef, {
      'pendingInvites': FieldValue.arrayUnion([friendId])
    });

    // Executa as duas operações
    await batch.commit();
  }

  /// Convidado ACEITA um convite de evento.
  Future<void> acceptEventInvite(QueryDocumentSnapshot invite) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final String eventId = invite.id;
    final String myUid = user.uid;

    WriteBatch batch = _firestore.batch();

    // 1. Adiciona ao 'participants' (como antes)
    final eventRef = _firestore.collection('events').doc(eventId);
    batch.update(eventRef, {
      'participants': FieldValue.arrayUnion([myUid]),
      // 2. (NOVO) Remove do 'pendingInvites'
      'pendingInvites': FieldValue.arrayRemove([myUid])
    });

    // 3. Exclui o convite pendente (como antes)
    batch.delete(invite.reference);

    await batch.commit();
  }

  /// Convidado RECUSA um convite de evento.
  Future<void> declineEventInvite(String inviteId) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    WriteBatch batch = _firestore.batch();

    // 1. Remove o convite da lista do usuário
    final inviteRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('event_invites')
        .doc(inviteId);
    batch.delete(inviteRef);

    // 2. (NOVO) Remove do 'pendingInvites' no evento
    final eventRef = _firestore.collection('events').doc(inviteId);
    batch.update(eventRef, {
      'pendingInvites': FieldValue.arrayRemove([user.uid])
    });

    await batch.commit();
  }
  /// Libera a 'porção' de um item que o usuário atual pegou
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
}