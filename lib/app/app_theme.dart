import 'package:flutter/material.dart';

class AppTheme {
  static const alive = Color(0xFF24825A);
  static const dead = Color(0xFFB04747);
  static const unknown = Color(0xFF697484);

  static ThemeData get light {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF256A5B),
      surface: const Color(0xFFF8FAF8),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
