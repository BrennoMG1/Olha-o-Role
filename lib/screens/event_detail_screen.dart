// lib/event_detail_screen.dart (VERSÃO COMPLETA E CORRIGIDA)

import 'package:Olha_o_Role/models/contributor.dart';
import 'package:Olha_o_Role/services/event_service.dart';
import 'package:Olha_o_Role/services/friends_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para o input de números
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/services/event_item.dart';
import 'create_event_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // --- Serviços e Variáveis de Estado ---
  final EventService _eventService = EventService();
  final FriendsService _friendsService = FriendsService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _eventName;
  late String _eventId;
  late Map<String, dynamic> _eventData;
  late List<EventItem> _items;
  late List<String> _participants;
  late Set<String> _pendingInviteFriendIds;
  final Set<String> _locallyInvitedFriendIds = {};
  bool _isHost = false;

  // --- Métodos de Ciclo de Vida (initState) ---
  @override
  void initState() {
    super.initState();
    _loadDataFromWidget(
      widget.event.data() as Map<String, dynamic>,
      widget.event.id,
    );
  }

  // --- Métodos de Lógica ---

  void _loadDataFromWidget(Map<String, dynamic> data, String docId) {
    _eventData = data;
    _eventId = docId;
    _eventName = _eventData['name'] ?? 'Detalhes do Evento';

    _items = (_eventData['items'] as List<dynamic>)
        .map((itemData) => EventItem.fromMap(itemData))
        .toList();

    _participants = List<String>.from(_eventData['participants'] ?? []);

    // --- ATUALIZAÇÃO AQUI ---
    // Carrega os IDs dos convites pendentes do documento do evento
    _pendingInviteFriendIds =
        Set<String>.from(_eventData['pendingInvites'] ?? []);

    _isHost = (_eventData['hostId'] == _currentUser?.uid);
  }

