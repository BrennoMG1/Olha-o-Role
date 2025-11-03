import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'create_event_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event.dart';
import '/auth/auth_service.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  // Variável para guardar a referência ao Future que abre a caixa.
  // Isso garante que a operação de abrir a caixa só será executada UMA VEZ.
  late final Future<Box<Event>> _eventsBoxFuture;
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Inicializamos o Future aqui, no initState.
    _eventsBoxFuture = _openEventsBox();
    _loadCurrentUser();
  }
  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  /// Método auxiliar para abrir a caixa de eventos de forma segura.
  Future<Box<Event>> _openEventsBox() async {
    if (Hive.isBoxOpen('events')) {
      return Hive.box<Event>('events');
    } else {
      return await Hive.openBox<Event>('events');
    }
  }

  Future<void> _showDeleteConfirmationDialog(Event event) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O usuário deve tocar em um botão para fechar.
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 230, 210, 185),
          title: const Text(
            'Confirmar Exclusão',
            style: TextStyle(fontFamily: 'Itim'),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Você tem certeza que deseja excluir o evento "${event.name}"?',
                  style: const TextStyle(fontFamily: 'Itim'),
                ),
                const Text(
                  '\nEsta ação não pode ser desfeita.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(fontFamily: 'Itim')),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Excluir', style: TextStyle(fontFamily: 'Itim')),
              onPressed: () {
                // A MÁGICA ACONTECE AQUI!
                event.delete();
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // O seu método build original está correto e permanece aqui...
    // Ele usa o FutureBuilder e o ValueListenableBuilder para construir a lista
    // e chama o _buildEventCard para cada item.
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
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
          children: <Widget>[// VVVVV SUBSTITUA O DRAWERHEADER ANTIGO POR ISTO VVVVV
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUser?.displayName ?? 'Usuário', // Nome do usuário
                style: const TextStyle(
                  fontFamily: 'Itim',
                  fontSize: 18,
                  color: Color.fromARGB(255, 63, 39, 28),
                ),
              ),
              accountEmail: Text(
                _currentUser?.email ?? '', // Email do usuário
                style: const TextStyle(
                  fontFamily: 'Itim',
                  color: Color.fromARGB(255, 63, 39, 28),
                ),
              ),
              currentAccountPicture: CircleAvatar(
                // Aqui está a mágica da foto:
                backgroundImage: (_currentUser?.photoURL != null)
                    ? NetworkImage(_currentUser!.photoURL!) // Usa a foto (ex: Google)
                    : null,
                backgroundColor: Colors.white,
                child: (_currentUser?.photoURL == null)
                    ? const Icon( // Fallback: Ícone de pessoa
                        Icons.person,
                        size: 40,
                        color: Color.fromARGB(255, 63, 39, 28),
                      )
                    : null,
              ),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 211, 173, 92), // Cor de fundo
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil - em breve',style: TextStyle(decoration: TextDecoration.lineThrough),),
              
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações - em breve' ,style: TextStyle(decoration: TextDecoration.lineThrough),),
              
            ),
            const Divider(), // Um separador visual
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair',
                style: TextStyle(color: Colors.red, fontFamily: 'Itim'),
              ),
              onTap: () async {
                // 1. Fecha o drawer para o usuário ver a tela de login
                Navigator.pop(context); 
                
                // 2. Chama o método de logout do seu serviço
                await _authService.signOut();
                
                // 3. O seu "AuthGate" (que deve estar escutando 
                //    o authStateChanges) fará o resto, 
                //    redirecionando para a tela de login.
              },
            ),
          ],
        ),
      ),
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
              child: FutureBuilder<Box<Event>>(
                future: _eventsBoxFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Erro ao carregar eventos: ${snapshot.error}'));
                  }

                  final eventBox = snapshot.data!;
                  return ValueListenableBuilder(
                    valueListenable: eventBox.listenable(),
                    builder: (context, Box<Event> box, _) {
                      final events = box.values.toList().cast<Event>();

                      if (events.isEmpty) {
                        return const Center(
                          child: Text('Nenhum evento por aqui ainda!',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 63, 39, 28),
                                  fontFamily: 'Itim',
                                  fontSize: 25)),
                        );
                      }
                      
                      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                      return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          // Chamando a versão CORRETA e ÚNICA do _buildEventCard
                          return _buildEventCard(events[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
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
                          style: TextStyle(fontSize: 18, decoration: TextDecoration.lineThrough)),
                      trailing: Text("Em Desenvolvimento",
                          style: TextStyle(fontSize: 12)),
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

  
  Widget _buildEventCard(Event event) {
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
          event.name,
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
              '📅 Data do Evento: ${event.eventDate ?? "Não definida"}',
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Itim',
              ),
            ),
            Text(
              'Itens na lista: ${event.items.length}',
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
          _navigateToEventDetails(event);
        },
      ),
    );
  }

  // Método ATUALIZADO para mostrar todos os detalhes do evento
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
              value,
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

  // MÉTODO _navigateToEventDetails TOTALMENTE ATUALIZADO
  void _navigateToEventDetails(Event event) {
    // Formata a data de criação para o padrão DD/MM/AAAA
    final formattedCreationDate = 
        "${event.createdAt.day.toString().padLeft(2, '0')}/"
        "${event.createdAt.month.toString().padLeft(2, '0')}/"
        "${event.createdAt.year}";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 245, 235, 220), // Um tom um pouco mais claro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        // Título centralizado com o nome do evento
        title: Center(
          child: Text(
            event.name,
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

              // Usando nosso helper widget para cada informação
              _buildInfoRow(Icons.calendar_today, 'Data do Evento:', event.eventDate ?? "Não definida"),
              _buildInfoRow(Icons.people, 'Quantidade de Pessoas:', '${event.peopleCount ?? 0} pessoas'),
              _buildInfoRow(Icons.description, 'Descrição:', event.description ?? "Nenhuma"),
              _buildInfoRow(Icons.vpn_key, 'ID do Evento:', event.id),
              _buildInfoRow(Icons.create, 'Data de Criação:', formattedCreationDate),

              const SizedBox(height: 20),

              // Seção de Itens do Evento
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

              // Mapeando a lista de itens para o novo widget de item
              ...event.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Ícone do item
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 226, 169), // Cor de fundo do ícone
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            // Pega a primeira letra do item ou um emoji
                            item.name.isNotEmpty ? item.name[0].toUpperCase() : '🛒',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nome do item
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontFamily: 'Itim', fontSize: 16),
                          ),
                        ),
                        // "Badge" de quantidade
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      ],
                    ),
                  ),
                );
              }),
              if (event.items.isEmpty)
                const Text(
                  'Nenhum item na lista.',
                  style: TextStyle(fontFamily: 'Itim', fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          // Os botões de ação continuam aqui
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(event);
            },
            child: const Text('Excluir', style: TextStyle(fontFamily: 'Itim')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(fontFamily: 'Itim', color: Color.fromARGB(255, 63, 39, 28))),
          ),
        ],
      ),
    );
  }
}