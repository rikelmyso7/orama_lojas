import 'package:flutter/material.dart';
import 'package:orama_lojas/utils/gerar_excel.dart';
import 'package:orama_lojas/utils/gerar_romaneio.dart';
import 'package:orama_lojas/utils/show_snackbar.dart'; // Ajuste o import conforme seu projeto

class DataViewPage extends StatelessWidget {
  final Map<String, dynamic> report;

  DataViewPage({required this.report});

  @override
  Widget build(BuildContext context) {
    final categorias = report['Categorias'] as List;

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Vizualizar",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xff60C03D),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () async {
                    try {
                      final caminho = await gerarRomaneioPDF(context, report);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erro ao compartilhar: $e")),
                      );
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: categorias.length * 2, // Conta os Dividers entre os itens
        itemBuilder: (context, index) {
          if (index.isOdd) {
            // Insere um Divider entre os ExpansionTiles
            return Divider(
              thickness: 1,
              height: 1,
            );
          }

          final actualIndex = index ~/ 2;
          final categoria = categorias[actualIndex];
          final itens = categoria['Itens'] as List;

          itens.sort((a, b) => (a['Item'] ?? '').compareTo(b['Item'] ?? ''));

          return ExpansionTile(
            title: Text(categoria['Categoria']),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Item")),
                    DataColumn(label: Text("Quantidade")),
                    DataColumn(label: Text("Qtd Minima")),
                    DataColumn(label: Text("Tipo")),
                  ],
                  rows: itens.map<DataRow>((item) {
                    return DataRow(cells: [
                      DataCell(Text(item['Item'] ?? "")),
                      DataCell(Text(item['Quantidade'] ?? "")),
                      DataCell(Text(item['Qtd Minima'] ?? "")),
                      DataCell(Text(item['Tipo'] ?? "")),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
