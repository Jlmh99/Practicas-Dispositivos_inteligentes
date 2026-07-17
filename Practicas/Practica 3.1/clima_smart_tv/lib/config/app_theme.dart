import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF0A0A1A);

  static const focusColor = Color(0xFFFFD700);

  static const cardColor = Color.fromRGBO(255, 255, 255, 0.12);

  static const detailColor = Color.fromRGBO(255, 255, 255, 0.75);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A237E),
        brightness: Brightness.dark,
      ),

      fontFamily: 'Segoe UI',
    );
  }
}