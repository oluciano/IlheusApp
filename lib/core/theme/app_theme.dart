import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF1565C0);
  static const _backgroundColor = Color(0xFFFAFAFA);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: const CardTheme(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
