import 'package:Olha_o_Role/auth/auth_service.dart';
import 'package:Olha_o_Role/services/event_item.dart';
import 'package:Olha_o_Role/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'create_event_screen.dart';
import 'join_event_screen.dart';
import 'event_detail_screen.dart';
import 'friends_screen.dart';
import '/services/friends_services.dart';
import 'profile_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  // Nossos novos serviços
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();
  final FriendsService _friendsService = FriendsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _photoCacheKey = DateTime.now().millisecondsSinceEpoch.toString();

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
    final docRef = _firestore.collection('users').doc(_currentUser!.uid);

    try {
      final docSnap = await docRef.get();

      // --- Geração do friendCode (a mesma lógica de sempre) ---
      // Geramos o código aqui, pois vamos precisar dele em ambos os casos.
      final String fullHex = _currentUser!.uid.hashCode
          .abs()
          .toRadixString(16)
          .padLeft(8, '0')
          .toUpperCase();
      final String friendCode = fullHex.substring(fullHex.length - 8);
      // --- Fim da geração ---

      if (docSnap.exists) {
        // --- CASO 1: Documento EXISTE ---
        docData = docSnap.data() as Map<String, dynamic>?;

        if (docData != null && (docData['friendCode'] == null)) {
          // Documento existe, mas SEM friendCode (usuário antigo)
          await docRef.update({'friendCode': friendCode});
          docData['friendCode'] = friendCode; // Atualiza localmente
        }
      } else {
        // --- CASO 2: Documento NÃO EXISTE ---
        // (Usuário do Google "órfão" que pulou o setup)
        
        // Cria o mapa de dados do zero
        docData = {
          'uid': _currentUser!.uid,
          'email': _currentUser!.email,
          'displayName': _currentUser!.displayName ?? _currentUser!.email?.split('@')[0],
          'photoURL': _currentUser!.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
          'friendCode': friendCode, // Adiciona o friendCode
        };

        // Cria o documento no Firestore
        await docRef.set(docData, SetOptions(merge: true));
      }
    } catch (e) {
      print("Erro ao buscar/criar dados do usuário: $e");
    }

    if (mounted) {
      setState(() {
        _userDocumentData = docData;
        _photoCacheKey = DateTime.now().millisecondsSinceEpoch.toString();
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
                  ? NetworkImage(
                      '${_currentUser!.photoURL!}?key=$_photoCacheKey') // <-- CORREÇÃO AQUI
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
              title: const Text('Perfil', style: TextStyle(fontFamily: 'Itim')), // <-- 1. Removido o "em breve"
              onTap: () { // <-- 2. Adicionado o onTap
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ).then((_) {
                  // Ao retornar da ProfileScreen, force o recarregamento
                  _loadCurrentUserData(); 
                });
            },
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
                    StreamBuilder<QuerySnapshot>(
                      stream: _eventService.getEventInvitesStream(),
                      builder: (context, snapshot) {
                        final bool hasInvites =
                            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                        return ListTile(
                          leading: Badge(
                            // O Badge (ponto vermelho)
                            isLabelVisible: hasInvites,
                            child: const Icon(Icons.arrow_forward, size: 28),
                          ),
                          title: const Text('Ingressar em um evento',
                              style: TextStyle(fontSize: 18)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const JoinEventScreen()),
                            );
                          },
                        );
                      },
                    ),
                  StreamBuilder<QuerySnapshot>(
                  stream: _friendsService.getFriendInvitesStream(),
                  builder: (context, snapshot) {
                    // Verifica se há algum convite pendente
                    final bool hasInvites =
                        snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                    return ListTile(
                      leading: Badge(
                        // O Badge (ponto vermelho)
                        isLabelVisible: hasInvites,
                        child: const Icon(Icons.people_outline, size: 28),
                      ),
                      title: const Text('Amigos',
                          style: TextStyle(fontSize: 18)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendsScreen(),
                          ),
                        );
                      },
                    );
                  },
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

}