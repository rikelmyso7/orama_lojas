import 'package:flutter/material.dart';

class ChecklistItemCard extends StatelessWidget {
  final String itemText;
  final bool value;
  final Function(bool?) onChanged;

  const ChecklistItemCard({
    super.key,
    required this.itemText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: CheckboxListTile(
        title: Text(itemText),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xff60C03D),
      ),
    );
  }
}
