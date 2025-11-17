// lib/friends_screen.dart

import 'package:Olha_o_Role/services/friends_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendsService _friendsService = FriendsService();
  final _friendCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  /// Lógica para enviar o convite
  void _sendInvite() async {
    if (_friendCodeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final message =
        await _friendsService.sendFriendInvite(_friendCodeController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              message.startsWith('Erro') ? Colors.red : Colors.green,
        ),
      );
      if (!message.startsWith('Erro')) {
        _friendCodeController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 1. Design do AppBar (copiado) ---
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        title: const Text(
          'Amigos', // Título da nova página
          style: TextStyle(
              color: Color.fromARGB(255, 63, 39, 28),
              fontFamily: 'Itim',
              fontSize: 30),
        ),
      ),
      // --- 2. Design do Body (copiado) ---
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 3. Seção 1: Adicionar Amigo ---
              _buildAddFriendCard(),
              const SizedBox(height: 30),

              // --- 4. Seção 2: Convites Pendentes ---
              _buildInvitationsSection(),
              const SizedBox(height: 30),

              // --- 5. Seção 3: Lista de Amigos ---
              _buildFriendsListSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Card para a Funcionalidade 1: Adicionar Amigo
  Widget _buildAddFriendCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: const Color.fromARGB(255, 245, 235, 220), // Cor de card sutil
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Adicionar Amigo',
              style: TextStyle(
                fontFamily: 'Itim',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 63, 39, 28),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _friendCodeController,
              decoration: const InputDecoration(
                labelText: 'Insira o ID de Amigo',
                labelStyle: TextStyle(fontFamily: 'Itim'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 63, 39, 28), // Cor de botão principal
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Enviar Convite',
                      style: TextStyle(fontFamily: 'Itim', fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Seção para a Funcionalidade 2: Convites Pendentes
  Widget _buildInvitationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Convites Pendentes',
            style: TextStyle(
              fontFamily: 'Itim',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 63, 39, 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _friendsService.getFriendInvitesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Erro ao carregar convites');
            }
            final invites = snapshot.data?.docs ?? [];

            if (invites.isEmpty) {
              return Card(
                color: const Color.fromARGB(255, 245, 235, 220),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'Nenhum convite pendente.',
                      style: TextStyle(fontFamily: 'Itim', fontSize: 18),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invites.length,
              itemBuilder: (context, index) {
                final invite = invites[index];
                final data = invite.data() as Map<String, dynamic>;
                return _buildInvitationCard(invite.id, data);
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showRemoveConfirmationDialog(
      String friendId, String friendName) async { // <-- 1. Parâmetros friendId e friendName
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover Amigo', style: TextStyle(fontFamily: 'Itim')),
          // 2. Use friendName aqui
          content: Text(
              'Você tem certeza que deseja remover $friendName de seus amigos?',
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
                  const Text('Remover', style: TextStyle(fontFamily: 'Itim')),
              onPressed: () async {
                // 3. Use friendId aqui
                final result = await _friendsService.removeFriend(friendId); 
                if (mounted) {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result == "Sucesso"
                          ? '$friendName foi removido.'
                          : 'Falha: $result'),
                      backgroundColor: result == "Sucesso" ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Card para um Convite Pendente
  Widget _buildInvitationCard(String senderId, Map<String, dynamic> data) {
    final String senderName = data['senderName'] ?? 'Usuário';
    final String? senderCode = data['senderFriendCode'];

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.person_add_alt_1,
            size: 40, color: Color.fromARGB(255, 63, 39, 28)),
        title: Text(
          senderName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 63, 39, 28),
            fontFamily: 'Itim',
          ),
        ),
        subtitle: Text(
          'ID: $senderCode',
          style: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Itim',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              onPressed: () {
                _friendsService.acceptFriendInvite(
                    senderId, senderName, senderCode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              onPressed: () {
                _friendsService.declineFriendInvite(senderId);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Seção para a Funcionalidade 3: Lista de Amigos
  Widget _buildFriendsListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Meus Amigos',
            style: TextStyle(
              fontFamily: 'Itim',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 63, 39, 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _friendsService.getFriendsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Erro ao carregar amigos');
            }
            final friends = snapshot.data?.docs ?? [];

            if (friends.isEmpty) {
              return Card(
                color: const Color.fromARGB(255, 245, 235, 220),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'Adicione amigos usando o ID deles.',
                      style: TextStyle(fontFamily: 'Itim', fontSize: 18),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final data = friend.data() as Map<String, dynamic>;
                return _buildFriendCard(friend.id, data);
              },
            );
          },
        ),
      ],
    );
  }

  /// Card para um Amigo
  Widget _buildFriendCard(String friendId, Map<String, dynamic> data) {
    final friendName = data['displayName'] ?? 'Amigo';

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(Icons.person,
            size: 40, color: Color.fromARGB(255, 63, 39, 28)),
        title: Text(
          friendName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 63, 39, 28),
            fontFamily: 'Itim',
          ),
        ),
        subtitle: Text(
          'ID: ${data['friendCode'] ?? '...'}',
          style: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Itim',
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade700),
          // VVVV CORREÇÃO: Chama o diálogo e passa os dados VVVV
          onPressed: () => _showRemoveConfirmationDialog(friendId, friendName),
        ),
      ),
    );
  }
}