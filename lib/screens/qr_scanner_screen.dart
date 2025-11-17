import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanDone = false; // Para evitar múltiplos scans

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // Evita que o scanner envie múltiplos resultados
    if (_isScanDone) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _isScanDone = true;
      final String scannedValue = barcodes.first.rawValue!;
      // Retorna o valor escaneado para a tela anterior
      Navigator.pop(context, scannedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR Code',
            style: TextStyle(fontFamily: 'Itim')),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // O widget da câmera
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // Um "overlay" visual para guiar o usuário
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}