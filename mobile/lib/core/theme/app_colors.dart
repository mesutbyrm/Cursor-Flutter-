import 'package:flutter/material.dart';

import 'app_theme_colors.dart';
import 'canlifal_brand_colors.dart';

/// Marka ve semantik renkler — yüzey/metin için [AppThemeColors] / `context.colors`.
abstract final class AppColors {
  static const Color accentPink = AppThemeColors.accentPink;
  static const Color accentPurple = AppThemeColors.accentPurple;
  static const Color accentCyan = AppThemeColors.accentCyan;
  static const Color liveRed = AppThemeColors.liveRed;
  static const Color onlineGreen = AppThemeColors.onlineGreen;
  static const Color diamondBlue = AppThemeColors.diamondBlue;
  static const Color coinGold = AppThemeColors.coinGold;
  static const Color warning = Color(0xFFFFB347);

  // Geriye dönük koyu sabitler (yeni kod: context.colors)
  static const Color background = CanlifalBrandColors.ink;
  static const Color backgroundElevated = CanlifalBrandColors.anthracite;
  static const Color surface = CanlifalBrandColors.anthracite;
  static const Color surfaceElevated = CanlifalBrandColors.anthraciteRaised;
  static const Color surfaceGlass = Color(0xCC121218);
  static const Color bgPurpleGlow = Color(0xFF1A0F3D);
  static const Color bgBlueGlow = Color(0xFF0A1A2E);
  static const Color textPrimary = CanlifalBrandColors.textPrimary;
  static const Color textSecondary = CanlifalBrandColors.textSecondary;
  static const Color textMuted = CanlifalBrandColors.textMuted;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentPink, accentPurple],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4EC8), Color(0xFFD52DFF)],
  );

  static const LinearGradient coinCapsuleGradient = LinearGradient(
    colors: [Color(0xFF2A1548), Color(0xFF1A0F32)],
  );

  static List<BoxShadow> glowShadow(Color color, {double blur = 24}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: blur,
        ),
      ];
}
