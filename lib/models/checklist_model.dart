class Checklist {
  final String id; // "abertura" ou "fechamento"
  final String titulo;
  final String? periodo;
  final List<String> itens;

  Checklist({
    required this.id,
    required this.titulo,
    required this.itens,
    this.periodo,
  });

  factory Checklist.fromJson(String id, Map<String, dynamic> json) {
    return Checklist(
      id: id,
      titulo: json['titulo'] ?? '',
      itens: List<String>.from(json['itens'] ?? const []),
      periodo: json['periodo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'periodo': periodo,
      'itens': itens,
    };
  }
}
