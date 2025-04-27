import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/others/insumos.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:orama_lojas/utils/exit_dialog_utils.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:provider/provider.dart';

class EditarEspecificoRelatorioPage extends StatefulWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic> reportData;
  final String reportId;
  final String tipo_relatorio;

  const EditarEspecificoRelatorioPage({
    Key? key,
    required this.nome,
    required this.data,
    required this.city,
    required this.loja,
    required this.reportData,
    required this.reportId,
    required this.tipo_relatorio,
  }) : super(key: key);

  @override
  _EditarEspecificoRelatorioPageState createState() =>
      _EditarEspecificoRelatorioPageState();
}

class _EditarEspecificoRelatorioPageState
    extends State<EditarEspecificoRelatorioPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> quantityControllers = {};
  final Map<String, TextEditingController> minControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final categorias = widget.reportData['Categorias'] as List<dynamic>?;

    for (final category in insumos.keys) {
      final items = insumos[category]!;
      for (final item in items) {
        final itemName = item['nome'];
        final key = (category == 'BALDES' || category == 'POTES')
            ? '${category}_$itemName'
            : itemName;

        final existingItem = categorias
            ?.firstWhere(
              (cat) => cat['Categoria'] == category,
              orElse: () => null,
            )?['Itens']
            ?.firstWhere(
              (it) => it['Item'] == itemName,
              orElse: () => null,
            );

        final quantidade = existingItem?['Quantidade']?.toString() ?? '';
        final minimo = existingItem?['Qtd Minima']?.toString() ??
            item['minimo'].toString();

        quantityControllers[key] = TextEditingController(text: quantidade);
        minControllers[key] = TextEditingController(text: minimo);
      }
    }
  }

  Future<void> _updateReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final updatedData = {
      'ID': widget.reportId,
      'Nome do usuario': widget.nome,
      'Data': formattedDate,
      'Cidade': widget.city,
      'Loja': widget.loja,
      'Categorias': [],
      'Tipo Relatorio': widget.tipo_relatorio,
    };

    // Filtra apenas os itens com valores preenchidos
    final categorias = insumos.keys
        .map((category) {
          final items = <Map<String, dynamic>>[];

          for (var item in insumos[category] ?? []) {
            final itemName = item['nome'];
            final tipo = item['tipo'] ?? '';
            final key = (category == 'BALDES' || category == 'POTES')
                ? '${category}_$itemName'
                : itemName;

            final quantidade = quantityControllers[key]?.text.trim() ?? '';
            final minimo = minControllers[key]?.text.trim() ?? '';

            // Adiciona o item apenas se a quantidade E o mínimo forem preenchidos
            if (quantidade.isNotEmpty) {
              items.add({
                'Item': itemName,
                'Quantidade': quantidade,
                'Qtd Minima': minimo,
                'Tipo': tipo,
              });
            }
          }

          // Inclui apenas categorias com itens preenchidos
          if (items.isNotEmpty) {
            return {'Categoria': category, 'Itens': items};
          }
          return null;
        })
        .where((categoria) => categoria != null) // Remove categorias vazias
        .toList();

    updatedData['Categorias'] = categorias;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio_especifico')
          .doc(widget.reportId)
          .set(updatedData, SetOptions(merge: true));

      ShowSnackBar(context, 'Relatório salvo com sucesso!', Colors.green);
      final store = Provider.of<StockStore>(context, listen: false);
      await store.fetchReportsEspecifico();
      Navigator.pop(context);
    } catch (e) {
      print("Erro ao atualizar o relatório: $e");
    }
  }

  /// Exclui o relatório do Firestore
  Future<void> _deleteReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio_especifico')
          .doc(widget.reportId)
          .delete();

      ShowSnackBar(
          context, 'Relatório deletado com sucesso!', Colors.red.shade400);
      final store = Provider.of<StockStore>(context, listen: false);
      await store.fetchReportsEspecifico();
      Navigator.pop(context);
    } catch (e) {
      print("Erro ao excluir o relatório: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldPop = await DialogUtils.showConfirmationDialog(
              context: context,
              title: 'Confirmação de Saída',
              content: 'Você deseja sair do aplicativo?',
              confirmText: 'Sair',
              cancelText: 'Não',
              onConfirm: () {
                exit(0);
              },
            ) ??
            false;
      },
      child: DefaultTabController(
        length: insumos.keys.length,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Editar Relatório Específico - ${widget.loja}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xff60C03D),
            actions: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteReport,
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _updateReport,
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              indicatorColor: Colors.amber,
              tabs:
                  insumos.keys.map((category) => Tab(text: category)).toList(),
            ),
          ),
          body: TabBarView(
            children: insumos.keys.map((category) {
              final items = List.from(insumos[category]!);
              items.sort((a, b) => a['nome'].compareTo(b['nome']));

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final itemName = item['nome'];
                  final key = (category == 'BALDES' || category == 'POTES')
                      ? '${category}_$itemName'
                      : itemName;
                  final tipo = item['tipo'] ?? '';

                  return _buildItemCard(item, key);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, String key) {
    final itemName = item['nome'];
    final tipo = item['tipo'];
    final defaultValue = item['minimo'].toString();
    final isFraction = defaultValue.contains('/'); // Verifica se é uma fração

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMinInputField(
                    label: 'Qtd Mínima',
                    controller: minControllers[key] ?? TextEditingController(),
                    defaultValue: defaultValue,
                    onChanged: (value) {
                      minControllers[key]?.text = value;
                    },
                    tipo: tipo ?? '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInputField(
                    label: 'Quantidade',
                    controller:
                        quantityControllers[key] ?? TextEditingController(),
                    inputType: TextInputType.name,
                    onChanged: (value) {
                      quantityControllers[key]?.text = value;
                    },
                    icon: Icon(
                      Icons.balance,
                      color: Colors.grey[500],
                    ),
                    isFraction: isFraction, // Passa a informação de fração
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinInputField({
    required String label,
    required TextEditingController controller,
    required String defaultValue,
    required String tipo,
    required void Function(String) onChanged,
  }) {
    final isFraction = defaultValue.contains('/');
    if (isFraction) {
      return DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : defaultValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffix: Text(tipo, style: TextStyle(color: Colors.grey[500])),
        ),
        items: ['1/4', '2/4', '3/4', '4/4']
            .map((fraction) => DropdownMenuItem(
                  value: fraction,
                  child: Text(fraction),
                ))
            .toList(),
        onChanged: (value) {
          controller.text = value!;
          onChanged(value);
        },
      );
    } else {
      return TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffix: Text(
            tipo,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
        onChanged: onChanged,
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required TextInputType inputType,
    required void Function(String) onChanged,
    required icon,
    bool isFraction = false,
  }) {
    if (isFraction) {
      return DropdownButtonFormField<String>(
        value: ['', '0', '1/4', '2/4', '3/4', '4/4'].contains(controller.text)
            ? controller.text
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: icon,
        ),
        items: [
          '', // Opção vazia
          '0',
          '1/4',
          '2/4',
          '3/4',
          '4/4',
        ]
            .map((fraction) => DropdownMenuItem(
                  value: fraction,
                  child: Flexible(
                      child: Text(
                    fraction.isEmpty ? 'Selecio...' : fraction,
                  )),
                ))
            .toList(),
        onChanged: (value) {
          controller.text =
              value ?? ''; // Atualiza o controlador com o valor selecionado
          onChanged(value ?? '');
        },
      );
    } else {
      return TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          suffixIcon: icon,
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: onChanged,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in minControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
