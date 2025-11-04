// lib/event_detail_screen.dart

import 'package:Olha_o_Role/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/services/event_item.dart';

class EventDetailScreen extends StatefulWidget {
  // 1. Recebemos o documento do evento ao navegar
  final QueryDocumentSnapshot event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 2. Variáveis de estado para guardar os dados do evento
  late String _eventName;
  late String _eventId;
  late Map<String, dynamic> _eventData;
  late List<EventItem> _items;

  @override
  void initState() {
    super.initState();
    // 3. Inicializamos o estado com os dados do documento
    _eventData = widget.event.data() as Map<String, dynamic>;
    _eventId = widget.event.id;
    _eventName = _eventData['name'] ?? 'Detalhes do Evento';

    // Converte a lista de mapas para uma lista de EventItem
    _items = (_eventData['items'] as List<dynamic>)
        .map((itemData) => EventItem.fromMap(itemData))
        .toList();
  }

  // 4. Movemos o widget auxiliar para cá
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Itim',
              color: Color.fromARGB(255, 63, 39, 28),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? "Nenhum(a)" : value,
              style: const TextStyle(
                fontFamily: 'Itim',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Movemos o diálogo de confirmação de exclusão para cá
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 230, 210, 185),
          title: const Text('Confirmar Exclusão',
              style: TextStyle(fontFamily: 'Itim')),
          content: Text(
              'Você tem certeza que deseja excluir o evento "$_eventName"?\nEsta ação não pode ser desfeita.',
              style: const TextStyle(fontFamily: 'Itim')),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancelar', style: TextStyle(fontFamily: 'Itim')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child:
                  const Text('Excluir', style: TextStyle(fontFamily: 'Itim')),
              onPressed: () async {
                await _eventService.deleteEvent(_eventId);
                if (mounted) {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  Navigator.of(context).pop(); // Volta para a lista de eventos
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formata a data de criação
    final Timestamp? createdAt = _eventData['createdAt'];
    final String formattedCreationDate = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'Indefinida';

    return Scaffold(
      // 6. AppBar com o mesmo estilo
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        title: Text(
          _eventName,
          style: const TextStyle(
              color: Color.fromARGB(255, 63, 39, 28),
              fontFamily: 'Itim',
              fontSize: 30),
        ),
        actions: [
          // 7. Botão de Excluir movido para o AppBar
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Colors.red.shade700, size: 28),
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
      // 8. Body com o background e SingleChildScrollView
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/background.png"),
              fit: BoxFit.cover,
              opacity: 0.18),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Card de Informações ---
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.calendar_today, 'Data do Evento:',
                          _eventData['eventDate'] ?? "Não definida"),
                      _buildInfoRow(Icons.people, 'Quantidade de Pessoas:',
                          '${_eventData['peopleCount'] ?? 0} pessoas'),
                      _buildInfoRow(Icons.description, 'Descrição:',
                          _eventData['description'] ?? "Nenhuma"),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.vpn_key, 'ID do Evento:', _eventId),
                      _buildInfoRow(
                          Icons.create, 'Criado em:', formattedCreationDate),
                      _buildInfoRow(Icons.person_outline, 'Anfitrião:',
                          _eventData['hostName'] ?? 'Não definido'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Card da Lista de Itens ---
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🛒 Itens do Evento',
                        style: TextStyle(
                          fontFamily: 'Itim',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color.fromARGB(255, 63, 39, 28),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),

                      // 9. A lista de itens interativa (lógica movida do pop-up)
                      _buildInteractiveItemsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 10. Widget que constrói a lista de itens interativa
  Widget _buildInteractiveItemsList() {
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Nenhum item na lista.',
            style: TextStyle(fontFamily: 'Itim', fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Usamos Column em vez de ListView.builder, pois já estamos
    // dentro de um SingleChildScrollView
    return Column(
      children: _items.map((item) {
        final bool isAssigned = item.broughtBy != null;
        final bool isMe = item.broughtBy == _currentUser?.uid;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.green.withOpacity(0.05)
                  : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isMe
                    ? Colors.green.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                // "Badge" de quantidade
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 230, 210, 185),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 63, 39, 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nome do item e quem leva
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style:
                            const TextStyle(fontFamily: 'Itim', fontSize: 16),
                      ),
                      if (isAssigned)
                        Text(
                          isMe
                              ? "Você vai levar!"
                              : "Por: ${item.broughtByName ?? 'Alguém'}",
                          style: TextStyle(
                              fontFamily: 'Itim',
                              fontSize: 12,
                              color: isMe
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),

                // --- O BOTÃO DE ESCOLHER ---
                if (isMe)
                  // Se sou eu, botão de "Cancelar"
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.red.shade700),
                    onPressed: () async {
                      await _eventService.unassignItem(_eventId, item.name);
                      // 11. Atualiza o estado da página
                      setState(() {
                        item.broughtBy = null;
                        item.broughtByName = null;
                      });
                    },
                  )
                else if (!isAssigned)
                  // Se ninguém pegou, botão de "Pegar"
                  IconButton(
                    icon: Icon(Icons.add_shopping_cart,
                        color: Colors.green.shade700),
                    onPressed: () async {
                      if (_currentUser == null) return;
                      await _eventService.assignItemToUser(
                          _eventId, item.name, _currentUser!);
                      // 11. Atualiza o estado da página
                      setState(() {
                        item.broughtBy = _currentUser!.uid;
                        item.broughtByName = _currentUser!.displayName ??
                            _currentUser!.email;
                      });
                    },
                  )
                else
                  // Se já foi pego por outro, ícone de "check"
                  Icon(Icons.check_circle, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}