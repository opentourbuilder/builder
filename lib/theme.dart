import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

var themeData = ThemeData(
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: MaterialStateProperty.all(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),
  ),
  textTheme: TextTheme(
    button: GoogleFonts.robotoCondensed().copyWith(
      letterSpacing: 1.25,
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
    ),
  ),
  colorScheme: const ColorScheme.light(
    primary: Color.fromARGB(255, 55, 73, 233),
    onPrimary: Colors.white,
    secondary: Color.fromARGB(255, 20, 173, 122),
    onSecondary: Colors.white,
  ),
);
