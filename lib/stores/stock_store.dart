import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:orama_lojas/others/insumos.dart';
import 'package:orama_lojas/services/stock_service.dart';
import 'package:uuid/uuid.dart';

part 'stock_store.g.dart';

class StockStore = _StockStore with _$StockStore;

abstract class _StockStore with Store {
  _StockStore() {}

  final StockService stockService = StockService();

  @observable
  bool isLoading = false;

  final box = GetStorage();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

// Relatórios gerais
  ObservableList<Map<String, dynamic>> reports =
      ObservableList<Map<String, dynamic>>();

// Relatórios específicos
  ObservableList<Map<String, dynamic>> specificReports =
      ObservableList<Map<String, dynamic>>();

  @observable
  ObservableMap<String, String> quantityValues =
      ObservableMap<String, String>();
  @observable
  ObservableMap<String, String> minValues = ObservableMap<String, String>();

  @observable
  Map<String, TextEditingController> quantityControllers = {};
  @observable
  Map<String, TextEditingController> minControllers = {};

  void populateFieldsWithReport(Map<String, dynamic> reportData) {
    print("Dados do relatório: $reportData"); // Depuração
    if (reportData['Categorias'] == null) return;

    for (var category in reportData['Categorias']) {
      final categoryName = category['Categoria'];
      for (var item in category['Itens']) {
        final itemName = item['Item'];
        final tipo =
            item['tipo'] ?? 'Indefinido'; // Garante que o tipo seja capturado.

        // Garantia de chave única para BALDES e POTES
        final key = (categoryName == 'BALDES' || categoryName == 'POTES')
            ? '${categoryName}_$itemName'
            : itemName;

        final quantidade = item['Quantidade']?.toString() ?? '';
        final minimo = item['Qtd Minima']?.toString() ?? '';

        // Atualiza os observables
        quantityValues[key] = quantidade;
        minValues[key] = minimo;

        // Inicializa os controladores com os valores do relatório
        quantityControllers[key] ??= TextEditingController(text: quantidade);
        minControllers[key] ??= TextEditingController(text: minimo);

        // Atualiza o texto nos controladores existentes
        quantityControllers[key]!.text = quantidade;
        minControllers[key]!.text = minimo;

        print(
            "Carregado: $key -> quantidade=$quantidade, minimo=$minimo, tipo=$tipo");
      }
    }
  }

  @action
  void initItemValues(String category, String itemName, String minimoPadrao,
      {String? tipo}) {
    final key = (category == 'BALDES' || category == 'POTES')
        ? '${category}_$itemName'
        : itemName;

    if (!minValues.containsKey(key)) minValues[key] = minimoPadrao;
    if (!quantityValues.containsKey(key)) quantityValues[key] = '';

    // Remove "/4" ao inicializar o controlador
    final rawQuantity = quantityValues[key]?.split('/').first ?? '';

    minControllers[key] ??= TextEditingController(text: minValues[key]);
    quantityControllers[key] ??= TextEditingController(text: rawQuantity);

    minControllers[key]!.addListener(() {
      updateMinValue(key, minControllers[key]!.text);
    });
    quantityControllers[key]!.addListener(() {
      updateQuantity(key, quantityControllers[key]!.text);
    });

    print(
        "Inicializado: $key -> tipo=$tipo, minimo=$minimoPadrao, quantidade=$rawQuantity");
  }

  @action
  void updateMinValue(String key, String minValue) {
    minValues[key] = minValue; // Atualiza o valor no mapa
  }

  @action
  void updateQuantity(String key, String quantity) {
    if (_isValidNumber(quantity)) {
      // Verifica se a quantidade já possui "/4"
      if (!quantity.endsWith('/4')) {
        quantity =
            '$quantity/4'; // Adiciona "/4" apenas se não estiver presente
      }
      quantityValues[key] = quantity;
      box.write('quantityValues', quantityValues);
    }
  }

