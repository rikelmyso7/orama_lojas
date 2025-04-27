import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orama_lojas/services/stock_moviment.dart';
import 'package:orama_lojas/services/stock_service.dart';
import 'package:orama_lojas/utils/show_snackbar.dart';
import 'package:uuid/uuid.dart';
import 'package:orama_lojas/others/insumos.dart';
import 'package:orama_lojas/pages/relatorios_page.dart';

class FormularioPage extends StatefulWidget {
  final String nome;
  final String data;
  final String city;
  final String loja;
  final Map<String, dynamic>? reportData;
  final String? reportId;
  final String tipo_relatorio;

  const FormularioPage({
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
  State<FormularioPage> createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> quantityControllers = {};
  final Map<String, TextEditingController> minControllers = {};
  bool isLoading = true;
  late Map<String, List<Map<String, dynamic>>> insumosFiltrados;
  List<String> categoriasVisiveis = [];
  final StockService stockService = StockService();

  Future<void> _loadInsumosFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('configuracoes_loja')
          .doc(widget.loja)
          .get();

      if (!doc.exists) {
        ShowSnackBar(context, 'Loja não encontrada!', Colors.red);
        setState(() => isLoading = false);
        return;
      }

      final data = doc.data()!;
      final categorias = List<String>.from(data['categorias'] ?? []);
      final rawInsumos = data['insumos'] as Map<String, dynamic>? ?? {};

      final Map<String, List<Map<String, dynamic>>> parsedInsumos = {};

      for (final entry in rawInsumos.entries) {
        final categoria = entry.key;
        final items = List<Map<String, dynamic>>.from(entry.value);
        parsedInsumos[categoria] = items;
      }

      setState(() {
        categoriasVisiveis = categorias;
        insumosFiltrados = parsedInsumos;
        isLoading = false;
      });
    } catch (e) {
      ShowSnackBar(context, 'Erro ao carregar dados: $e', Colors.red);
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInsumosFromFirestore().then((_) {
      _initializeFields();
    });
  }

  void _initializeFields() {
    if (widget.reportData != null) {
      _populateFieldsFromReport(widget.reportData!);
    } else {
      _initializeEmptyFields();
    }
  }

  void _populateFieldsFromReport(Map<String, dynamic> reportData) {
    final categorias = reportData['Categorias'] as List<dynamic>?;

    categorias?.forEach((category) {
      final categoryName = category['Categoria'];
      final items = category['Itens'] as List<dynamic>;

      for (final item in items) {
        final itemName = item['Item'];
        final key = _generateKey(categoryName, itemName);

        quantityControllers[key] = TextEditingController(
          text: item['Quantidade']?.toString() ?? '0',
        );
        minControllers[key] = TextEditingController(
          text: item['Qtd Minima']?.toString() ?? '',
        );
      }
    });
  }

  void _initializeEmptyFields() {
    for (final category in categoriasVisiveis) {
      if (!insumosFiltrados.containsKey(category)) continue;
      for (final item in insumosFiltrados[category]!) {
        final itemName = item['nome'];
        final key = _generateKey(category, itemName);
        final defaultValue = item['minimo'].toString();

        // Se o valor mínimo é uma fração, garantir um valor padrão válido
        final isFraction = defaultValue.contains('/');
        final initialValue = isFraction ? '0' : defaultValue;

        quantityControllers.putIfAbsent(
            key, () => TextEditingController(text: '0'));
        minControllers.putIfAbsent(
            key, () => TextEditingController(text: initialValue));
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
      ShowSnackBar(context, 'Usuário não autenticado!', Colors.green);
      setState(() => isLoading = false);
      return;
    }

    final userId = user.uid;
    final uuid = widget.reportId ?? const Uuid().v4();
    final DateTime now = DateTime.now().toUtc().add(const Duration(hours: -3));
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final categorias = categoriasVisiveis.map((category) {
      final items = insumosFiltrados[category]!.map((item) {
        final itemName = item['nome'];
        final tipo = item['tipo'] ?? '';
        final key = (category == 'BALDES' || category == 'POTES')
            ? '${category}_$itemName'
            : itemName;
        var quantidade = quantityControllers[key]?.text.trim() ?? '0';
        final minimo = minControllers[key]?.text.trim() ?? item['minimo'];

        if (quantidade.isEmpty) {
          quantidade = '0';
        }

        return {
          'Item': itemName,
          'Quantidade': quantidade,
          'Qtd Minima': minimo,
          'Tipo': tipo,
        };
      }).toList();

      return {'Categoria': category, 'Itens': items};
    }).toList();

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
          .collection('relatorio')
          .doc(uuid)
          .set(report);

      final List<StockMovement> movimentos = [];

for (final categoria in categorias) {
  final String categoriaNome = categoria['Categoria'] as String;
  final List<dynamic> itens = categoria['Itens'] as List<dynamic>;

  for (final item in itens) {
    final String itemNome = item['Item'];
    final String quantidadeStr = item['Quantidade']?.toString() ?? '0';
    final double quantidade = double.tryParse(quantidadeStr.replaceAll(',', '.')) ?? 0;

    if (quantidade <= 0) continue;

    final String unidade = item['Tipo'] ?? '';

    movimentos.add(StockMovement(
      itemId: itemNome, // substitua por ID real se disponível
      nome: itemNome,
      quantidade: quantidade,
      unidade: unidade,
    ));
  }
}

await stockService.registrarSaida(
  destino: widget.loja,
  movimentos: movimentos,
);


      ShowSnackBar(context, 'Relatório salvo com sucesso!', Colors.green);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RelatoriosPage()),
        (route) => false,
      );
    } catch (e) {
      ShowSnackBar(context, 'Erro ao salvar relatório: $e', Colors.green);
    } finally {
      setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categoriasVisiveis.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Estoque - ${widget.loja}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          iconTheme: IconThemeData(color: Colors.white),
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
            tabs: categoriasVisiveis
                .map((category) => Tab(text: category))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: categoriasVisiveis.map((category) {
            final items = List.from(insumosFiltrados[category]!);
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
                    controller: quantityControllers[key] ??
                        TextEditingController(
                            text: item['Quantidade']?.toString()),
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
            : defaultValue,
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
      final validOptions = ['0', '1/4', '2/4', '3/4', '4/4'];

      // Garante que o valor inicial seja válido
      final initialValue =
          validOptions.contains(controller.text) ? controller.text : '0';

      return DropdownButtonFormField<String>(
        key: ValueKey(initialValue), // Atualiza corretamente ao mudar
        value: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: icon,
        ),
        items: validOptions
            .map((fraction) => DropdownMenuItem(
                  value: fraction,
                  child: Text(fraction),
                ))
            .toList(),
        onChanged: (value) {
          controller.text = value ?? '0';
          onChanged(value ?? '0');
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
}
