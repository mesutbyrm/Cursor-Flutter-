import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import '../ui/premium_2026/premium_2026_tokens.dart';
import 'canlifal_tokens.dart';

/// Material 3 — koyu (varsayılan) ve açık tema.
class AppTheme {
  AppTheme._();

  // Geriye dönük sabitler (yeni kod: AppColors)
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color surfaceElevated = AppColors.surfaceElevated;
  static const Color accent = AppColors.accentPink;
  static const Color accentSecondary = AppColors.accentCyan;
  static const Color onBackground = AppColors.textPrimary;
  static const Color muted = AppColors.textMuted;

  static ThemeData dark() => _build(Brightness.dark, CanlifalTokens.dark);

  static ThemeData light() => _build(Brightness.light, CanlifalTokens.light);

  static ThemeData _build(Brightness brightness, CanlifalTokens tokens) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : const Color(0xFFF8F8FC);
    final surface = isDark ? AppColors.surface : Colors.white;
    final onBg = isDark ? AppColors.textPrimary : const Color(0xFF0B0B1E);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPink,
        brightness: brightness,
        primary: AppColors.accentPink,
        secondary: AppColors.accentCyan,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: onBg,
      ),
      extensions: [
        tokens,
        isDark ? Premium2026Tokens.dark : Premium2026Tokens.light,
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = _textTheme(base.textTheme, onBg);

    return base.copyWith(
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: onBg,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.navBarBackground,
        indicatorColor: AppColors.accentPink.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? onBg
                : (isDark ? AppColors.textMuted : const Color(0xFF6E6E82)),
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceElevated : Colors.white,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusCard),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.accentCyan : AppColors.accentPink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF0F0F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.textMuted : const Color(0xFF8E8E93),
        ),
      ),
      dividerColor: isDark ? AppColors.surfaceElevated : const Color(0xFFE5E5EA),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceElevated : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Premium2026Tokens.dark.radiusSheet),
          ),
        ),
        showDragHandle: true,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onBg) {
    try {
      return GoogleFonts.plusJakartaSansTextTheme(base).apply(
        bodyColor: onBg,
        displayColor: onBg,
      );
    } catch (_) {
      return base.apply(bodyColor: onBg, displayColor: onBg);
    }
  }
}