  @action
  void clearFields() {
    minValues.clear();
    quantityControllers.clear();
    minControllers.clear();
    quantityValues.clear();
    box.erase();
    print('Campos limpos');
  }

  bool _isValidNumber(String value) {
    final num? number = num.tryParse(value);
    return number != null && number >= 0;
  }

  Future<void> saveData(
      String nome, String data, String city, String loja, String tipo_relatorio,
      {String? reportId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Erro: Usuário não autenticado.");
      return;
    }

    final userId = user.uid;
    final uuid = reportId ?? Uuid().v4(); // Gera um novo ID se não existir
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Construção das categorias e itens diretamente a partir do mapa `insumos`
    final categorias = insumos.keys.map((categoria) {
      final items = insumos[categoria]!.map((item) {
        final itemName = item['nome'];
        final tipo = item['tipo'] ?? ''; // Tipo diretamente do insumo.
        final key = (categoria == 'BALDES' || categoria == 'POTES')
            ? '${categoria}_$itemName'
            : itemName;

        // Recupera valores de quantidade e mínimo
        var quantidade = quantityValues[key]?.split('/').first ?? '0';
        final minimo = minValues[key] ?? item['minimo'];

        if (quantidade.isEmpty) {
          quantidade = '0';
        }

        // Verifica se a quantidade mínima é uma fração
        final isFraction = minimo.contains('/');

        // Formata a quantidade apenas se a quantidade mínima for uma fração
        final formattedQuantidade = isFraction ? '$quantidade/4' : quantidade;

        return {
          'Item': itemName,
          'Quantidade': formattedQuantidade,
          'Qtd Minima': minimo,
          'Tipo': tipo, // Inclui o campo tipo diretamente.
        };
      }).toList();

      return {'Categoria': categoria, 'Itens': items};
    }).toList();

    // Estrutura completa do relatório
    final report = {
      'ID': uuid,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias,
      'Tipo Relatorio': tipo_relatorio,
    };

    try {
      // Salva o relatório no Firebase
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(uuid)
          .set(report, SetOptions(merge: true));

      // Atualiza o reportId temporário para o real
      if (reportInsumos.containsKey('temp_$uuid')) {
        reportInsumos[uuid] = reportInsumos.remove('temp_$uuid')!;
        print('Relatório temporário atualizado com ID real: $uuid');
      }

      print("Dados salvos com sucesso: $report");
      clearFields();
    } catch (e) {
      print("Erro ao salvar dados: $e");
      box.write('unsavedData', report); // Salva localmente como fallback.
    }
  }

  @action
  Future<void> fetchReports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    reports.clear(); // Limpa apenas os relatórios gerais

