import 'package:flutter/material.dart';
import 'package:orama_lojas/others/insumos.dart';

class AddItemDialog extends StatefulWidget {
  final Function({
    required String category,
    required String name,
    required String min,
    required String quantity,
    required String type,
  }) onSave;

  const AddItemDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  String? _selectedType; // Tipo selecionado no DropdownButton

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _minController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<String> typeOptions = [
      'Balde',
      'Pote',
      'Un',
      'g',
      'Tubo',
      'Kg',
      'Fardo',
      'Caixa',
      'Sacos',
      'Litro',
      'Rolo',
    ];

    return AlertDialog(
      title: const Text('Adicionar Novo Item'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: null,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: insumos.keys.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _categoryController.text = value!;
                  if (value == "BALDES") {
                    _minController.text = "2/4"; // Define 2/4 para BALDES
                  } else {
                    _minController
                        .clear(); // Limpa o valor para outras categorias
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome do Item',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _minController,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                labelText: 'Quantidade Mínima',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.name,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: typeOptions
                  .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Salvar'),
          onPressed: () {
            final category = _categoryController.text;
            final name =
                _nameController.text.toUpperCase(); // Nome em maiúsculas
            final min = _minController.text;
            final quantity = _quantityController.text.toUpperCase();
            final type = _selectedType?.toUpperCase() ?? ''; // Tipo selecionado

            if (category.isNotEmpty && name.isNotEmpty && type.isNotEmpty) {
              widget.onSave(
                category: category,
                name: name,
                min: min,
                quantity: quantity,
                type: type,
              );
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, preencha todos os campos.'),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
