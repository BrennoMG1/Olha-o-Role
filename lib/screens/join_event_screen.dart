// lib/join_event_screen.dart (VERSÃO ATUALIZADA)

import 'package:Olha_o_Role/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JoinEventScreen extends StatefulWidget {
  const JoinEventScreen({super.key});

  @override
  State<JoinEventScreen> createState() => _JoinEventScreenState();
}

class _JoinEventScreenState extends State<JoinEventScreen> {
  final _eventIdController = TextEditingController();
  final EventService _eventService = EventService(); // 1. Adiciona o serviço

  @override
  void dispose() {
    _eventIdController.dispose();
    super.dispose();
  }

  void _joinWithId() {
    // ... (sua lógica de ingressar com ID) ...
  }

  void _scanQrCode() {
    // ... (sua lógica de QR code) ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        title: const Text(
          'Ingressar em um Evento',
          style: TextStyle(
              color: Color.fromARGB(255, 63, 39, 28),
              fontFamily: 'Itim',
              fontSize: 30),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildJoinByIdCard(),
              const SizedBox(height: 20),
              _buildQrCodeCard(),
              const SizedBox(height: 30),
              
              // 2. Substitui a seção de convites
              _buildInvitationsSection(), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinByIdCard() {
    // ... (este widget não muda) ...
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
              'Ingressar com ID do Evento',
              style: TextStyle(
                fontFamily: 'Itim',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 63, 39, 28),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eventIdController,
              decoration: const InputDecoration(
                labelText: 'Cole o ID do evento aqui',
                labelStyle: TextStyle(fontFamily: 'Itim'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _joinWithId,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 63, 39, 28), // Cor de botão principal
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Entrar no Evento',
                style: TextStyle(fontFamily: 'Itim', fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeCard() {
    // ... (este widget não muda) ...
     return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: const Color.fromARGB(255, 245, 235, 220),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        leading: const Icon(
          Icons.qr_code_scanner,
          size: 40,
          color: Color.fromARGB(255, 63, 39, 28),
        ),
        title: const Text(
          'Escanear QR Code',
          style: TextStyle(
            fontFamily: 'Itim',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 63, 39, 28),
          ),
        ),
        subtitle: const Text(
          'Aponte a câmera para o convite',
          style: TextStyle(fontFamily: 'Itim'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _scanQrCode,
      ),
    );
  }

  // --- 3. SEÇÃO DE CONVITES ATUALIZADA (NÃO USA MAIS MOCK DATA) ---
  Widget _buildInvitationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Convites de Eventos', // Título atualizado
            style: TextStyle(
              fontFamily: 'Itim',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 63, 39, 28),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // --- StreamBuilder para convites de EVENTO ---
        StreamBuilder<QuerySnapshot>(
          stream: _eventService.getEventInvitesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Erro ao carregar convites de evento');
            }
            final invites = snapshot.data?.docs ?? [];

            if (invites.isEmpty)
              return Card(
                color: const Color.fromARGB(255, 245, 235, 220),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'Você não tem nenhum convite de evento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Itim',
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              );

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invites.length,
              itemBuilder: (context, index) {
                final invite = invites[index];
                return _buildInvitationCard(invite);
              },
            );
          },
        ),
      ],
    );
  }

  // --- 4. CARD DE CONVITE ATUALIZADO ---
  Widget _buildInvitationCard(QueryDocumentSnapshot invite) {
    final data = invite.data() as Map<String, dynamic>;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
            Icons.mail_outline,
            color: Color.fromARGB(255, 63, 39, 28),
            size: 30,
          ),
        ),
        title: Text(
          data['eventName'] ?? 'Evento sem nome',
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
            Text(
              'De: ${data['hostName'] ?? 'Anfitrião'}',
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Itim',
              ),
            ),
            Text(
              'Data: ${data['eventDate'] ?? 'Não definida'}',
              style: const TextStyle(
                color: Colors.black54,
                fontFamily: 'Itim',
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              onPressed: () {
                _eventService.acceptEventInvite(invite);
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              onPressed: () {
                _eventService.declineEventInvite(invite.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}