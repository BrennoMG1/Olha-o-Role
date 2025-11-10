import 'package:flutter/material.dart';

// Dados simulados do evento
class EventDetail {
  final String title;
  final String date;
  final String location;
  final String host;
  final int participants;

  EventDetail({
    required this.title,
    required this.date,
    required this.location,
    required this.host,
    required this.participants,
  });
}

class EventConfirmationScreen extends StatelessWidget {
  final String eventCode;
  
  // Detalhes do evento simulados para demonstração
  final EventDetail simulatedEvent = EventDetail(
    title: 'Super Festa Tecnológica Anual',
    date: '28 de Outubro de 2025 - 20:00h',
    location: 'Rua da Inovação, 123 - Centro de Convenções',
    host: 'Tech Events S/A',
    participants: 150,
  );

  EventConfirmationScreen({Key? key, required this.eventCode}) : super(key: key);

  void _confirmJoin(BuildContext context) {
    // Lógica para ingressar de fato no evento (API call, etc.)
    
    // Simulação: Volta para a tela inicial e mostra uma mensagem de sucesso
    Navigator.of(context).popUntil((route) => route.isFirst); // Volta para a raiz (TelaInicial)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Você ingressou no evento "${simulatedEvent.title}" com o código $eventCode!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmar Evento',
          style: TextStyle(
            color: Color(0xFF7E22CE),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF7E22CE)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Título de Confirmação
              const Text(
                'Confirme sua presença',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9333EA),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Você está prestes a ingressar neste evento. Verifique os detalhes:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // Card de Detalhes do Evento
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        simulatedEvent.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7E22CE),
                        ),
                      ),
                      const Divider(height: 25),
                      _buildDetailRow(
                          icon: Icons.calendar_today,
                          label: 'Data e Hora',
                          value: simulatedEvent.date),
                      _buildDetailRow(
                          icon: Icons.location_on,
                          label: 'Local',
                          value: simulatedEvent.location),
                      _buildDetailRow(
                          icon: Icons.person,
                          label: 'Organizador',
                          value: simulatedEvent.host),
                      _buildDetailRow(
                          icon: Icons.people,
                          label: 'Participantes',
                          value: '${simulatedEvent.participants} Confirmados'),
                      _buildDetailRow(
                          icon: Icons.vpn_key_sharp,
                          label: 'Seu Código',
                          value: eventCode,
                          isCode: true),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Botão de Confirmação
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('CONFIRMAR INGRESSO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _confirmJoin(context),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botão de Cancelar
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Volta para a tela de inserir código
                },
                child: const Text(
                  'Cancelar e Voltar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF7E22CE), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCode ? FontWeight.w900 : FontWeight.w500,
                    color: isCode ? const Color(0xFF9333EA) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}