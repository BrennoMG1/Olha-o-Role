// lib/join_event_screen.dart (VERSÃO ATUALIZADA)

import 'package:Olha_o_Role/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'qr_scanner_screen.dart'; // <-- 1. NOVO IMPORT

class JoinEventScreen extends StatefulWidget {
  const JoinEventScreen({super.key});

  @override
  State<JoinEventScreen> createState() => _JoinEventScreenState();
}

class _JoinEventScreenState extends State<JoinEventScreen> {
  final _eventIdController = TextEditingController();
  final EventService _eventService = EventService();
  bool _isLoading = false;

  @override
  void dispose() {
    _eventIdController.dispose();
    super.dispose();
  }

  // --- 2. IMPLEMENTA O BOTÃO DE "INGRESSAR COM ID" ---
  void _joinWithId() async {
    if (_eventIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Insira um ID de evento.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final String result =
        await _eventService.joinEventById(_eventIdController.text);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result == "Sucesso") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Você ingressou no evento!'),
              backgroundColor: Colors.green),
        );
        // Fecha a tela de "Ingressar" e a tela de "Detalhes"
        // (Assume que você quer voltar para a lista principal)
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- 3. IMPLEMENTA O BOTÃO DE "ESCANEAR" ---
  void _scanQrCode() async {
    // Navega para a tela de scanner e espera um resultado
    final scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (scannedValue != null && mounted) {
      // O QR Code que geramos é: 'olharole://EVENT_ID'
      // Precisamos extrair apenas o EVENT_ID.
      if (scannedValue != null && mounted) {
      if (scannedValue.startsWith('olharole://')) {
        final String eventId = scannedValue.substring('olharole://'.length);
        
        // 1. Define o ID no controller
        setState(() {
          _eventIdController.text = eventId;
        });
        
        // 2. CHAMA A FUNÇÃO DE INGRESSO
        _joinWithId(); 
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('QR Code inválido.'),
              backgroundColor: Colors.red),
        );
      }
      }
    }
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
              // --- Card de Ingressar com ID (agora funcional) ---
              _buildJoinByIdCard(),
              const SizedBox(height: 20),
              // --- Card de QR Code (agora funcional) ---
              _buildQrCodeCard(),
              const SizedBox(height: 30),
              // --- Seção de Convites (funcional) ---
              _buildInvitationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. ATUALIZA O CARD DE "INGRESSAR COM ID" ---
  Widget _buildJoinByIdCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: const Color.fromARGB(255, 245, 235, 220),
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
              onPressed: _isLoading ? null : _joinWithId, // <-- Chama a função
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 63, 39, 28),
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
                      'Entrar no Evento',
                      style: TextStyle(fontFamily: 'Itim', fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. ATUALIZA O CARD DE "QR CODE" ---
  Widget _buildQrCodeCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
        onTap: _scanQrCode, // <-- Chama a função
      ),
    );
  }

  // --- 6. (O RESTANTE DA SUA TELA) ---
  // (Os métodos _buildInvitationsSection e _buildInvitationCard
  // permanecem os mesmos da nossa última etapa)

  Widget _buildInvitationsSection() {
    // ... (Cole o método _buildInvitationsSection da sua versão anterior)
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

  Widget _buildInvitationCard(QueryDocumentSnapshot invite) {
    // ... (Cole o método _buildInvitationCard da sua versão anterior)
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
              icon:
                  const Icon(Icons.check_circle, color: Colors.green, size: 30),
              onPressed: () {
                _eventService.acceptEventInvite(invite);
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
              onPressed: () async { // <-- 1. "async"
                // 2. Chama e espera o resultado
                bool success =
                    await _eventService.declineEventInvite(invite.id);

                // 3. Mostra o erro se falhar (IMPEDE O TRAVAMENTO)
                if (mounted && !success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Erro ao recusar o convite. Verifique suas permissões.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                // Se for sucesso, o StreamBuilder remove o card.
              },
            ),
          ],
        ),
      ),
    );
  }
}