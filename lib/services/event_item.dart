// lib/models/event_item.dart

class EventItem {
  String name;
  int quantity;
  String? broughtBy; // UID de quem vai levar
  String? broughtByName; // Nome de quem vai levar

  EventItem({
    required this.name,
    required this.quantity,
    this.broughtBy,
    this.broughtByName,
  });

  // Converte o objeto para um Mapa (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'broughtBy': broughtBy,
      'broughtByName': broughtByName,
    };
  }

  // Cria um objeto a partir de um Mapa (lido do Firestore)
  factory EventItem.fromMap(Map<String, dynamic> map) {
    return EventItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      broughtBy: map['broughtBy'],
      broughtByName: map['broughtByName'],
    );
  }
}