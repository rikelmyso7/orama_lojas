import 'package:flutter/material.dart';
import 'package:orama_lojas/widgets/my_textstyle.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? icon;
  final Widget? prefixicon;
  final TextInputType? keyBordType;

  const MyTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.validator,
    this.icon,
    this.keyBordType,
    this.prefixicon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              keyboardType: keyBordType,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white,
                filled: true,
                labelText: hintText,
                labelStyle: MyTextStyle.hintTextFieldStyle,
                prefixIcon: prefixicon,
                prefixIconColor: Colors.black38,
                suffixIcon: icon,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Builder(
            builder: (context) {
              final errorText = (context
                  .findAncestorStateOfType<FormFieldState<String>>()
                  ?.errorText);
              if (errorText != null) {
                return Text(
                  errorText,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              }
              return SizedBox(height: 0);
            },
          ),
        ],
      ),
    );
  }
}
