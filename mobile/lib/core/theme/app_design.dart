import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Geriye dönük uyumluluk — yeni kod `AppColors` / `context.tokens` kullanmalı.
abstract final class AppDesign {
  static const Color bgBase = AppColors.background;
  static const Color bgPurpleGlow = AppColors.bgPurpleGlow;
  static const Color bgBlueGlow = AppColors.bgBlueGlow;

  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;

  static const Color accentPink = AppColors.accentPink;
  static const Color accentPurple = AppColors.accentPurple;
  static const Color accentCyan = AppColors.accentCyan;
  static const Color liveRed = AppColors.liveRed;
  static const Color onlineGreen = AppColors.onlineGreen;
  static const Color diamondBlue = AppColors.diamondBlue;
  static const Color coinGold = AppColors.coinGold;

  static const double radiusCard = AppSpacing.radiusLg;
  static const double radiusChip = AppSpacing.radiusMd;
  static const double liveCardWidth = AppSpacing.liveCardWidth;
  static const double liveCardHeight = AppSpacing.liveCardHeight;
  static const double quickActionSize = AppSpacing.quickActionSize;
  static const double orbSize = AppSpacing.orbSize;

  static const LinearGradient heroGradient = AppColors.brandGradient;
  static const LinearGradient fabGradient = AppColors.fabGradient;
  static const LinearGradient coinCapsuleGradient = AppColors.coinCapsuleGradient;

  static List<BoxShadow> glowShadow(Color color, {double blur = 24}) =>
      AppColors.glowShadow(color, blur: blur);
}
