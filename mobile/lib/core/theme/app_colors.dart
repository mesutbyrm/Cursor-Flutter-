import 'package:flutter/material.dart';

import 'app_theme_colors.dart';

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
  static const Color background = Color(0xFF0B0B1E);
  static const Color backgroundElevated = Color(0xFF12121F);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C26);
  static const Color surfaceGlass = Color(0xCC12121F);
  static const Color bgPurpleGlow = Color(0xFF1A0F3D);
  static const Color bgBlueGlow = Color(0xFF0A1A2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);
  static const Color textMuted = Color(0xFF6E6E82);

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
