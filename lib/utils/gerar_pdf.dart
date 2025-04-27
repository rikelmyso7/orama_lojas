import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

Future<void> generateAndOpenPDF(
    BuildContext context, Map<String, dynamic> report) async {
  try {
    final pdf = pw.Document();
    final categorias = report['Categorias'] as List;

    // Criando o conteúdo do PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: categorias.map((categoria) {
              final itens = categoria['Itens'] as List;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    categoria['Categoria'],
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Table.fromTextArray(
                    headers: ["Item", "Qtd Minima", "Quantidade", "Tipo"],
                    data: itens.map((item) {
                      return [
                        item['Item'],
                        item['Qtd Minima'],
                        item['Quantidade'],
                        item['Tipo']
                      ];
                    }).toList(),
                  ),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),
          );
        },
      ),
    );

    // Salvando o PDF no dispositivo
    final output = await getApplicationDocumentsDirectory();
    final filePath = "${output.path}/comanda_${report['ID']}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Mostrando mensagem com o caminho do arquivo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Arquivo salvo em: $filePath"),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            OpenFilex.open(filePath);
          },
        ),
      ),
    );

    // Abrindo o arquivo automaticamente
    await OpenFilex.open(filePath);
  } catch (e) {
    // Tratamento de erro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erro ao gerar o arquivo: $e")),
    );
  }
}
