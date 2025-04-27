import 'package:cloud_firestore/cloud_firestore.dart';
// Modelo para representar um movimento de estoque (entrada ou saída)
class StockMovement {
  final String itemId; // Id do documento do insumo no estoque
  final String nome;   // Nome do insumo (opcional se já estiver no item)
  final double quantidade;
  final String unidade;

  StockMovement({
    required this.itemId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
  });
}

// Modelo para representar o item de estoque

class ItemModel {
  final String itemId;
  final String nome;
  final double quantidade;
  final String unidade;
  final List<Map<String, dynamic>> historico;

  ItemModel({
    required this.itemId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
    required this.historico,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      itemId: doc.id,
      nome: data['nome'] ?? "",
      quantidade: (data['quantidade'] ?? 0).toDouble(),
      unidade: data['unidade'] ?? "",
      historico: (data['historico'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    );
  }
}
