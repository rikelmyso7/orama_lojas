import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/pages/checklist/checklist_page.dart';
import 'package:orama_lojas/utils/scroll_hide_fab.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:provider/provider.dart';
import '../../stores/checklist_store.dart';

class ChecklistSelectPage extends StatefulWidget {
  final String storeName;
  final String? periodo;
  final String funcionario;

  const ChecklistSelectPage({
    super.key,
    required this.storeName,
    required this.periodo,
    required this.funcionario,
  });

  @override
  State<ChecklistSelectPage> createState() => _ChecklistSelectPageState();
}

class _ChecklistSelectPageState extends State<ChecklistSelectPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    context.read<ChecklistStore>().loadAll();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enviarChecklist(BuildContext context) async {
    final store = context.read<ChecklistStore>();

    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now);
    final String id =
        "${widget.funcionario} - ${formattedDate} - ${widget.periodo}";

    // escolhe os itens do período selecionado
    final items = widget.periodo == 'ABERTURA'
        ? store.abertura?.itens ?? []
        : store.fechamento?.itens ?? [];

    final docData = {
      'id': id,
      'loja': widget.storeName,
      'periodo': widget.periodo,
      'funcionario': widget.funcionario,
      'data': formattedDate,
      'itens': items.asMap().entries.map((e) {
        return {
          'nome': e.value,
          'feito': store.isChecked(widget.periodo!.toLowerCase(),
              e.key), // usa id abertura/fechamento
        };
      }).toList(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('checklist_resultados')
          .doc(id)
          .set(docData);

      if (mounted) {
        ShowSnackBar(context, "Checklist salvo com sucesso!", Colors.green);
        store.resetAll();
      }
    } catch (e) {
      if (mounted) {
        ShowSnackBar(context, "Falha ao salvar checklist", Colors.green);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChecklistStore>();

    Widget buildList(String id, List<String> itens) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: itens.length,
        itemBuilder: (_, i) => Observer(builder: (_) {
          final checked = store.isChecked(id, i);
          return Card(
            child: CheckboxListTile(
              title: Text(itens[i]),
              value: checked,
              onChanged: (v) => store.toggle(id, i, v ?? false),
            ),
          );
        }),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        store.resetAll();
        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 4,
          backgroundColor: const Color(0xff60C03D),
          scrolledUnderElevation: 0,
          title: Observer(builder: (_) {
            final itens = widget.periodo == 'ABERTURA'
                ? store.abertura?.itens ?? []
                : store.fechamento?.itens ?? [];
            final total = itens.length;
            final feitos = itens.asMap().entries.where((e) {
              return store.isChecked(widget.periodo!.toLowerCase(), e.key);
            }).length;
            final progress = total == 0 ? 0.0 : feitos / total;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checklist ${widget.storeName.toUpperCase()}',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${widget.funcionario} - ${widget.periodo}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12),
                ),
                const SizedBox(height: 4),
                // progress bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  color: Colors.amber,
                  minHeight: 4,
                ),
              ],
            );
          }),
        ),
        body: Observer(builder: (_) {
          if (store.abertura == null || store.fechamento == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // mostra somente o período selecionado
          if (widget.periodo == 'ABERTURA') {
            return buildList('abertura', store.abertura!.itens);
          } else {
            return buildList('fechamento', store.fechamento!.itens);
          }
        }),
        floatingActionButton: ScrollHideFab(
          scrollController: _scrollController,
          child: FloatingActionButton(
            onPressed: () {
              _enviarChecklist(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChecklistPage(
                            storeName: widget.storeName,
                          )));
            },
            backgroundColor: const Color(0xff60C03D),
            child: const Icon(
              Icons.check,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
