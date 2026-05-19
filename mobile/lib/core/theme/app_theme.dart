import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// canlifal.com web arayüzüyle uyumlu kozmik koyu tema (mor gece, yıldız, pembe vurgular).
class AppTheme {
  AppTheme._();

  /// Ana zemin — çok koyu mor/lacivert.
  static const Color background = Color(0xFF0A0518);
  /// Kart / panel zemini.
  static const Color surface = Color(0xFF151028);
  static const Color surfaceElevated = Color(0xFF1E1235);
  /// Kenarlık ve hafif parıltı için orta mor.
  static const Color cosmicPurple = Color(0xFF4A2F7A);
  /// Bölüm başlığı dikey çubuğu (web’deki kırmızı aksan).
  static const Color sectionBar = Color(0xFFE53935);
  /// Jeton / premium vurguları.
  static const Color accentGold = Color(0xFFF4C430);
  /// Ana etkileşim (FAB, canlı).
  static const Color accent = Color(0xFFFF2D7A);
  /// İkincil neon (ikon / link).
  static const Color accentSecondary = Color(0xFFB388FF);
  static const Color onBackground = Color(0xFFF5F5F7);
  static const Color muted = Color(0xFFB0A8C9);

  static LinearGradient get cosmicBackdropGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A0F2E),
          Color(0xFF0D0618),
          Color(0xFF050210),
        ],
        stops: [0.0, 0.45, 1.0],
      );

  static LinearGradient get fabGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF2D7A),
          Color(0xFFB400FF),
        ],
      );

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
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: onBackground,
      displayColor: onBackground,
    );
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
