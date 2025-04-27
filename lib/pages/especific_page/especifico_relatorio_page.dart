import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/others/insumos.dart';
import 'package:orama_lojas/pages/especific_page/especifico_view_page.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class EspecificoRelatorioPage extends StatefulWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic>? reportData;
  final String? reportId;
  final String tipo_relatorio;

  const EspecificoRelatorioPage({
    Key? key,
    required this.nome,
    required this.data,
    required this.city,
    required this.loja,
    this.reportData,
    this.reportId,
    required this.tipo_relatorio,
  }) : super(key: key);

  @override
  _EspecificoRelatorioPageState createState() =>
      _EspecificoRelatorioPageState();
}

class _EspecificoRelatorioPageState extends State<EspecificoRelatorioPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> quantityControllers = {};
  final Map<String, TextEditingController> minControllers = {};
  bool isLoading = false;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Certifique-se de usar o Provider aqui
    final store = Provider.of<StockStore>(context, listen: false);
    store.fetchReportsEspecifico(); // Chamada ao método do store
  }

  void _initializeFields() {
    if (widget.reportData != null) {
      _populateControllersFromReport(widget.reportData!);
    } else {
      _initializeEmptyFields();
    }
  }

  void _populateControllersFromReport(Map<String, dynamic> reportData) {
    final categorias = reportData['Categorias'] as List<dynamic>?;
    categorias?.forEach((category) {
      final categoryName = category['Categoria'];
      final itens = category['Itens'] as List<dynamic>;

      for (final item in itens) {
        final itemName = item['Item'];
        final key = _generateKey(categoryName, itemName);

        quantityControllers[key] = TextEditingController(
          text: item['Quantidade']?.toString() ?? '',
        );
        minControllers[key] = TextEditingController(
          text: item['Qtd Minima']?.toString() ?? '',
        );
      }
    });
  }

  void _initializeEmptyFields() {
    for (final category in insumos.keys) {
      for (final item in insumos[category]!) {
        final itemName = item['nome'];
        final key = _generateKey(category, itemName);

        quantityControllers.putIfAbsent(key, () => TextEditingController());
        minControllers.putIfAbsent(
            key, () => TextEditingController(text: item['minimo'].toString()));
      }
    }
  }

  String _generateKey(String category, String itemName) {
    return (category == 'BALDES' || category == 'POTES')
        ? '${category}_$itemName'
        : itemName;
  }

  Future<void> _saveData() async {
    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ShowSnackBar(context, 'Usuário não autenticado!', Colors.yellow);
      setState(() => isLoading = false);
      return;
    }

    final userId = user.uid;
    final uuid = widget.reportId ?? const Uuid().v4();
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = insumos.keys
        .map((category) {
          final items = insumos[category]!
              .map((item) {
                final itemName = item['nome'];
                final tipo = item['tipo'] ?? '';
                final key = _generateKey(category, itemName);
                final quantidade = quantityControllers[key]?.text.trim() ?? '';
                final minimo = minControllers[key]?.text.trim() ?? '';

                // Verifica se a quantidade foi preenchida pelo usuário
                if (quantidade.isNotEmpty) {
                  return {
                    'Item': itemName,
                    'Quantidade': quantidade,
                    'Qtd Minima': minimo,
                    'Tipo': tipo,
                  };
                }

                return null; // Ignora itens com quantidade vazia
              })
              .where((item) => item != null) // Remove itens nulos
              .toList();

          // Inclui a categoria apenas se houver itens preenchidos
          if (items.isNotEmpty) {
            return {'Categoria': category, 'Itens': items};
          }

          return null; // Ignora categorias sem itens preenchidos
        })
        .where((categoria) => categoria != null) // Remove categorias nulas
        .toList();

    final report = {
      'ID': uuid,
      'Nome do usuario': widget.nome,
      'Data': formattedDate,
      'Cidade': widget.city,
      'Loja': widget.loja,
      'Categorias': categorias,
      'Tipo Relatorio': widget.tipo_relatorio,
    };

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('relatorio_especifico')
          .doc(uuid)
          .set(report);

      ShowSnackBar(context, 'Relatório salvo com sucesso!', Colors.green);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => EspecificoViewPage()),
        (route) => false,
      );
    } catch (e) {
      ShowSnackBar(context, 'Erro ao salvar relatório: $e', Colors.green);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: insumos.keys.length,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Estoque Específico - ${widget.loja}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xff60C03D),
          actions: [
            isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _saveData,
                  ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.amber,
            isScrollable: true,
            tabs: insumos.keys.map((category) => Tab(text: category)).toList(),
            onTap: (index) {
              _removeFocus();
            },
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
                final key = _generateKey(category, itemName);

                return _buildItemCard(item, key);
              },
            );
          }).toList(),
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
    required void Function(String) onChanged,
    required String tipo,
  }) {
    final isFraction = defaultValue.contains('/');

    if (isFraction) {
      return DropdownButtonFormField<String>(
        value: ['1/4', '2/4', '3/4', '4/4'].contains(controller.text)
    ? controller.text
    : defaultValue, // Se o valor não estiver na lista, usa o default

        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffix: Text(tipo),
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
        keyboardType: TextInputType.name,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffix: Text(tipo),
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
        value: controller.text, // Permite valor vazio
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

  void _removeFocus() {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