/// 1. MÉTODO PARA BUSCAR OS DADOS DOS PARTICIPANTES
  /// Busca todos os documentos de usuário da lista de UIDs
  Future<List<DocumentSnapshot>> _fetchParticipantDetails() async {
    // Cria uma lista de "Futures" (tarefas)
    final futures = _participants.map((uid) {
      return _firestore.collection('users').doc(uid).get();
    }).toList();

    // Executa todas as tarefas em paralelo e espera o resultado
    final results = await Future.wait(futures);
    
    // Retorna apenas os documentos que existem
    return results.where((doc) => doc.exists).toList();
  }
  
  Future<void> _showLeaveConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 230, 210, 185),
          title: const Text('Sair do Evento',
              style: TextStyle(fontFamily: 'Itim')),
          content: const Text(
              'Você tem certeza que quer sair deste evento?\n\nOs itens que você se comprometeu a levar serão liberados.',
              style: TextStyle(fontFamily: 'Itim')),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancelar', style: TextStyle(fontFamily: 'Itim')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Sair', style: TextStyle(fontFamily: 'Itim')),
              
              // --- INÍCIO DA CORREÇÃO ---
              onPressed: () async {
                // 1. Verificamos se o usuário é nulo PRIMEIRO.
                if (_currentUser == null) {
                  // Se for nulo, mostramos um erro e paramos.
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erro: Usuário não encontrado.'),
                        backgroundColor: Colors.red),
                  );
                  return; // Para a execução aqui
                }

                // 2. Se chegamos aqui, o Dart SABE que _currentUser NÃO é nulo.
                //    Agora podemos usar o '!' com segurança.
                final result =
                    await _eventService.leaveEvent(_eventId, _currentUser!);

                if (mounted) {
                  if (result == "Sucesso") {
                    Navigator.of(context).pop(); // Fecha o diálogo
                    Navigator.of(context).pop(); // Volta para a lista de eventos
                  } else {
                    Navigator.of(context).pop(); // Fecha o diálogo
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(result), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              // --- FIM DA CORREÇÃO ---
            ),
          ],
        );
      },
    );
  }
  /// 2. O WIDGET DO CARD DE PARTICIPANTES
  /// Constrói o card principal que usa um FutureBuilder
  Widget _buildParticipantsCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👥 Participantes (${_participants.length})',
              style: const TextStyle(
                fontFamily: 'Itim',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color.fromARGB(255, 63, 39, 28),
              ),
            ),
            const Divider(height: 20),
            
            // FutureBuilder para carregar os perfis
            FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchParticipantDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar participantes.');
                }

                final participantDocs = snapshot.data!;
                
                if (participantDocs.isEmpty) {
                  return const Text('Nenhum participante encontrado.');
                }

                return Column(
                  children: participantDocs.map((doc) {
                    // Chama o helper para construir cada linha
                    return _buildParticipantTile(doc);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// 3. O WIDGET DE CADA LINHA DE PARTICIPANTE
  /// Constrói o ListTile (ícone + nome) para um único participante
  Widget _buildParticipantTile(DocumentSnapshot userDoc) {
    final data = userDoc.data() as Map<String, dynamic>;
    final bool isHost = (userDoc.id == _eventData['hostId']);

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: (data['photoURL'] != null && data['photoURL']!.isNotEmpty)
            ? NetworkImage(data['photoURL']!)
            : null,
        backgroundColor: const Color.fromARGB(255, 230, 210, 185),
        child: (data['photoURL'] == null || data['photoURL']!.isEmpty)
            ? const Icon(Icons.person,
                size: 24, color: Color.fromARGB(255, 63, 39, 28))
            : null,
      ),
      title: Text(
        data['displayName'] ?? 'Usuário',
        style: const TextStyle(fontFamily: 'Itim', fontSize: 16),
      ),
      trailing: isHost
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 211, 173, 92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Anfitrião',
                style: TextStyle(
                  fontFamily: 'Itim',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 63, 39, 28),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _refreshEventData() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('events')
          .doc(_eventId)
          .get();
      if (docSnap.exists && mounted) {
        setState(() {
          _loadDataFromWidget(
            docSnap.data() as Map<String, dynamic>,
            docSnap.id,
          );
        });
      }
    } catch (e) {
      print("Erro ao recarregar dados do evento: $e");
    }
  }

  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          existingEvent: widget.event,
        ),
      ),
    ).then((_) {
      _refreshEventData();
    });
  }

  // --- Métodos de Diálogo e BottomSheet ---

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
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showInviteOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 245, 235, 220),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Convidar para o Evento',
                          style: TextStyle(
                            fontFamily: 'Itim',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 63, 39, 28),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Color.fromARGB(255, 63, 39, 28)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildQrCodeSection(),
                        const SizedBox(height: 30),
                        _buildInviteFriendsListSection(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showClaimQuantityDialog(EventItem item) {
    final _quantityController = TextEditingController(text: '1');
    final int maxAvailable = item.quantityAvailable;
    final _formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 245, 235, 220),
          title: Text('Levar "${item.name}"',
              style: const TextStyle(fontFamily: 'Itim')),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Quantos você vai levar? (Disponível: $maxAvailable de ${item.totalQuantity})',
                    style: const TextStyle(fontFamily: 'Itim')),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inválido';
                    }
                    final int? val = int.tryParse(value);
                    if (val == null || val <= 0) {
                      return 'Deve ser > 0';
                    }
                    if (val > maxAvailable) {
                      return 'Máx: $maxAvailable';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(
                      fontFamily: 'Itim',
                      color: Color.fromARGB(255, 63, 39, 28))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  final int quantityToClaim =
                      int.parse(_quantityController.text);
                  if (_currentUser == null) return;

                  Navigator.pop(context); // Fecha o diálogo

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registrando item...')),
                  );

                  await _eventService.claimItemPortion(
                      _eventId, item.name, quantityToClaim, _currentUser!);

                  await _refreshEventData();
                }
              },
              child: const Text('Confirmar',
                  style: TextStyle(fontFamily: 'Itim')),
            ),
          ],
        );
      },
    );
  }

  // --- Métodos Auxiliares de Build (Widgets) ---

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

  Widget _buildQrCodeSection() {
    final String qrData = 'olharole://${_eventId}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Convite via QR Code',
          style: TextStyle(
            fontFamily: 'Itim',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 63, 39, 28),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
              backgroundColor: Colors.white,
              foregroundColor: const Color.fromARGB(255, 63, 39, 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Seu amigo pode escanear este código para entrar no evento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Itim', fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteFriendsListSection() {
  if (_eventData['hostId'] != _currentUser?.uid) {
    return Container();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Convidar Amigos do App',
        style: TextStyle(
          fontFamily: 'Itim',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 63, 39, 28),
        ),
      ),
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot>(
        stream: _friendsService.getFriendsStream(),
        builder: (context, snapshot) {
          // ... (o código de loading, error, e 'friends.isEmpty' é o mesmo) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Text('Erro ao carregar amigos');
          }
          final friends = snapshot.data?.docs ?? [];

          if (friends.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Você não tem amigos adicionados para convidar.',
                  style: TextStyle(fontFamily: 'Itim', fontSize: 16),
                ),
              ),
            );
          }

          return Column(
            children: friends.map((friendDoc) {
              final friendId = friendDoc.id;
              final friendData = friendDoc.data() as Map<String, dynamic>;
              final friendName = friendData['displayName'] ?? 'Amigo';

              // --- LÓGICA DE VALIDAÇÃO ATUALIZADA ---
              final bool isAlreadyInvited = _participants.contains(friendId);

              // Verifica se o amigo está na lista de PENDENTES
              final bool isPending = _pendingInviteFriendIds.contains(friendId);
              // --- FIM DA LÓGICA ATUALIZADA ---

              return ListTile(
                leading: const Icon(Icons.person,
                    color: Color.fromARGB(255, 63, 39, 28)),
                title: Text(friendName,
                    style: const TextStyle(fontFamily: 'Itim')),

                // --- WIDGET TRAILING ATUALIZADO ---
                trailing: isAlreadyInvited
                    ? TextButton(
                        onPressed: null,
                        child: Text(
                          'Já no evento',
                          style: TextStyle(
                              fontFamily: 'Itim',
                              color: Colors.grey.shade600),
                        ),
                      )
                    : isPending // <-- USA A NOVA VARIÁVEL
                        ? TextButton(
                            onPressed: null,
                            child: const Text(
                              'Convidado!',
                              style: TextStyle(
                                  fontFamily: 'Itim',
                                  color: Colors.blue),
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 63, 39, 28),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await _eventService.sendEventInvite(
                                eventId: _eventId,
                                eventData: _eventData,
                                friendId: friendId,
                              );

                              // ATUALIZA A UI LOCAL
                              setState(() {
                                _pendingInviteFriendIds.add(friendId);
                              });
                            },
                            child: const Text('Convidar',
                                style: TextStyle(fontFamily: 'Itim')),
                          ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

  Widget _buildContributorAvatars(List<Contributor> contributors) {
    if (contributors.isEmpty) {
      return const Text(
        'Ninguém se ofereceu para levar este item ainda.',
        style: TextStyle(
            fontFamily: 'Itim', fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    final int maxAvatars = 3;
    final int extraCount = contributors.length - maxAvatars;

    return Row(
      children: [
        ...contributors.take(maxAvatars).map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Tooltip(
              message: '${c.name} (levando ${c.quantityTaken})',
              child: CircleAvatar(
                radius: 16,
                backgroundImage: (c.photoUrl != null && c.photoUrl!.isNotEmpty)
                    ? NetworkImage(c.photoUrl!)
                    : null,
                backgroundColor: const Color.fromARGB(255, 230, 210, 185),
                child: (c.photoUrl == null || c.photoUrl!.isEmpty)
                    ? const Icon(Icons.person,
                        size: 20, color: Color.fromARGB(255, 63, 39, 28))
                    : null,
              ),
            ),
          );
        }),
        if (extraCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              '+$extraCount',
              style: const TextStyle(
                  fontFamily: 'Itim',
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

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

    return Column(
      children: _items.map((item) {
        final int total = item.totalQuantity;
        final int claimed = item.quantityClaimed;
        final int available = item.quantityAvailable;
        final double progress = total > 0 ? (claimed / total) : 0;
        final bool isFullyClaimed = available == 0;

        Contributor? myClaim;
        try {
          myClaim =
              item.contributors.firstWhere((c) => c.uid == _currentUser?.uid);
        } catch (e) {
          myClaim = null;
        }
        final bool iAmAContributor = myClaim != null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                            fontFamily: 'Itim',
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (iAmAContributor)
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.red.shade700),
                        tooltip:
                            'Liberar minha parte (${myClaim!.quantityTaken}x)',
                        onPressed: () async {
                          if (_currentUser == null) return;
                          await _eventService.releaseMyClaim(
                              _eventId, item.name, _currentUser!);
                          _refreshEventData();
                        },
                      )
                    else if (!isFullyClaimed)
                      IconButton(
                        icon: Icon(Icons.add_shopping_cart,
                            color: Colors.green.shade700),
                        tooltip: 'Eu levo!',
                        onPressed: () {
                          _showClaimQuantityDialog(item);
                        },
                      )
                    else
                      Icon(Icons.check_circle, color: Colors.grey.shade400),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade300,
                    color: const Color.fromARGB(255, 211, 173, 92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$claimed / $total Levados',
                  style: const TextStyle(
                      fontFamily: 'Itim',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 63, 39, 28)),
                ),
                const SizedBox(height: 12),
                _buildContributorAvatars(item.contributors),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- O MÉTODO BUILD() PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    final Timestamp? createdAt = _eventData['createdAt'];
    final String formattedCreationDate = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : 'Indefinida';

    return Scaffold(
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
          if (_eventData['hostId'] == _currentUser?.uid)
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Color.fromARGB(255, 63, 39, 28), size: 26),
              onPressed: _navigateToEditScreen,
            ),
          if (_eventData['hostId'] == _currentUser?.uid)
            IconButton(
              icon: const Icon(Icons.share,
                  color: Color.fromARGB(255, 63, 39, 28), size: 28),
              onPressed: _showInviteOptionsBottomSheet,
            ),
          if (_eventData['hostId'] == _currentUser?.uid) // Botão Excluir (com 'if')
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade700, size: 28),
              onPressed: _showDeleteConfirmationDialog,
            ),
        ],
      ),
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
              _buildParticipantsCard(),
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
                      // --- Chamada ao método de construir a lista ---
                      _buildInteractiveItemsList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (!_isHost) // SÓ MOSTRA SE NÃO FOR O ANFITRIÃO
            ElevatedButton(
              onPressed: _showLeaveConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sair do Evento',
                style: TextStyle(fontFamily: 'Itim', fontSize: 18),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}