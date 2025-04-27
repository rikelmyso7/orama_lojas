import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType inputType;
  final Function(String) onChanged;
  final Widget icon;
  final bool isFraction;

  const InputField({
    Key? key,
    required this.label,
    required this.controller,
    required this.inputType,
    required this.onChanged,
    required this.icon,
    this.isFraction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isFraction
        ? DropdownButtonFormField<String>(
            value: controller.text,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: icon,
            ),
            items: [
              '', '0', '1/4', '2/4', '3/4', '4/4',
            ].map((fraction) => DropdownMenuItem(
                  value: fraction,
                  child: Text(fraction.isEmpty ? 'Selecione...' : fraction),
                )).toList(),
            onChanged: (value) {
              controller.text = value ?? '';
              onChanged(value ?? '');
            },
          )
        : TextField(
            controller: controller,
            keyboardType: inputType,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: icon,
            ),
            onChanged: onChanged,
          );
  }
}

class MinInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String defaultValue;
  final String tipo;
  final Function(String) onChanged;

  const MinInputField({
    Key? key,
    required this.label,
    required this.controller,
    required this.defaultValue,
    required this.tipo,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isFraction = defaultValue.contains('/');

    return isFraction
        ? DropdownButtonFormField<String>(
            value: controller.text.isNotEmpty ? controller.text : defaultValue,
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
          )
        : TextField(
            controller: controller,
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
