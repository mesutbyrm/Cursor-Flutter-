import 'package:flutter/material.dart';

import 'canlifal_brand_colors.dart' as brand;

typedef _B = brand.CanlifalBrandColors;

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
    BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: blur),
  ];

  static const AppThemeColors dark = AppThemeColors(
    brightness: Brightness.dark,
    scaffoldBackground: _B.ink,
    surface: _B.anthracite,
    surfaceElevated: _B.anthraciteRaised,
    surfaceContainer: _B.anthraciteContainer,
    onSurface: _B.textPrimary,
    onSurfaceVariant: _B.textSecondary,
    onSurfaceMuted: _B.textMuted,
    primary: _B.violetStrong,
    onPrimary: Colors.white,
    secondary: _B.turquoise,
    onSecondary: _B.ink,
    outline: Color(0xFF34343F),
    outlineVariant: _B.hairline,
    divider: _B.hairlineSoft,
    glassFill: Color(0xB8141419),
    glassFillElevated: Color(0xD11A1A21),
    glassBorder: Color(0x1FFFFFFF),
    glassHighlight: Color(0x14FFFFFF),
    dialogBackground: _B.anthraciteRaised,
    bottomSheetBackground: Color(0xF7141419),
    snackBarBackground: Color(0xFF24242D),
    barrier: Color(0x99000000),
    brandGradient: _B.primaryGradient,
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x528B5CF6),
        blurRadius: 28,
        spreadRadius: -8,
        offset: Offset(0, 12),
      ),
      BoxShadow(color: Color(0x73000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
    useGlassBlur: true,
  );

  /// Saf siyah AMOLED — OLED ekranlar için pil dostu koyu tema.
  static const AppThemeColors amoled = AppThemeColors(
    brightness: Brightness.dark,
    scaffoldBackground: Color(0xFF000000),
    surface: Color(0xFF050505),
    surfaceElevated: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFF080810),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFFC8C8D8),
    onSurfaceMuted: Color(0xFF8A8A9E),
    primary: _B.violetBright,
    onPrimary: Color(0xFF12082A),
    secondary: _B.turquoise,
    onSecondary: Color(0xFF000000),
    outline: Color(0xFF2E2E3A),
    outlineVariant: Color(0xFF1A1A22),
    divider: Color(0xFF1A1A22),
    glassFill: Color(0xB30A0A12),
    glassFillElevated: Color(0xCC0D0D16),
    glassBorder: Color(0x1AFFFFFF),
    glassHighlight: Color(0x12FFFFFF),
    dialogBackground: Color(0xFF0A0A0A),
    bottomSheetBackground: Color(0xF00A0A0A),
    snackBarBackground: Color(0xFF141418),
    barrier: Color(0x99000000),
    brandGradient: _B.primaryGradient,
    cardShadow: [
      BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x668B5CF6),
        blurRadius: 24,
        spreadRadius: -8,
        offset: Offset(0, 10),
      ),
    ],
    useGlassBlur: true,
  );

  /// Modern, profesyonel açık tema.
  static const AppThemeColors light = AppThemeColors(
    brightness: Brightness.light,
    scaffoldBackground: _B.paper,
    surface: _B.paperRaised,
    surfaceElevated: _B.paperRaised,
    surfaceContainer: _B.paperContainer,
    onSurface: _B.inkText,
    onSurfaceVariant: _B.inkTextSecondary,
    onSurfaceMuted: _B.inkTextMuted,
    primary: _B.violetStrong,
    onPrimary: Colors.white,
    secondary: _B.turquoiseDeep,
    onSecondary: Colors.white,
    outline: Color(0xFFD6D6E0),
    outlineVariant: Color(0xFFE6E6EE),
    divider: Color(0xFFE8E8EF),
    glassFill: Color(0xF2FFFFFF),
    glassFillElevated: Color(0xFFFFFFFF),
    glassBorder: Color(0x1F7C3AED),
    glassHighlight: Color(0x40FFFFFF),
    dialogBackground: Colors.white,
    bottomSheetBackground: Color(0xFFFFFFFF),
    snackBarBackground: Color(0xFF1C1C24),
    barrier: Color(0x66000000),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_B.violet, _B.violetStrong, _B.violetDeep],
    ),
    cardShadow: [
      BoxShadow(color: Color(0x0F16162A), blurRadius: 18, offset: Offset(0, 6)),
    ],
    elevatedShadow: [
      BoxShadow(
        color: Color(0x2E7C3AED),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
      BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    useGlassBlur: false,
  );

  ColorScheme toColorScheme() {
    Color tint(Color c, double a) =>
        Color.alphaBlend(c.withValues(alpha: a), surface);
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: tint(primary, isDark ? 0.24 : 0.12),
      onPrimaryContainer: isDark
          ? const Color(0xFFEDE7FF)
          : const Color(0xFF2E1065),
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: tint(secondary, isDark ? 0.20 : 0.14),
      onSecondaryContainer: isDark
          ? const Color(0xFFCCFBF1)
          : const Color(0xFF134E4A),
      tertiary: accentPink,
      onTertiary: Colors.white,
      error: liveRed,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceDim: scaffoldBackground,
      surfaceBright: surfaceElevated,
      surfaceContainerLowest: scaffoldBackground,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest: surfaceElevated,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black,
      // Yükseltilmiş yüzeylere mor ton binmesin; antrasit nötr kalsın.
      surfaceTint: Colors.transparent,
      inverseSurface: isDark
          ? const Color(0xFFF1F1F6)
          : const Color(0xFF1C1C24),
      onInverseSurface: isDark
          ? const Color(0xFF111118)
          : const Color(0xFFF1F1F6),
      inversePrimary: isDark
          ? const Color(0xFF6D28D9)
          : const Color(0xFFC4B5FD),
    );
  }
}
