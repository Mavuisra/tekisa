/// Thème de l'application - Interface colorée adaptée aux enfants
library;

import 'package:flutter/material.dart';

/// Palette TEKISA : base bleu-vert + neutres gris.
class AppColors {
  AppColors._();

  static const Color bluePrimary = Color(0xFF035D8A);
  static const Color blueDark = Color(0xFF024A6E);
  static const Color blueLight = Color(0xFF2B7AA3);
  static const Color accentYellow = Color(0xFF94A3B8);
  static const Color accentRedLight = Color(0xFFE11D48);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFB45309);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
}

/// Thème principal
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bluePrimary,
        primary: AppColors.bluePrimary,
        secondary: AppColors.accentYellow,
        error: AppColors.accentRedLight,
        surface: AppColors.backgroundLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.bluePrimary,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bluePrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}
