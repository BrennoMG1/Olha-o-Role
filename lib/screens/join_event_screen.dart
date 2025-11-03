import 'package:flutter/material.dart';
// (No futuro, você precisará de pacotes como 'qr_code_scanner' aqui)

class JoinEventScreen extends StatefulWidget {
  const JoinEventScreen({super.key});

  @override
  State<JoinEventScreen> createState() => _JoinEventScreenState();
}

class _JoinEventScreenState extends State<JoinEventScreen> {
  final _eventIdController = TextEditingController();

  @override
  void dispose() {
    _eventIdController.dispose();
    super.dispose();
  }

  /// Lógica (placeholder) para entrar com ID
  void _joinWithId() {
    if (_eventIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um ID de evento.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Lógica futura para buscar o evento no Firestore
    print('Buscando evento com ID: ${_eventIdController.text}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buscando evento... (função não implementada)'),
      ),
    );
  }

  /// Lógica (placeholder) para escanear QR Code
  void _scanQrCode() {
    // Lógica futura para abrir a câmera
    print('Abrindo câmera para escanear QR Code...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Câmera de QR Code ainda não implementada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Dados de Exemplo (Mock) para a lista de convites ---
    // No futuro, isso viria de um stream/future do Firestore
    final List<Map<String, String>> invitations = [
      {'eventName': 'Churrasco de Sábado', 'fromUser': 'Renan'},
      {'eventName': 'Aniversário da Maria', 'fromUser': 'Maria Júlia'},
    ];

    return Scaffold(
      // --- 1. Design do AppBar (copiado do event_list_screen) ---
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        title: const Text(
          'Ingressar em um Evento', // Título da nova página
          style: TextStyle(
              color: Color.fromARGB(255, 63, 39, 28),
              fontFamily: 'Itim',
              fontSize: 30),
        ),
      ),

      // --- 2. Design do Body (copiado do event_list_screen) ---
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/background.png"),
              fit: BoxFit.cover,
              opacity: 0.18),
        ),
        padding: const EdgeInsets.all(16.0),
        // SingleChildScrollView evita que o teclado cause overflow
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 3. Funcionalidade 1: Ingressar com ID ---
              _buildJoinByIdCard(),
              const SizedBox(height: 20),

              // --- 4. Funcionalidade 2: Escanear QR Code ---
              _buildQrCodeCard(),
              const SizedBox(height: 30),

              // --- 5. Funcionalidade 3: Convites de Amigos ---
              _buildInvitationsSection(invitations),
            ],
          ),
        ),
      ),
    );
  }

  /// Card para a Funcionalidade 1: Ingressar com ID
  Widget _buildJoinByIdCard() {
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

  /// Card para a Funcionalidade 2: Escanear QR Code
  Widget _buildQrCodeCard() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: const Color.fromARGB(255, 245, 235, 220),
      child: ListTile(
        // Usamos um ListTile para esta ação mais simples
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

  /// Seção para a Funcionalidade 3: Convites de Amigos
  Widget _buildInvitationsSection(List<Map<String, String>> invitations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Convites de Amigos',
            style: TextStyle(
              fontFamily: 'Itim',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 63, 39, 28),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Caso 1: Não há convites
        if (invitations.isEmpty)
          Card(
            color: const Color.fromARGB(255, 245, 235, 220),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'Você não tem nenhum convite pendente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Itim',
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ),

        // Caso 2: Lista de convites
        // (Usamos ListView.builder, que é melhor para listas)
        if (invitations.isNotEmpty)
          ListView.builder(
            // shrinkWrap e physics são necessários para um ListView dentro
            // de um SingleChildScrollView
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invite = invitations[index];
              // Reutilizamos o estilo de card de evento
              return _buildInvitationCard(invite);
            },
          ),
      ],
    );
  }

  /// Widget (copiado de event_list_screen) para mostrar um convite
  Widget _buildInvitationCard(Map<String, String> invite) {
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
            Icons.mail_outline, // Ícone de convite
            color: Color.fromARGB(255, 63, 39, 28),
            size: 30,
          ),
        ),
        title: Text(
          invite['eventName']!,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 63, 39, 28),
            fontFamily: 'Itim',
          ),
        ),
        subtitle: Text(
          'De: ${invite['fromUser']}',
          style: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Itim',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Convite aceito! (não implementado)')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Convite recusado! (não implementado)')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}