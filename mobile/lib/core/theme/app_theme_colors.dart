import 'package:flutter/material.dart';

/// Tek renk kaynağı — tüm light/dark yüzey, metin, cam ve gölge token'ları.
@immutable
class AppThemeColors {
  const AppThemeColors({
    required this.brightness,
    required this.scaffoldBackground,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceMuted,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.outline,
    required this.outlineVariant,
    required this.divider,
    required this.glassFill,
    required this.glassFillElevated,
    required this.glassBorder,
    required this.glassHighlight,
    required this.dialogBackground,
    required this.bottomSheetBackground,
    required this.snackBarBackground,
    required this.barrier,
    required this.brandGradient,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.useGlassBlur,
  });

  final Brightness brightness;
  final Color scaffoldBackground;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceMuted;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color outline;
  final Color outlineVariant;
  final Color divider;
  final Color glassFill;
  final Color glassFillElevated;
  final Color glassBorder;
  final Color glassHighlight;
  final Color dialogBackground;
  final Color bottomSheetBackground;
  final Color snackBarBackground;
  final Color barrier;
  final Gradient brandGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedShadow;
  final bool useGlassBlur;

  bool get isDark => brightness == Brightness.dark;

  /// Marka vurguları — tema bağımsız.
  static const Color accentPink = Color(0xFFFE2C55);
  static const Color accentPurple = Color(0xFFB832FF);
  static const Color accentCyan = Color(0xFF25F4EE);
  static const Color liveRed = Color(0xFFFF3B5C);
  static const Color onlineGreen = Color(0xFF3DFF6E);
  static const Color diamondBlue = Color(0xFF5B8CFF);
  static const Color coinGold = Color(0xFFFFD54F);
  static const Color warning = Color(0xFFFFB347);

  static List<BoxShadow> glowShadow(Color color, {double blur = 24}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: blur,
        ),
      ];

  static const AppThemeColors dark = AppThemeColors(
    brightness: Brightness.dark,
    scaffoldBackground: Color(0xFF0B0B1E),
    surface: Color(0xFF14141C),
    surfaceElevated: Color(0xFF1C1C26),
    surfaceContainer: Color(0xFF16162A),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFB8B8C8),
    onSurfaceMuted: Color(0xFF6E6E82),
    primary: accentPink,
    onPrimary: Colors.white,
    secondary: accentCyan,
    onSecondary: Color(0xFF0B0B1E),
    outline: Color(0xFF3A3A4E),
    outlineVariant: Color(0xFF2A2A38),
    divider: Color(0xFF2A2A38),
    glassFill: Color(0x8C1E1E36),
    glassFillElevated: Color(0xA31C1C2E),
    glassBorder: Color(0x55B832FF),
    glassHighlight: Color(0x18FFFFFF),
    dialogBackground: Color(0xFF1C1C26),
    bottomSheetBackground: Color(0xF01C1C26),
    snackBarBackground: Color(0xFF252536),
    barrier: Color(0x8C000000),
    brandGradient: LinearGradient(
      colors: [accentPink, accentPurple],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x66FE2C55),
        blurRadius: 28,
        spreadRadius: -6,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
    useGlassBlur: true,
  );

  /// Modern, profesyonel açık tema.
  static const AppThemeColors light = AppThemeColors(
    brightness: Brightness.light,
    scaffoldBackground: Color(0xFFF5F6FA),
    surface: Colors.white,
    surfaceElevated: Color(0xFFF8F9FC),
    surfaceContainer: Color(0xFFF0F2F8),
    onSurface: Color(0xFF0F0F1A),
    onSurfaceVariant: Color(0xFF3D3D52),
    onSurfaceMuted: Color(0xFF6E6E82),
    primary: Color(0xFFE91E63),
    onPrimary: Colors.white,
    secondary: Color(0xFF00B8B0),
    onSecondary: Color(0xFF0F0F1A),
    outline: Color(0xFFD8DAE5),
    outlineVariant: Color(0xFFE8EAF0),
    divider: Color(0xFFE5E7EF),
    glassFill: Color(0xF5FFFFFF),
    glassFillElevated: Color(0xFFFFFFFF),
    glassBorder: Color(0x339C27B0),
    glassHighlight: Color(0x40FFFFFF),
    dialogBackground: Colors.white,
    bottomSheetBackground: Color(0xFFFFFFFF),
    snackBarBackground: Color(0xFF1A1A2E),
    barrier: Color(0x66000000),
    brandGradient: LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
    ),
    cardShadow: [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x33E91E63),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    useGlassBlur: false,
  );

  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      error: liveRed,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceElevated,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
    );
  }
}
