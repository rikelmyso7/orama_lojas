import 'package:flutter/material.dart';
import 'package:orama_lojas/widgets/my_textstyle.dart';

class MyDropDownButton extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> options;
  final Function(dynamic)? onChanged;
  const MyDropDownButton(
      {super.key,
      required this.value,
      required this.options,
      this.onChanged,
      required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      margin: EdgeInsets.symmetric(horizontal: 25),
      padding: EdgeInsets.only(left: 10, right: 5),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey),
          ),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          style: MyTextStyle.hintTextFieldStyle,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 36,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
