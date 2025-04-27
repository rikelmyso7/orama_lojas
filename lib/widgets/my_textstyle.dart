import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTextStyle {
  MyTextStyle._();

  static TextStyle defaultStyle = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontWeight: FontWeight.w400,
      color: Colors.grey.shade600,
    ),
  );

  static TextStyle largerTitle = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: Color(0xff1E232C),
    ),
  );

  static TextStyle mediunTitle = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: Color(0xff1E232C),
    ),
  );

  static TextStyle logo = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontSize: 28,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      color: Color(0xff1E232C),
    ),
  );

  static TextStyle hintTextFieldStyle = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade500,
    ),
  );

  static TextStyle semiTitle = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade500,
    ),
  );

  static TextStyle largerButtonTextStyle = GoogleFonts.nunito(
    textStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 15,
    ),
  );

  static TextStyle textDivisorStyle = GoogleFonts.nunito(
    textStyle: TextStyle(
      fontWeight: FontWeight.w400,
      color: Colors.grey.shade600,
    ),
  );

  static TextStyle linkTextStyle = GoogleFonts.nunito(
    textStyle: TextStyle(
      color: Colors.blue,
      fontWeight: FontWeight.bold,
    ),
  );
}
