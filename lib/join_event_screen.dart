import 'package:flutter/material.dart';
import 'event_confirmation_screen.dart'; // Importa a próxima tela

class JoinEventScreen extends StatefulWidget {
  const JoinEventScreen({Key? key}) : super(key: key);

  @override
  State<JoinEventScreen> createState() => _JoinEventScreenState();
}

class _JoinEventScreenState extends State<JoinEventScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _joinEvent(String code) {
    if (code.isNotEmpty) {
      // Simulação: Navega para a tela de confirmação com um código
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventConfirmationScreen(eventCode: code),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o código do evento')),
      );
    }
  }

  void _scanQRCode() {
    // Simulação de escanear QR Code e obter um código
    const String simulatedCode = 'FESTA2024';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulando leitura de QR Code...')),
    );
    // Navega para a tela de confirmação após "escanear"
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventConfirmationScreen(eventCode: simulatedCode),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ingressar em Evento',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent, // Transparente para mostrar o fundo
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true, // Estende o corpo para trás do AppBar
      body: Container(
        // Fundo com Gradiente Roxo (Copiado de init_screen.dart)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9333EA),
              Color(0xFFA855F7),
              Color(0xFF7E22CE),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Insira o Código do Evento',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7E22CE),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Você pode encontrar o código com o criador do evento ou no convite.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  
                  // Campo de Texto para o Código
                  TextField(
                    controller: _codeController,
                    focusNode: _codeFocusNode,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'CÓDIGO',
                      prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF9333EA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9333EA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFA855F7).withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF9333EA), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF7E22CE),
                    ),
                    onSubmitted: _joinEvent,
                  ),
                  
                  const SizedBox(height: 25),
                  
                  // Botão de Ingressar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('INGRESSAR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9333EA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _joinEvent(_codeController.text),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  const Text('OU', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 30),
                  
                  // Botão de Escanear QR Code
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('ESCANEAR QR CODE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF9333EA),
                        side: const BorderSide(color: Color(0xFF9333EA), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _scanQRCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}