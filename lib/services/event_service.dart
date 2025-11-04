// lib/services/event_service.dart

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

  /// Atribui um item a um usuário (a sua nova feature!)
  Future<void> assignItemToUser(
      String eventId, String itemName, User user) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final docSnap = await eventRef.get();

      if (!docSnap.exists) {
        throw Exception('Evento não encontrado');
      }

      // Pega a lista de itens atual
      List<dynamic> items = docSnap.data()?['items'] ?? [];

      // Converte para um tipo que podemos modificar
      List<Map<String, dynamic>> modifiableItems =
          List<Map<String, dynamic>>.from(items);

      // Encontra o item pelo nome
      int itemIndex =
          modifiableItems.indexWhere((item) => item['name'] == itemName);

      if (itemIndex != -1) {
        // Atualiza os campos do item
        modifiableItems[itemIndex]['broughtBy'] = user.uid;
        modifiableItems[itemIndex]['broughtByName'] =
            user.displayName ?? user.email;
      }

      // Salva a lista de itens *inteira* de volta no documento
      await eventRef.update({'items': modifiableItems});
    } catch (e) {
      print("Erro ao atribuir item: $e");
    }
  }

  /// Desatribui um item (caso o usuário desista)
  Future<void> unassignItem(String eventId, String itemName) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final docSnap = await eventRef.get();

      if (!docSnap.exists) {
        throw Exception('Evento não encontrado');
      }

      List<dynamic> items = docSnap.data()?['items'] ?? [];
      List<Map<String, dynamic>> modifiableItems =
          List<Map<String, dynamic>>.from(items);
      int itemIndex =
          modifiableItems.indexWhere((item) => item['name'] == itemName);

      if (itemIndex != -1) {
        // Apenas limpa os campos
        modifiableItems[itemIndex]['broughtBy'] = null;
        modifiableItems[itemIndex]['broughtByName'] = null;
      }

      await eventRef.update({'items': modifiableItems});
    } catch (e) {
      print("Erro ao desatribuir item: $e");
    }
  }
}