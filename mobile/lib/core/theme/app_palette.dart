import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema-duyarlı yüzey ve metin renkleri — `Theme.of(context).extension`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.divider,
    required this.glassOverlay,
    required this.iconMuted,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color divider;
  final Color glassOverlay;
  final Color iconMuted;

  static const dark = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    divider: Color(0xFF2A2A38),
    glassOverlay: Color(0x8C0B0B1E),
    iconMuted: AppColors.textMuted,
  );

  static const light = AppPalette(
    background: Color(0xFFF8F8FC),
    surface: Colors.white,
    surfaceElevated: Color(0xFFF0F0F5),
    textPrimary: Color(0xFF0B0B1E),
    textSecondary: Color(0xFF3D3D52),
    textMuted: Color(0xFF6E6E82),
    divider: Color(0xFFE5E5EA),
    glassOverlay: Color(0x99FFFFFF),
    iconMuted: Color(0xFF8E8E93),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? divider,
    Color? glassOverlay,
    Color? iconMuted,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      iconMuted: iconMuted ?? this.iconMuted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
