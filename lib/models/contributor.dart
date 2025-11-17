// lib/models/contributor.dart

class Contributor {
  final String uid;
  final String name;
  final String? photoUrl;
  final int quantityTaken;

  Contributor({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.quantityTaken,
  });

  // Converte o objeto para um Mapa (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'photoUrl': photoUrl,
      'quantityTaken': quantityTaken,
    };
  }

  // Cria um objeto a partir de um Mapa (lido do Firestore)
  factory Contributor.fromMap(Map<String, dynamic> map) {
    return Contributor(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Usuário',
      photoUrl: map['photoUrl'],
      quantityTaken: map['quantityTaken'] ?? 0,
    );
  }
}