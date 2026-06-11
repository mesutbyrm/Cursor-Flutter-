import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_theme_colors.dart';
import '../ui/premium_2026/premium_2026_tokens.dart';
import 'canlifal_tokens.dart';

/// Material 3 — merkezi [AppThemeColors] ile light / dark.
class AppTheme {
  AppTheme._();

  // Geriye dönük sabitler (yeni kod: context.colors)
  static const Color background = Color(0xFF0B0B1E);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C26);
  static const Color accent = AppThemeColors.accentPink;
  static const Color accentSecondary = AppThemeColors.accentCyan;
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6E6E82);

  static ThemeData dark() => _build(AppThemeColors.dark, CanlifalTokens.dark);

  static ThemeData light() => _build(AppThemeColors.light, CanlifalTokens.light);

  static ThemeData _build(AppThemeColors c, CanlifalTokens tokens) {
    final palette = AppPalette(c);
    final isDark = c.isDark;
    final p26 = isDark ? Premium2026Tokens.dark : Premium2026Tokens.light;

    final base = ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      scaffoldBackgroundColor: c.scaffoldBackground,
      colorScheme: c.toColorScheme(),
      extensions: [tokens, p26, palette],
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          // Android: Cupertino geçişi soğuk açılışta gri modal scrim bırakabiliyor.
          TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    final textTheme = _textTheme(base.textTheme, c.onSurface);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: c.onSurface,
        iconTheme: IconThemeData(color: c.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: c.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.navBarBackground,
        indicatorColor: c.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? c.onSurface : c.onSurfaceMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? c.onSurface : c.onSurfaceMuted,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceElevated,
        elevation: isDark ? 0 : 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.dialogBackground,
        elevation: isDark ? 0 : 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: c.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bottomSheetBackground,
        modalBackgroundColor: c.bottomSheetBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: c.onSurfaceMuted.withValues(alpha: 0.45),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackBarBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.onSurfaceVariant,
        textColor: c.onSurface,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: c.onSurface,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: c.onSurfaceMuted,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: c.onSurface),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceContainer,
        labelStyle: TextStyle(color: c.onSurface),
        side: BorderSide(color: c.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          elevation: isDark ? 0 : 2,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.secondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.onSurfaceMuted),
        labelStyle: TextStyle(color: c.onSurfaceVariant),
      ),
      iconTheme: IconThemeData(color: c.onSurfaceVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.onPrimary;
          return c.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primary.withValues(alpha: 0.55);
          }
          return c.outline;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return c.onPrimary;
            return c.onSurfaceVariant;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return c.primary;
            return c.surfaceContainer;
          }),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    try {
      return GoogleFonts.plusJakartaSansTextTheme(base).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      );
    } catch (_) {
      return base.apply(bodyColor: onSurface, displayColor: onSurface);
    }
  }
}
