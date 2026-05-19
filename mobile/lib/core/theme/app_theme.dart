import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TikTok tarzı koyu tema — yüksek kontrast, neon vurgular.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0B0B1E);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C26);
  static const Color accent = Color(0xFFFE2C55);
  static const Color accentSecondary = Color(0xFF25F4EE);
  static const Color onBackground = Color(0xFFF5F5F7);
  static const Color muted = Color(0xFF8E8E93);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentSecondary,
        surface: surface,
        error: accent,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: onBackground,
      ),
    );
    TextTheme textTheme;
    try {
      textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: onBackground,
        displayColor: onBackground,
      );
    } catch (_) {
      textTheme = base.textTheme.apply(
        bodyColor: onBackground,
        displayColor: onBackground,
      );
    }
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: onBackground,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: onBackground,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentSecondary),
      ),
      dividerColor: surfaceElevated,
    );
  }
}
