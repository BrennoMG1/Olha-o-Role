// lib/models/event_item.dart

import 'package:Olha_o_Role/models/contributor.dart';

class EventItem {
  String name;
  int totalQuantity; // Renomeado de 'quantity'
  List<Contributor> contributors;

  EventItem({
    required this.name,
    required this.totalQuantity,
    this.contributors = const [],
  });

  // --- Helpers para a UI ---

  /// Calcula o total de itens já pegos
  int get quantityClaimed {
    if (contributors.isEmpty) {
      return 0;
    }
    // Soma a 'quantityTaken' de todos os contribuidores
    return contributors.fold(
        0, (sum, contributor) => sum + contributor.quantityTaken);
  }

  /// Calcula quantos itens ainda estão disponíveis
  int get quantityAvailable {
    return totalQuantity - quantityClaimed;
  }

  // --- Fim dos Helpers ---

  // Converte o objeto para um Mapa (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalQuantity': totalQuantity, // Nome atualizado
      // Converte a lista de contribuidores para uma lista de mapas
      'contributors': contributors.map((c) => c.toMap()).toList(),
    };
  }

  // Cria um objeto a partir de um Mapa (lido do Firestore)
  factory EventItem.fromMap(Map<String, dynamic> map) {
    return EventItem(
      name: map['name'] ?? '',
      totalQuantity: map['totalQuantity'] ?? 0, // Nome atualizado
      // Converte a lista de mapas lida do Firestore em lista de Contributor
      contributors: (map['contributors'] as List<dynamic>? ?? [])
          .map((cMap) => Contributor.fromMap(cMap as Map<String, dynamic>)) // <-- CORRIGIDO
          .toList(),
    );
  }
}