import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ui/premium_2026/premium_2026_tokens.dart';

/// Premium Fortune — koyu mistik tema.
abstract final class PfTheme {
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF5E6A8);
  static const Color purple = Color(0xFF9B5DE5);
  static const Color pink = Color(0xFFFF4FD8);
  static const Color surface = Color(0xFF0E0A1A);
  static const Color surfaceElevated = Color(0xFF1A1228);
  static const Color card = Color(0xFF1E1630);
  static const Color border = Color(0x33FFFFFF);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: purple,
        secondary: pink,
        tertiary: gold,
        surface: surface,
        onSurface: Color(0xFFF5F0FF),
        error: Color(0xFFFF6B6B),
      ),
      extensions: const [Premium2026Tokens.dark],
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Color(0xFFF5F0FF),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: gold,
        unselectedItemColor: Color(0x88FFFFFF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: border,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFF5F0FF),
        displayColor: const Color(0xFFF5F0FF),
      ),
    );
  }
}
