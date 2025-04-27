import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:orama_lojas/stores/stock_store.dart';
import 'package:intl/intl.dart';

class StockTab extends StatefulWidget {
  final String category;
  final List<String> items;

  StockTab({required this.category, required this.items});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return StockItemCard(
          itemName: widget.items[index],
          isLastItem: index == widget.items.length - 1,
        );
      },
    );
  }
}

class StockItemCard extends StatefulWidget {
  final String itemName;
  final bool isLastItem;

  StockItemCard({required this.itemName, required this.isLastItem});

  @override
  _StockItemCardState createState() => _StockItemCardState();
}

class _StockItemCardState extends State<StockItemCard> {
  late TextEditingController kgController;
  late TextEditingController quantityController;
  late FocusNode kgFocusNode;
  late FocusNode quantityFocusNode;

  bool isKgFilled = false;
  bool isQuantityFilled = false;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<StockStore>(context, listen: false);

    quantityController = TextEditingController(
        text: store.quantityValues[widget.itemName] ?? '');
    kgFocusNode = FocusNode();
    quantityFocusNode = FocusNode();

    quantityController.addListener(() {
      store.updateQuantity(widget.itemName, quantityController.text);
      setState(() {
        isQuantityFilled = quantityController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    kgController.dispose();
    quantityController.dispose();
    kgFocusNode.dispose();
    quantityFocusNode.dispose();
    super.dispose();
  }

  String _formatToKg(String input) {
    // Remove qualquer caractere não numérico
    String cleanedInput = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Converte para gramas
    double valueInGrams = int.tryParse(cleanedInput)?.toDouble() ?? 0.0;

    // Converte para quilogramas e formata para 3 casas decimais
    double valueInKg = valueInGrams / 1000;
    return NumberFormat('0.000').format(valueInKg);
  }

  void _handleEditingComplete() {
    if (!isKgFilled) {
      kgFocusNode.requestFocus();
    } else if (!isQuantityFilled) {
      quantityFocusNode.requestFocus();
    } else if (!widget.isLastItem) {
      FocusScope.of(context).nextFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 5,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.itemName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputField(
                    label: 'Peso',
                    controller: kgController,
                    focusNode: kgFocusNode,
                    nextFocusNode: quantityFocusNode,
                    isFilled: isKgFilled,
                    icon: Icons.balance,
                    inputFormatter: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        String formatted = _formatToKg(newValue.text);
                        return TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                      }),
                    ],
                    sufix: 'Kg',
                  ),
                  const SizedBox(width: 12),
                  _buildInputField2(
                    label: 'Quantidade',
                    controller: quantityController,
                    focusNode: quantityFocusNode,
                    isFilled: isQuantityFilled,
                    icon: Icons.format_list_numbered,
                    onEditingComplete: _handleEditingComplete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required bool isFilled,
    required IconData icon,
    required String sufix,
    List<TextInputFormatter>? inputFormatter,
    void Function()? onEditingComplete,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  inputFormatters: inputFormatter,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon),
                    suffix: Text(
                      sufix,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    hintText: '0.000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: onEditingComplete ??
                      () {
                        if (nextFocusNode != null) {
                          FocusScope.of(context).requestFocus(nextFocusNode);
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      },
                ),
              ),
              if (isFilled)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField2({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required bool isFilled,
    required IconData icon,
    List<TextInputFormatter>? inputFormatter,
    void Function()? onEditingComplete,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  inputFormatters: inputFormatter,
                  decoration: InputDecoration(
                    prefixIcon: Icon(icon),
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: onEditingComplete ??
                      () {
                        if (nextFocusNode != null) {
                          FocusScope.of(context).requestFocus(nextFocusNode);
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      },
                ),
              ),
              if (isFilled)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
