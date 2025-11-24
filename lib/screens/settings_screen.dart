// lib/settings_screen.dart

import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Constantes de estilo (baseadas no seu app)
  static const Color _backgroundColor = Color.fromARGB(255, 230, 210, 185);
  static const Color _appBarColor = Color.fromARGB(255, 211, 173, 92);
  static const Color _textColor = Color.fromARGB(255, 63, 39, 28);

  // 1. Função para exibir o diálogo "Sobre o App"
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Olha o Rolê',
      applicationVersion: '1.0.0', // Versão hardcoded por enquanto
      applicationIcon: const Icon(Icons.event_available, color: _textColor),
      children: [
        const Text(
          'Este aplicativo foi desenvolvido para organizar listas de itens em eventos colaborativos.',
          style: TextStyle(fontFamily: 'Itim'),
        ),
        const Text(
          '\nDesenvolvido por: Chris Arruda, Júlia Toledo, Brenno Magalhães e Jéssica Nascimento',
          style: TextStyle(fontFamily: 'Itim', fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        foregroundColor: _textColor,
        backgroundColor: _appBarColor,
        centerTitle: false,
        title: const Text(
          'Configurações',
          style: TextStyle(
              color: _textColor, fontFamily: 'Itim', fontSize: 30),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/background.png"),
              fit: BoxFit.cover,
              opacity: 0.18),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            // --- Seção 1: Geral ---
            ListTile(
              title: const Text('Geral',
                  style: TextStyle(
                      fontFamily: 'Itim',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor)),
            ),
            const Divider(),

            // --- Seção 2: Sobre o App ---
            ListTile(
              leading: const Icon(Icons.info_outline, color: _textColor),
              title: const Text('Sobre o App',
                  style: TextStyle(fontFamily: 'Itim')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAboutDialog(context),
            ),
            
            // Placeholder (Exemplo futuro)
            ListTile(
              leading: const Icon(Icons.star_rate_outlined, color: _textColor),
              title: const Text('Avalie-nos (Em breve)',
                  style: TextStyle(
                      fontFamily: 'Itim',
                      decoration: TextDecoration.lineThrough)),
            ),
          ],
        ),
      ),
    );
  }
}