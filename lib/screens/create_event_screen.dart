// create_event_screen.dart (VERSÃO ATUALIZADA)

import 'package:Olha_o_Role/services/event_item.dart';
import 'package:Olha_o_Role/services/event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Controladores
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _peopleCountController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemQuantityController = TextEditingController(text: '1');
  
  // O novo serviço
  final EventService _eventService = EventService();

  // A lista de itens agora usa o novo modelo EventItem
  final List<EventItem> _items = [];
  bool _isLoading = false;

  // Mostra o DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // Adiciona um item à lista local
  void _addItemToList() {
    final String name = _itemNameController.text;
    final int? quantity = int.tryParse(_itemQuantityController.text);

    if (name.isNotEmpty && quantity != null && quantity > 0) {
      setState(() {
        _items.add(EventItem(name: name, quantity: quantity));
        // Limpa os campos
        _itemNameController.clear();
        _itemQuantityController.text = '1';
      });
      FocusScope.of(context).unfocus(); // Fecha o teclado
    }
  }

  // Salva o evento NO FIRESTORE
  Future<void> _saveEvent() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O nome do evento é obrigatório.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Chama o serviço
      await _eventService.createEvent(
        _nameController.text,
        _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        _dateController.text.isEmpty ? null : _dateController.text,
        int.tryParse(_peopleCountController.text),
        _items, // Passa a lista de itens
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Evento criado com sucesso!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta para a lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao criar evento: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _peopleCountController.dispose();
    _itemNameController.dispose();
    _itemQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O seu build() pode continuar quase o mesmo,
    // apenas certifique-se de que a lista de itens
    // está sendo construída a partir da `_items` (List<EventItem>)
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        title: const Text('Criar Novo Evento',
            style: TextStyle(
                color: Color.fromARGB(255, 63, 39, 28),
                fontFamily: 'Itim',
                fontSize: 30)),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Card de Informações Básicas ---
              _buildInfoCard(),
              const SizedBox(height: 20),
              // --- Card de Adicionar Itens ---
              _buildAddItemCard(),
              const SizedBox(height: 20),
              // --- Lista de Itens Adicionados ---
              _buildItemsList(),
              const SizedBox(height: 30),
              // --- Botão Salvar ---
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 63, 39, 28),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Salvar Evento na Nuvem',
                        style: TextStyle(fontFamily: 'Itim', fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (Os widgets auxiliares _buildInfoCard, _buildAddItemCard,
  // e _buildItemsList são os mesmos que você já tinha,
  // apenas certifique-se de que _buildItemsList usa a `_items`
  // e o `setState` para remover um item)
  
  // Exemplo de como o _buildItemsList deve ser:
  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return const Center(child: Text('Nenhum item adicionado.'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text(item.name, style: const TextStyle(fontFamily: 'Itim')),
            subtitle: Text('Quantidade: ${item.quantity}', style: const TextStyle(fontFamily: 'Itim')),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _items.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }

  // (Cole seus widgets _buildInfoCard e _buildAddItemCard aqui
  // ou use estes que são baseados no seu design)
  
  Widget _buildInfoCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome do Evento', labelStyle: TextStyle(fontFamily: 'Itim')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição (Opcional)', labelStyle: TextStyle(fontFamily: 'Itim')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Data do Evento (Opcional)',
                labelStyle: TextStyle(fontFamily: 'Itim'),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _peopleCountController,
              decoration: const InputDecoration(labelText: 'Nº de Pessoas (Opcional)', labelStyle: TextStyle(fontFamily: 'Itim')),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddItemCard() {
     return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adicionar Itens ao Evento', style: TextStyle(fontFamily: 'Itim', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(labelText: 'Nome do Item', labelStyle: TextStyle(fontFamily: 'Itim')),
            ),
            const SizedBox(height: 10),
             TextField(
              controller: _itemQuantityController,
              decoration: const InputDecoration(labelText: 'Quantidade', labelStyle: TextStyle(fontFamily: 'Itim')),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addItemToList,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Item', style: TextStyle(fontFamily: 'Itim')),
            ),
          ],
        ),
      ),
    );
  }
}