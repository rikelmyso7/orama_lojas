import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:orama_lojas/services/stock_moviment.dart';

class StockService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final CollectionReference estoqueCollection =
      FirebaseFirestore.instance.collection('estoque');

  /// Registra uma ENTRADA no estoque para cada [movimento] recebido.
  Future<void> registrarEntrada({
    required String origem,
    required List<StockMovement> movimentos,
  }) async {
    for (final movimento in movimentos) {
      final docRef = estoqueCollection.doc(movimento.itemId);
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final Timestamp agora = Timestamp.now();
        final historyEntry = {
          'tipo': 'entrada',
          'quantidade': movimento.quantidade,
          'origem': origem,
          'data': agora,
        };

        if (!snapshot.exists) {
          // Se o item não existe, cria com a quantidade informada
          final data = {
            'nome': movimento.nome,
            'quantidade': movimento.quantidade,
            'unidade': movimento.unidade,
            'historico': [historyEntry],
          };
          transaction.set(docRef, data);
        } else {
          final currentData = snapshot.data() as Map<String, dynamic>;
          final currentQuantidade =
              (currentData['quantidade'] ?? 0).toDouble();
          final newQuantidade = currentQuantidade + movimento.quantidade;
          
          // Atualiza o item e adiciona o novo registro de histórico
          transaction.update(docRef, {
            'quantidade': newQuantidade,
            'historico': FieldValue.arrayUnion([historyEntry]),
          });
        }
      });
    }
  }

  /// Registra uma SAÍDA no estoque para cada [movimento].
  Future<void> registrarSaida({
    required String destino,
    required List<StockMovement> movimentos,
  }) async {
    for (final movimento in movimentos) {
      final docRef = estoqueCollection.doc(movimento.itemId);
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception("Item ${movimento.itemId} não existe no estoque.");
        }

        final currentData = snapshot.data() as Map<String, dynamic>;
        final currentQuantidade = (currentData['quantidade'] ?? 0).toDouble();

        if (currentQuantidade < movimento.quantidade) {
          throw Exception("Quantidade insuficiente para o item ${movimento.itemId}");
        }
        
        final newQuantidade = currentQuantidade - movimento.quantidade;
        final Timestamp agora = Timestamp.now();
        final historyEntry = {
          'tipo': 'saida',
          'quantidade': movimento.quantidade,
          'destino': destino,
          'data': agora,
        };

        transaction.update(docRef, {
          'quantidade': newQuantidade,
          'historico': FieldValue.arrayUnion([historyEntry]),
        });
      });
    }
  }

  /// Stream que retorna a lista atual do estoque.
  Stream<List<ItemModel>> getEstoqueAtual() {
    return estoqueCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream para obter o histórico de movimentações de um item específico.
  Stream<List<Map<String, dynamic>>> getHistoricoItem(String itemId) {
    final docRef = estoqueCollection.doc(itemId);
    return docRef.snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final historico = data['historico'] as List<dynamic>? ?? [];
      return historico.cast<Map<String, dynamic>>();
    });
  }
}
