import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

/// Material [ThemeExtension] — [AppThemeColors] token seti.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette(this.colors);

  final AppThemeColors colors;

  static final AppPalette dark = AppPalette(AppThemeColors.dark);
  static final AppPalette light = AppPalette(AppThemeColors.light);

  bool get isDark => colors.isDark;
  bool get useGlassBlur => colors.useGlassBlur;

  Color get background => colors.scaffoldBackground;
  Color get surface => colors.surface;
  Color get surfaceElevated => colors.surfaceElevated;
  Color get textPrimary => colors.onSurface;
  Color get textSecondary => colors.onSurfaceVariant;
  Color get textMuted => colors.onSurfaceMuted;
  Color get divider => colors.divider;
  Color get glassOverlay => colors.glassFill;
  Color get iconMuted => colors.onSurfaceMuted;
  Color get glassFill => colors.glassFill;
  Color get glassBorder => colors.glassBorder;

  @override
  AppPalette copyWith({AppThemeColors? colors}) {
    return AppPalette(colors ?? this.colors);
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    final a = colors;
    final b = other.colors;
    return AppPalette(
      AppThemeColors(
        brightness: t < 0.5 ? a.brightness : b.brightness,
        scaffoldBackground:
            Color.lerp(a.scaffoldBackground, b.scaffoldBackground, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        surfaceElevated:
            Color.lerp(a.surfaceElevated, b.surfaceElevated, t)!,
        surfaceContainer:
            Color.lerp(a.surfaceContainer, b.surfaceContainer, t)!,
        onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
        onSurfaceVariant:
            Color.lerp(a.onSurfaceVariant, b.onSurfaceVariant, t)!,
        onSurfaceMuted:
            Color.lerp(a.onSurfaceMuted, b.onSurfaceMuted, t)!,
        primary: Color.lerp(a.primary, b.primary, t)!,
        onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
        secondary: Color.lerp(a.secondary, b.secondary, t)!,
        onSecondary: Color.lerp(a.onSecondary, b.onSecondary, t)!,
        outline: Color.lerp(a.outline, b.outline, t)!,
        outlineVariant:
            Color.lerp(a.outlineVariant, b.outlineVariant, t)!,
        divider: Color.lerp(a.divider, b.divider, t)!,
        glassFill: Color.lerp(a.glassFill, b.glassFill, t)!,
        glassFillElevated:
            Color.lerp(a.glassFillElevated, b.glassFillElevated, t)!,
        glassBorder: Color.lerp(a.glassBorder, b.glassBorder, t)!,
        glassHighlight:
            Color.lerp(a.glassHighlight, b.glassHighlight, t)!,
        dialogBackground:
            Color.lerp(a.dialogBackground, b.dialogBackground, t)!,
        bottomSheetBackground: Color.lerp(
          a.bottomSheetBackground,
          b.bottomSheetBackground,
          t,
        )!,
        snackBarBackground:
            Color.lerp(a.snackBarBackground, b.snackBarBackground, t)!,
        barrier: Color.lerp(a.barrier, b.barrier, t)!,
        brandGradient: t < 0.5 ? a.brandGradient : b.brandGradient,
        cardShadow: t < 0.5 ? a.cardShadow : b.cardShadow,
        elevatedShadow: t < 0.5 ? a.elevatedShadow : b.elevatedShadow,
        useGlassBlur: t < 0.5 ? a.useGlassBlur : b.useGlassBlur,
      ),
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