    isLoading = true;

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        reports.add(data);
      }

      print("Relatórios carregados: ${reports.length}");
    } catch (e) {
      print("Erro ao buscar relatórios: $e");
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> fetchReportsEspecifico() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    // Evita múltiplas chamadas simultâneas
    if (isLoading) return;

    isLoading = true; // Inicia o estado de carregamento
    specificReports
        .clear(); // Limpa os relatórios específicos antes de carregar

    try {
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio_especifico')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Adiciona o ID do documento
        specificReports.add(data); // Adiciona ao array de relatórios
      }

      print("Relatórios específicos carregados: ${specificReports.length}");
    } catch (e) {
      print("Erro ao buscar relatórios específicos: $e");
    } finally {
      isLoading = false; // Finaliza o estado de carregamento
    }
  }

  Map<String, List<Map<String, dynamic>>> getItemsForReport(String reportId) {
    // Recupera itens dinâmicos
    final dynamicItems = reportInsumos[reportId] ?? {};

    // Cria uma cópia do modelo base para evitar alterações diretas
    final mergedItems = Map<String, List<Map<String, dynamic>>>.fromEntries(
      insumos.entries
          .map((entry) => MapEntry(entry.key, List.from(entry.value))),
    );

    // Mescla os itens dinâmicos com os itens base
    dynamicItems.forEach((category, items) {
      if (mergedItems.containsKey(category)) {
        mergedItems[category]!.addAll(items);
      } else {
        mergedItems[category] = items;
      }
    });

    return mergedItems;
  }

  @action
  void removeItemFromReport({
    required String reportId,
    required String category,
    required String name,
  }) {
    // Verifica se existem itens dinâmicos para o relatório e categoria
    if (reportInsumos[reportId] != null &&
        reportInsumos[reportId]![category] != null) {
      // Remove o item pelo nome
      reportInsumos[reportId]![category]!
          .removeWhere((item) => item['nome'] == name);

      // Remove a categoria se não houver mais itens
      if (reportInsumos[reportId]![category]!.isEmpty) {
        reportInsumos[reportId]!.remove(category);
      }

      // Remove o relatório se não houver mais categorias
      if (reportInsumos[reportId]!.isEmpty) {
        reportInsumos.remove(reportId);
      }

      print(
          'Item "$name" removido da categoria "$category" no relatório "$reportId".');
    } else {
      print('Nenhum item encontrado para remover.');
    }
  }

  ObservableMap<String, Map<String, List<Map<String, dynamic>>>> reportInsumos =
      ObservableMap.of({});

  // Adicionar novo item ao relatório específico
  void addItemToReport({
    required String? reportId,
    required String category,
    required String name,
    required String min,
    required String quantity,
    required String type,
  }) {
    // Gera um ID temporário se o reportId for nulo
    final currentReportId =
        reportId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final newItem = {
      'nome': name,
      'minimo': min,
      'quantidade': quantity,
      'tipo': type,
    };

    // Garante que o mapa para este relatório existe
    reportInsumos.putIfAbsent(currentReportId, () => {});

    // Garante que a lista da categoria é mutável
    if (reportInsumos[currentReportId]!.containsKey(category)) {
      reportInsumos[currentReportId]![category] =
          List<Map<String, dynamic>>.from(
              reportInsumos[currentReportId]![category]!);
    } else {
      reportInsumos[currentReportId]![category] = [];
    }

    // Adiciona o novo item
    reportInsumos[currentReportId]![category]!.add(newItem);

    // Atualiza os controladores
    final key = (category == 'BALDES' || category == 'POTES')
        ? '${category}_$name'
        : name;

    minControllers[key] ??= TextEditingController(text: min);
    quantityControllers[key] ??= TextEditingController(text: quantity);

    print(
        'Item adicionado: $newItem à categoria $category no relatório $currentReportId');
  }

  Future<void> updateReport(String nome, String data, String city, String loja,
      String tipo_relatorio, String? reportId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    final userId = user.uid;
    final DateTime now = DateTime.now().toUtc().add(Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    // Combinar itens base com itens dinâmicos
    final categorias = insumos.keys.map((categoria) {
      final baseItems = List<Map<String, dynamic>>.from(insumos[categoria]!);
      final dynamicItems = reportInsumos[reportId]?[categoria] ?? [];

      // Mesclar os itens base com os itens adicionados dinamicamente
      final allItems = [
        ...baseItems,
        ...dynamicItems,
      ];

      return {
        'Categoria': categoria,
        'Itens': allItems.map((item) {
          final itemName = item['nome'];
          final tipo = item['tipo'] ?? '';
          final key = (categoria == 'BALDES' || categoria == 'POTES')
              ? '${categoria}_$itemName'
              : itemName;

          // Recupera valores dos controladores
          var quantidade = quantityValues[key]?.split('/').first ?? '0';
          final minimo = minValues[key] ?? item['minimo'];

          if (quantidade.isEmpty) {
            quantidade = '0';
          }

          // Verifica se a quantidade mínima é uma fração
          final isFraction = minimo.contains('/');

          // Formata a quantidade apenas se a quantidade mínima for uma fração
          final formattedQuantidade = isFraction ? '$quantidade/4' : quantidade;

          return {
            'Item': itemName,
            'Quantidade': formattedQuantidade,
            'Qtd Minima': minimo,
            'Tipo': tipo,
          };
        }).toList(),
      };
    }).toList();

    // Estrutura do relatório atualizado
    final updatedData = {
      'ID': reportId,
      'Nome do usuario': nome,
      'Data': formattedDate,
      'Cidade': city,
      'Loja': loja,
      'Categorias': categorias,
      'Tipo Relatorio': tipo_relatorio,
    };

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(reportId)
          .set(updatedData, SetOptions(merge: true));

      print("Relatório atualizado com sucesso: $updatedData");
    } catch (e) {
      print("Erro ao atualizar relatório: $e");
    }
  }

  // Função auxiliar para determinar a categoria com base no nome do item
  String getCategoryFromItem(String itemName) {
    if (insumos['SORVETES']!.contains(itemName)) {
      return 'SORVETES';
    } else if (insumos['INSUMOS']!.contains(itemName)) {
      return 'INSUMOS';
    } else if (insumos['TAPIOCA']!.contains(itemName)) {
      return 'TAPIOCA';
    } else if (insumos['DESCARTÁVEIS']!.contains(itemName)) {
      return 'DESCARTÁVEIS';
    } else {
      return 'OUTROS';
    }
  }

  // Função para excluir um relatório específico
  Future<void> deleteReport(String reportId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("Usuário não autenticado.");
      return;
    }

    final userId = user.uid;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio')
          .doc(reportId)
          .delete();

      reports.removeWhere((report) => report['id'] == reportId);

      print("Relatório excluído com sucesso.");
    } catch (e) {
      print("Erro ao excluir relatório: $e");
    }
  }

  String formatReportForWhatsApp(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    buffer.writeln("*Relatório do que FALTA NA LOJA*");
    buffer.writeln("Loja: *${report['Loja']}*");
    buffer.writeln("Cidade: *${report['Cidade']}*");
    buffer.writeln("Data: ${report['Data']}");
    buffer.writeln("Responsável: *${report['Nome do usuario']}*\n");

    for (final category in report['Categorias']) {
      buffer.writeln("> ${category['Categoria']}:");
      for (final item in category['Itens']) {
        final itemName = item['Item'];
        final tipo = item['Tipo'] ?? "";
        final min = item['Qtd Minima'] != null
            ? "Mínimo: *_${item['Qtd Minima']} ${tipo}_*"
            : "";
        final quantidade = item['Quantidade'] != null
            ? "Quantidade Atual: *_${item['Quantidade']} ${tipo}_*\n"
            : "";
        buffer.writeln("  • *$itemName*\n  - $quantidade ".trim());
        buffer.writeln();
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String formatRelatorioForWhatsApp(Map<String, dynamic> report) {
    final buffer = StringBuffer();

    buffer.writeln("*Relatório de Estoque*");
    buffer.writeln("Loja: *${report['Loja']}*");
    buffer.writeln("Cidade: *${report['Cidade']}*");
    buffer.writeln("Data: ${report['Data']}");
    buffer.writeln("Responsável: *${report['Nome do usuario']}*\n");

    for (final category in report['Categorias']) {
      buffer.writeln("> ${category['Categoria']}:");
      for (final item in category['Itens']) {
        final itemName = item['Item'];
        final tipo = item['Tipo'] ?? "";
        final min = item['Qtd Minima'] != null
            ? "Mínimo: *_${item['Qtd Minima']} ${tipo}_*"
            : "";
        final quantidade = item['Quantidade'] != null
            ? "Quantidade Atual: *_${item['Quantidade']} ${tipo}_*\n"
            : "";
        buffer.writeln("  • *$itemName*\n  - $quantidade ".trim());
        buffer.writeln();
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
