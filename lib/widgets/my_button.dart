import 'package:flutter/material.dart';
import 'package:orama_lojas/widgets/my_textstyle.dart';

class MyButton extends StatefulWidget {
  final String buttonName;
  final Function()? onTap;
  final bool enabled;

  const MyButton({
    super.key, 
    required this.buttonName, 
    this.onTap, 
    required this.enabled
  });

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled && !isLoading
          ? () async {
              if (widget.onTap != null) {
                try {
                  setState(() {
                    isLoading = true;
                  });
                  await widget.onTap!();
                } catch (e) {
                  // Handle any errors here if needed
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        decoration: BoxDecoration(
          color: widget.enabled ? const Color(0xff60C03D) : Colors.grey,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 12,
              offset: const Offset(0, 7), // changes position of shadow
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 25,
                  height: 25,
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.buttonName,
                  style: MyTextStyle.largerButtonTextStyle,
                ),
        ),
      ),
    );
  }
}
