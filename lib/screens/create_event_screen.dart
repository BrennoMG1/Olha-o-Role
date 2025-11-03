import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_items_screen.dart';
import 'dart:math'; // Adicione este import para gerar ID aleatório



class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _peopleCountController = TextEditingController();
  final _dateController = TextEditingController();

  // Método para gerar ID único do evento
  String _generateEventId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Método para validar os campos
 bool _validateFields() {
    if (_titleController.text.isEmpty) {
      _showErrorDialog('Por favor, insira um título para o evento');
      return false;
    }
    if (_dateController.text.isEmpty) {
      _showErrorDialog('Por favor, insira uma data para o evento');
      return false;
    }
    
    // Valida se a data é válida e não é anterior ao dia atual
    if (!_isValidDate(_dateController.text)) {
      _showErrorDialog('Por favor, insira uma data válida no formato DD/MM/AAAA');
      return false;
    }
    
    if (_isPastDate(_dateController.text)) {
      _showErrorDialog('A data do evento não pode ser anterior ao dia de hoje');
      return false;
    }
    
    return true;
  }

  // Método para validar o formato da data
  bool _isValidDate(String date) {
    if (date.length != 10) return false;
    
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // Validações básicas (você já fez a checagem de data passada em _isPastDate)
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      
      // Validação específica para fevereiro e meses com 30 dias
      if (month == 2) {
        final isLeapYear = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
        if (day > (isLeapYear ? 29 : 28)) return false;
      } else if ([4, 6, 9, 11].contains(month)) {
        if (day > 30) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método para verificar se a data é anterior ao dia atual
  bool _isPastDate(String date) {
    try {
      final parts = date.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final eventDate = DateTime(year, month, day);
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      
      return eventDate.isBefore(todayWithoutTime);
    } catch (e) {
      return true; // Se houver erro na conversão, considera como data inválida
    }
  }

  // Método para obter a data formatada de hoje
  String _getTodayFormatted() {
    final today = DateTime.now();
    final day = today.day.toString().padLeft(2, '0');
    final month = today.month.toString().padLeft(2, '0');
    final year = today.year.toString();
    return '$day/$month/$year';
  }
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 230, 210, 185),
        title: const Text(
          'Atenção',
          style: TextStyle(
            color: Color.fromARGB(255, 63, 39, 28),
            fontFamily: 'Itim',
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color.fromARGB(255, 63, 39, 28),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color.fromARGB(255, 63, 39, 28),
                fontFamily: 'Itim',
              ),
            ),
          ),
        ],
      ),
    );
  }

 Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 211, 173, 92),
              onPrimary: Color.fromARGB(255, 63, 39, 28),
              onSurface: Color.fromARGB(255, 63, 39, 28),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 63, 39, 28),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        _dateController.text = '$day/$month/$year';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Define a data de hoje como placeholder
    _dateController.text = _getTodayFormatted();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _peopleCountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        title: const Text('Crie seu evento',
              style: TextStyle(
                color: Color.fromARGB(255, 63, 39, 28),
                fontFamily: 'Itim',
                fontSize: 30)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo Título
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Título do Evento',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.festival, color: Colors.black54),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Campo Descrição
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Descrição do Evento',
                labelStyle: const TextStyle(color: Colors.black54),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Campo Quantidade de Pessoas (APENAS NÚMEROS)
            TextField(
              controller: _peopleCountController,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Quantidade de Pessoas',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.people_outline, color: Colors.black54),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),
            
            // Campo Data (FORMATO DD/MM/AAAA)
            TextField(
              controller: _dateController,
              style: const TextStyle(color: Colors.black87),
              readOnly: true, // Impede digitação manual
              onTap: _selectDate, // Abre o seletor de data ao tocar
              decoration: InputDecoration(
                labelText: 'Data do Evento',
                labelStyle: const TextStyle(color: Colors.black54),
                hintText: 'DD/MM/AAAA',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.calendar_today, color: Colors.black54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color.fromARGB(255, 211, 173, 92)),
                  onPressed: _selectDate,
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Data mínima: ${_getTodayFormatted()}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            
            // Botão Avançar - ATUALIZADO
            ElevatedButton(
              onPressed: () {
                if (_validateFields()) {
                  // Gera um ID único para o evento
                  final eventId = _generateEventId();
                  
                  // NAVEGA PARA A PRÓXIMA TELA PASSANDO TODOS OS DADOS
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddItemsScreen(
                        eventId: eventId,
                        eventName: _titleController.text,
                        eventDescription: _descriptionController.text, // NOVO
                        eventDate: _dateController.text,               // NOVO
                        peopleCount: int.tryParse(_peopleCountController.text) ?? 0, // NOVO
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 63, 39, 28),
                backgroundColor: Color.fromARGB(255, 211, 173, 92),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Itim',
                ),
                
              ), child: Text( 'Avançar',
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Itim',
              ),
              ),
        ),
        ],
        ),
      ),
    );
  }
}

// Formatador personalizado para data (adiciona barras automaticamente)
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Remove todas as barras para processar
    final digitsOnly = text.replaceAll('/', '');
    
    // Não faz nada se estiver apagando
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    
    // Formata a data
    String formatted = '';
    for (int i = 0; i < digitsOnly.length && i < 8; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digitsOnly[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}