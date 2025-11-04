// create_event_screen.dart (VERSÃO ATUALIZADA 2-em-1)

import 'package:Olha_o_Role/services/event_item.dart';
import 'package:Olha_o_Role/services/event_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. NOVO IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateEventScreen extends StatefulWidget {
  // --- 2. ACEITA UM EVENTO OPCIONAL ---
  final QueryDocumentSnapshot? existingEvent;

  const CreateEventScreen({super.key, this.existingEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  // Controladores (mesmos de antes)
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _peopleCountController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemQuantityController = TextEditingController(text: '1');

  final EventService _eventService = EventService();

  // Lista de itens (mesma de antes)
  final List<EventItem> _items = [];
  bool _isLoading = false;

  // --- 3. VARIÁVEIS PARA O MODO DE EDIÇÃO ---
  bool _isEditMode = false;
  String? _editingEventId;

  @override
  void initState() {
    super.initState();

    // --- 4. LÓGICA DE PREENCHIMENTO (se for modo de edição) ---
    if (widget.existingEvent != null) {
      setState(() {
        _isEditMode = true;
        _editingEventId = widget.existingEvent!.id;

        // Carrega os dados do evento nos controladores
        final data = widget.existingEvent!.data() as Map<String, dynamic>;

        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _dateController.text = data['eventDate'] ?? '';
        _peopleCountController.text = data['peopleCount']?.toString() ?? '';

        // Carrega a lista de itens
        final List<dynamic> itemMaps = data['items'] ?? [];
        _items.addAll(itemMaps.map((map) => EventItem.fromMap(map)));
      });
    }
  }

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

  // Método para adicionar item (o que corrige o seu botão)
  void _addItemToList() {
    final String name = _itemNameController.text;
    final int? quantity = int.tryParse(_itemQuantityController.text);

    if (name.isNotEmpty && quantity != null && quantity > 0) {
      setState(() {
        _items.add(EventItem(
          name: name,
          totalQuantity: quantity, // Usando o nome de campo correto
          contributors: [],
        ));
        // Limpa os campos
        _itemNameController.clear();
        _itemQuantityController.text = '1';
      });
      FocusScope.of(context).unfocus(); // Fecha o teclado
    }
  }

  // --- 5. LÓGICA DE SALVAR ATUALIZADA ---
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
      final String name = _nameController.text;
      final String? description = _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text;
      final String? eventDate =
          _dateController.text.isEmpty ? null : _dateController.text;
      final int? peopleCount = int.tryParse(_peopleCountController.text);

      if (_isEditMode) {
        // --- MODO DE EDIÇÃO ---
        await _eventService.updateEvent(
          _editingEventId!, // ID do evento que estamos editando
          name,
          description,
          eventDate,
          peopleCount,
          _items,
        );
      } else {
        // --- MODO DE CRIAÇÃO (como antes) ---
        await _eventService.createEvent(
          name,
          description,
          eventDate,
          peopleCount,
          _items,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _isEditMode ? 'Evento atualizado!' : 'Evento criado!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volta para a tela anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar: $e'),
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 210, 185),
      appBar: AppBar(
        foregroundColor: const Color.fromARGB(255, 63, 39, 28),
        backgroundColor: const Color.fromARGB(255, 211, 173, 92),
        centerTitle: false,
        // --- 6. TÍTULO DINÂMICO ---
        title: Text(
          _isEditMode ? 'Editar Evento' : 'Criar Novo Evento',
          style: const TextStyle(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildAddItemCard(),
              const SizedBox(height: 20),
              _buildItemsList(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 63, 39, 28),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    // --- 7. TEXTO DO BOTÃO DINÂMICO ---
                    : Text(
                        _isEditMode ? 'Salvar Alterações' : 'Salvar Evento',
                        style:
                            const TextStyle(fontFamily: 'Itim', fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- O RESTO DOS SEUS WIDGETS (_buildInfoCard, _buildAddItemCard,
  // _buildItemsList) SÃO EXATAMENTE OS MESMOS DE ANTES ---

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
            subtitle: Text('Quantidade: ${item.totalQuantity}',
                style: const TextStyle(fontFamily: 'Itim')),
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

  Widget _buildInfoCard() {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Nome do Evento',
                  labelStyle: TextStyle(fontFamily: 'Itim')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  labelStyle: TextStyle(fontFamily: 'Itim')),
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
              decoration: const InputDecoration(
                  labelText: 'Nº de Pessoas (Opcional)',
                  labelStyle: TextStyle(fontFamily: 'Itim')),
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
            const Text('Adicionar Itens ao Evento',
                style: TextStyle(
                    fontFamily: 'Itim',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                  labelText: 'Nome do Item',
                  labelStyle: TextStyle(fontFamily: 'Itim')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _itemQuantityController,
              decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  labelStyle: TextStyle(fontFamily: 'Itim')),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addItemToList,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Item',
                  style: TextStyle(fontFamily: 'Itim')),
            ),
          ],
        ),
      ),
    );
  }
}