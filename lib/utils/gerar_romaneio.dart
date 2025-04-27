import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

// Função para converter frações para double
double parseFraction(String value) {
  if (value.contains('/')) {
    final parts = value.split('/');
    if (parts.length == 2) {
      final numerator = double.tryParse(parts[0]) ?? 0;
      final denominator = double.tryParse(parts[1]) ?? 1;
      return numerator / denominator;
    }
  }
  return double.tryParse(value) ?? 0;
}

// Função para formatar número conforme frações específicas
String formatNumber(double value, {String? categoria}) {
  // Se a categoria for "POTES", não convertemos para fração
  if (categoria == "POTES") {
    return value.toStringAsFixed(2).replaceAll('.00', '');
  }

  // Se for exatamente 1.0, retorna '4/4'
  if ((value - 1.0).abs() < 1.0E-6) {
    return '4/4';
  }

  final fractions = {
    0.0: '0',
    0.25: '1/4',
    0.5: '2/4',
    0.75: '3/4',
  };

  const tolerance = 1.0E-6;

  for (var entry in fractions.entries) {
    if ((value - entry.key).abs() < tolerance) {
      return entry.value;
    }
  }

  return value.toStringAsFixed(2).replaceAll('.00', '');
}

Future<void> gerarRomaneioPDF(
  BuildContext context,
  Map<String, dynamic> report,
) async {
  try {
    final pdf = pw.Document();
    final categorias = report['Categorias'] as List;
    final dataSolicitacao = DateTime.now();
    final dataFormatada =
        DateFormat('dd/MM/yyyy HH:mm').format(dataSolicitacao);
    final solicitante = report['Nome do usuario'] ?? "";
    final loja = report['Loja'] ?? "";

    // Lista de widgets que vão compor o PDF
    List<pw.Widget> conteudoRomaneio = [
      pw.Text(
        'Romaneio de Solicitação de Produtos',
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 10),
      pw.Text('Data da solicitação: $dataFormatada',
          style: pw.TextStyle(fontSize: 14)),
      pw.Text('Solicitante: $solicitante', style: pw.TextStyle(fontSize: 14)),
      pw.SizedBox(height: 20),
    ];

    // ============= SEÇÃO 1: Itens Faltantes =============

    // Título centralizado "Itens Faltantes"
    conteudoRomaneio.add(
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            "Itens Faltantes",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          )
        ],
      ),
    );

    conteudoRomaneio.add(pw.SizedBox(height: 15));

    // Percorre cada categoria, gera uma lista de itens faltantes
    for (var categoria in categorias) {
      final catNome = categoria['Categoria'] ?? '';
      final itens = categoria['Itens'] as List;

      // Lista para armazenar somente os itens que estiverem faltando
      List<List<String>> itensFaltantesPorCategoria = [];

      for (var item in itens) {
        final quantidade = parseFraction(item['Quantidade'].toString());
        final qtdMinima = parseFraction(item['Qtd Minima'].toString());
        final tipo = item['Tipo'] ?? "";

        if (quantidade < qtdMinima) {
          itensFaltantesPorCategoria.add([
            item['Item'] ?? '',
            "${formatNumber(quantidade, categoria: catNome)} $tipo",
            "${formatNumber(qtdMinima, categoria: catNome)} $tipo",
            "Faltando",
          ]);
        }
      }

      // Se esta categoria tiver itens faltantes, adiciona ao PDF
      if (itensFaltantesPorCategoria.isNotEmpty) {
        // Nome da categoria
        conteudoRomaneio.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                catNome,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
            ],
          ),
        );

        // Tabela de itens faltantes
        conteudoRomaneio.add(
          pw.Table.fromTextArray(
            headers: ["Item", "Qtd Atual", "Qtd Mínima", "Status"],
            columnWidths: {
              0: const pw.FixedColumnWidth(260),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            data: itensFaltantesPorCategoria,
          ),
        );

        conteudoRomaneio.add(pw.SizedBox(height: 10));
      }
    }

    conteudoRomaneio.add(pw.SizedBox(height: 20));

    // ============= SEÇÃO 2: Todos os Itens =============

    conteudoRomaneio.add(
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
        pw.Text(
          "Todos os itens",
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        )
      ]),
    );

    conteudoRomaneio.add(pw.SizedBox(height: 5));

    // Agora fazemos igual antes, exibindo todos os itens separados por categoria
    for (var categoria in categorias) {
      final catNome = categoria['Categoria'] ?? '';
      final itens = categoria['Itens'] as List;

      if (itens.isNotEmpty) {
        conteudoRomaneio.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(height: 10),
              pw.Text(
                catNome,
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
            ],
          ),
        );

        // Tabela com todos os itens da categoria
        conteudoRomaneio.add(
          pw.Table.fromTextArray(
            headers: ["Item", "Qtd Atual", "Qtd Mínima"],
            data: itens.map((item) {
              final quantidade = parseFraction(item['Quantidade'].toString());
              final qtdMinima = parseFraction(item['Qtd Minima'].toString());
              final tipo = item['Tipo'] ?? "";

              return [
                item['Item'] ?? '',
                "${formatNumber(quantidade, categoria: catNome)} $tipo",
                "${formatNumber(qtdMinima, categoria: catNome)} $tipo",
              ];
            }).toList(),
          ),
        );
        conteudoRomaneio.add(pw.SizedBox(height: 10));
      }
    }

    // ============= Gera e Salva o PDF =============
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return conteudoRomaneio;
        },
      ),
    );

    final dataCompleta = report['Data'] ?? "";
    final partesData = dataCompleta.split('/');
    final diaMes = "${partesData[0]}_${partesData[1]}";

    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/Relatório Semanal $loja $diaMes.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Romaneio salvo em: $filePath"),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            OpenFilex.open(filePath);
          },
        ),
      ),
    );

    // Compartilhar no WhatsApp
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Romaneio de solicitação de produtos',
    );
  } catch (e) {
    ShowSnackBar(context, "Erro ao gerar o romaneio: $e", Colors.red);
  }
}
