import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Função que cria a planilha Excel completa em uma única aba
Future<String> gerarExcel(Map<String, dynamic> report) async {
  // Cria uma instância do Excel
  final excel = Excel.createExcel();

  // Nome da aba
  final sheetName = "${report['Loja']}";
  final sheetObject = excel[sheetName];

  // Insere cabeçalho principal
  sheetObject.appendRow([
    TextCellValue("Categoria"),
    TextCellValue("Item"),
    TextCellValue("Quantidade"),
    TextCellValue("Qtd Minima"),
    TextCellValue("Tipo"),
    TextCellValue("Loja"),
    TextCellValue("Data"),
    TextCellValue("Responsável"),
  ]);

  final loja = report['Loja'] ?? "";
  final data = report['Data'] ?? "";
  final responsavel = report['Nome do usuario'] ?? "";

  // Pega a lista de categorias
  final categorias = report['Categorias'] as List;

  // Adiciona dados de cada categoria na planilha
  for (var cat in categorias) {
    final nomeCategoria = cat['Categoria'] ?? "Sem nome";

    // Itera pelos itens da categoria
    final itens = cat['Itens'] as List;
    for (var item in itens) {
      sheetObject.appendRow([
        TextCellValue(nomeCategoria),
        TextCellValue(item['Item'] ?? ""),
        TextCellValue(item['Quantidade'] ?? ""),
        TextCellValue(item['Qtd Minima'] ?? ""),
        TextCellValue(item['Tipo'] ?? ""),
        TextCellValue(loja),
        TextCellValue(data),
        TextCellValue(responsavel),
      ]);
    }
  }
  excel.delete("Sheet1");
  // Converte o Excel em bytes
  final fileBytes = excel.save();

  // Salva o arquivo no diretório de documentos do dispositivo
  final dir = await getApplicationDocumentsDirectory();

  // Extrai apenas dia e mês da data
  final dataCompleta =
      report['Data'] ?? "01/01/2000"; // Data padrão caso não exista
  final partesData = dataCompleta.split('/'); // Divide a data em partes
  final diaMes = "${partesData[0]}_${partesData[1]}"; // Pega dia e mês

  final path = "${dir.path}/relatorio_${loja}_${diaMes}.xlsx";
  final excelFile = File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes!);

  return path;
}

/// Abre o arquivo Excel usando o aplicativo padrão do sistema
Future<void> abrirExcel(String caminhoArquivo) async {
  try {
    await OpenFilex.open(caminhoArquivo);
  } catch (e) {
    print("Erro ao abrir o arquivo: $e");
  }
}

/// Compartilha o arquivo Excel usando o Share Plus
Future<void> compartilharExcel(String caminhoArquivo) async {
  try {
    await Share.shareXFiles(
      [XFile(caminhoArquivo)],
      text: 'Segue em anexo o relatório de estoque.',
    );
  } catch (e) {
    print("Erro ao compartilhar o arquivo: $e");
  }
}
