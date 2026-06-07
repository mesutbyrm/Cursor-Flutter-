import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_theme_colors.dart';

/// Geriye dönük uyumluluk — yeni kod `context.colors` / `context.palette` kullanmalı.
abstract final class AppDesign {
  static const Color bgBase = Color(0xFF0B0B1E);
  static const Color bgPurpleGlow = Color(0xFF16162A);
  static const Color bgBlueGlow = Color(0xFF16162A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);
  static const Color textMuted = Color(0xFF6E6E82);

  static const Color accentPink = AppThemeColors.accentPink;
  static const Color accentPurple = AppThemeColors.accentPurple;
  static const Color accentCyan = AppThemeColors.accentCyan;
  static const Color liveRed = AppThemeColors.liveRed;
  static const Color onlineGreen = AppThemeColors.onlineGreen;
  static const Color diamondBlue = AppThemeColors.diamondBlue;
  static const Color coinGold = AppThemeColors.coinGold;

  static const double radiusCard = AppSpacing.radiusLg;
  static const double radiusChip = AppSpacing.radiusMd;
  static const double liveCardWidth = AppSpacing.liveCardWidth;
  static const double liveCardHeight = AppSpacing.liveCardHeight;
  static const double quickActionSize = AppSpacing.quickActionSize;
  static const double orbSize = AppSpacing.orbSize;

  static const LinearGradient heroGradient = LinearGradient(
    colors: [AppThemeColors.accentPink, AppThemeColors.accentPurple],
  );
  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4EC8), Color(0xFFD52DFF)],
  );
  static const LinearGradient coinCapsuleGradient = LinearGradient(
    colors: [Color(0xFF2A1548), Color(0xFF1A0F32)],
  );

  static List<BoxShadow> glowShadow(Color color, {double blur = 24}) =>
      AppThemeColors.glowShadow(color, blur: blur);
}
