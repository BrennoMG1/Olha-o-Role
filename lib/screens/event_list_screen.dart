// event_list_screen.dart (VERSÃO FIRESTORE)

import 'package:Olha_o_Role/auth/auth_service.dart';
import 'package:Olha_o_Role/services/event_item.dart';
import 'package:Olha_o_Role/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'create_event_screen.dart';
import 'join_event_screen.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  // Nossos novos serviços
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Variáveis de estado para o Drawer (como antes)
  Map<String, dynamic>? _userDocumentData;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData(); // Renomeei para ser mais claro
  }

  // Carrega os dados do *usuário* (para o Drawer)
  Future<void> _loadCurrentUserData() async {
    if (_currentUser == null) return;
    Map<String, dynamic>? docData;

    try {
      final docRef = _firestore.collection('users').doc(_currentUser!.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        docData = docSnap.data();
        if (docData != null && (docData['friendCode'] == null)) {
          final String fullHex = _currentUser!.uid.hashCode
              .abs()
              .toRadixString(16)
              .padLeft(8, '0')
              .toUpperCase();
          final String friendCode = fullHex.substring(fullHex.length - 8);
          await docRef.update({'friendCode': friendCode});
          docData['friendCode'] = friendCode;
        }
      }
    } catch (e) {
      print("Erro ao buscar dados do usuário: $e");
    }

    if (mounted) {
      setState(() {
        _userDocumentData = docData;
      });
    }
  }

  // Diálogo de confirmação de exclusão (agora chama o EventService)
  Future<void> _showDeleteConfirmationDialog(
      String eventId, String eventName) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 230, 210, 185),
          title: const Text('Confirmar Exclusão',
              style: TextStyle(fontFamily: 'Itim')),
          content: Text(
              'Você tem certeza que deseja excluir o evento "$eventName"?\nEsta ação não pode ser desfeita.',
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
                // CHAMA O SERVIÇO DE EXCLUSÃO
                await _eventService.deleteEvent(eventId);
                if (mounted) {
                  Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        // ... (seu AppBar é o mesmo) ...
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        title: const Text('Eventos',
            style: TextStyle(
                color: Color.fromARGB(255, 63, 39, 28),
                fontFamily: 'Itim',
                fontSize: 30)),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- Seu UserAccountsDrawerHeader (copiado) ---
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUser?.displayName ?? 'Usuário',
                style: const TextStyle(
                  fontFamily: 'Itim',
                  fontSize: 18,
                  color: Color.fromARGB(255, 63, 39, 28),
                ),
              ),
              accountEmail: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.email ?? '',
                    style: const TextStyle(
                      fontFamily: 'Itim',
                      color: Color.fromARGB(255, 63, 39, 28),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      final friendCode = _userDocumentData?['friendCode'];
                      if (friendCode != null) {
                        Clipboard.setData(ClipboardData(text: friendCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'ID de Amigo copiado para a área de transferência!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Text(
                          'ID: ${_userDocumentData?['friendCode'] ?? '...'}',
                          style: const TextStyle(
                            fontFamily: 'Itim',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 63, 39, 28),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_outlined,
                            size: 14,
                            color: Color.fromARGB(255, 63, 39, 28)),
                      ],
                    ),
                  ),
                ],
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: (_currentUser?.photoURL != null)
                    ? NetworkImage(_currentUser!.photoURL!)
                    : null,
                backgroundColor: Colors.white,
                child: (_currentUser?.photoURL == null)
                    ? const Icon(Icons.person,
                        size: 40, color: Color.fromARGB(255, 63, 39, 28))
                    : null,
              ),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 211, 173, 92),
              ),
            ),
            
            // --- Resto do seu Drawer (copiado) ---
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início', style: TextStyle(fontFamily: 'Itim')),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil - em breve',
                  style: TextStyle(
                      fontFamily: 'Itim',
                      decoration: TextDecoration.lineThrough)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações - em breve',
                  style: TextStyle(
                      fontFamily: 'Itim',
                      decoration: TextDecoration.lineThrough)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.red, fontFamily: 'Itim'),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _authService.signOut();
              },
            ),
          ],
        ),
      ),
      
      // --- O NOVO BODY COM STREAMBUILDER ---
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/background.png"),
              fit: BoxFit.cover,
              opacity: 0.18),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // Este StreamBuilder é o novo "coração" da tela
              child: StreamBuilder<QuerySnapshot>(
                stream: _eventService.getEventsStreamForUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Erro ao carregar eventos: ${snapshot.error}'));
                  }

                  final events = snapshot.data?.docs ?? [];

                  if (events.isEmpty) {
                    return const Center(
                      child: Text('Nenhum evento por aqui ainda!',
                          style: TextStyle(
                              color: Color.fromARGB(255, 63, 39, 28),
                              fontFamily: 'Itim',
                              fontSize: 25)),
                    );
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      // Cada 'event' é um DocumentSnapshot do Firestore
                      final event = events[index];
                      return _buildEventCard(event);
                    },
                  );
                },
              ),
            ),
            
            // --- Seu Card de Ações (copiado) ---
            Card(
              elevation: 4.0,
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add, size: 28),
                      title: const Text('Criar Evento',
                          style: TextStyle(fontSize: 18)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CreateEventScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_forward, size: 28),
                      title: const Text('Ingressar em um evento',
                          style: TextStyle(fontSize: 18)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const JoinEventScreen()),
                        );
                      },
                    ),
                    const ListTile(
                      leading: Icon(Icons.people_outline, size: 28),
                      title: Text('Amigos',
                          style: TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough)),
                      trailing: Text("Em Desenvolvimento",
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(bottom: 20)),
          ],
        ),
      ),
    );
  }

  // Card do evento (agora lê um QueryDocumentSnapshot)
  Widget _buildEventCard(QueryDocumentSnapshot event) {
    // Pega os dados do snapshot
    final data = event.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'Evento sem nome';
    final String eventDate = data['eventDate'] ?? 'Não definida';
    final List<dynamic> items = data['items'] ?? [];

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 211, 173, 92),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(
            Icons.event,
            color: Color.fromARGB(255, 63, 39, 28),
            size: 30,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 63, 39, 28),
            fontFamily: 'Itim',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '📅 Data do Evento: $eventDate',
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Itim',
              ),
            ),
            Text(
              'Itens na lista: ${items.length}',
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Itim',
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color.fromARGB(255, 63, 39, 28),
          size: 16,
        ),
        onTap: () {
          // --- ATUALIZE AQUI ---
          // Navega para a nova tela de detalhes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
      ),
    );
  }

  // Widget auxiliar para as linhas de informação (o mesmo de antes)
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
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

  // --- O NOVO DIÁLOGO DE DETALHES COM A FEATURE DE ESCOLHER ITEM ---
  void _navigateToEventDetails(QueryDocumentSnapshot event) {
    final data = event.data() as Map<String, dynamic>;
    final String eventId = event.id; // O ID do documento

    // Formata a data de criação
    final Timestamp? createdAt = data['createdAt'];
    final String formattedCreationDate = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'Indefinida';

    // Converte a lista de mapas para uma lista de EventItem
    final List<EventItem> items = (data['items'] as List<dynamic>)
        .map((itemData) => EventItem.fromMap(itemData))
        .toList();

    showDialog(
      context: context,
      // 'StatefulBuilder' é necessário para que possamos atualizar
      // a UI de itens (quem pegou) DENTRO do diálogo
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor:
                const Color.fromARGB(255, 245, 235, 220), 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Center(
              child: Text(
                data['name'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Itim',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color.fromARGB(255, 63, 39, 28),
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Divider(),
                  const SizedBox(height: 10),

                  _buildInfoRow(Icons.calendar_today, 'Data do Evento:',
                      data['eventDate'] ?? "Não definida"),
                  _buildInfoRow(Icons.people, 'Quantidade de Pessoas:',
                      '${data['peopleCount'] ?? 0} pessoas'),
                  _buildInfoRow(Icons.description, 'Descrição:',
                      data['description'] ?? "Nenhuma"),
                  _buildInfoRow(Icons.vpn_key, 'ID do Evento:',
                      eventId), // ID do evento
                  _buildInfoRow(
                      Icons.create, 'Criado em:', formattedCreationDate),

                  const SizedBox(height: 20),

                  const Text(
                    '🛒 Itens do Evento:',
                    style: TextStyle(
                      fontFamily: 'Itim',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color.fromARGB(255, 63, 39, 28),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- A NOVA LISTA DE ITENS INTERATIVA ---
                  ...items.map((item) {
                    final bool isAssigned = item.broughtBy != null;
                    final bool isMe = item.broughtBy == _currentUser?.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // "Badge" de quantidade
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromARGB(255, 230, 210, 185),
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
                                    style: const TextStyle(
                                        fontFamily: 'Itim', fontSize: 16),
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
                                  await _eventService.unassignItem(
                                      eventId, item.name);
                                  // Atualiza a UI do diálogo
                                  setDialogState(() {
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
                                      eventId, item.name, _currentUser!);
                                  // Atualiza a UI do diálogo
                                  setDialogState(() {
                                    item.broughtBy = _currentUser!.uid;
                                    item.broughtByName =
                                        _currentUser!.displayName ??
                                            _currentUser!.email;
                                  });
                                },
                              )
                            else
                              // Se já foi pego por outro, ícone de "check"
                              Icon(Icons.check_circle,
                                  color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (items.isEmpty)
                    const Text(
                      'Nenhum item na lista.',
                      style: TextStyle(
                          fontFamily: 'Itim', fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                onPressed: () {
                  Navigator.pop(context); // Fecha diálogo de detalhes
                  _showDeleteConfirmationDialog(eventId, data['name']);
                },
                child:
                    const Text('Excluir', style: TextStyle(fontFamily: 'Itim')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar',
                    style: TextStyle(
                        fontFamily: 'Itim',
                        color: Color.fromARGB(255, 63, 39, 28))),
              ),
            ],
          );
        },
      ),
    );
  }
}