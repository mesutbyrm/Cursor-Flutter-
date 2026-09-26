import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/theme/canlifal_brand_colors.dart';

/// Onaylı ana sayfa mockup — sabit ölçü ve renkler.
abstract final class HomeApprovedDesign {
  static const background = CanlifalBrandColors.ink;
  static const surface = CanlifalBrandColors.anthracite;
  static const searchFill = CanlifalBrandColors.anthraciteContainer;
  static const border = CanlifalBrandColors.hairline;

  static const purple = CanlifalBrandColors.violet;
  static const pink = Color(0xFFFF007F);
  static const gold = Color(0xFFFFD700);
  static const liveRed = Color(0xFFFF2D55);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFFF9500);

  static const textPrimary = CanlifalBrandColors.textPrimary;
  static const textSecondary = CanlifalBrandColors.textSecondary;
  static const textMuted = CanlifalBrandColors.textMuted;

  static const hPad = 16.0;
  static const cardRadius = 20.0;
  static const searchRadius = 20.0;
  static const pillRadius = 20.0;

  static const liveCardW = 132.0;
  static const liveCardH = 176.0; // 3:4
  static const voiceCardW = 300.0;
  static const voiceCardH = 100.0;
  static const trendThumb = 120.0;
  static const fortuneCardW = 100.0;
  static const fortuneCardH = 120.0;
  static const tellerCardW = 132.0;
  static const tellerCardH = 176.0; // canlı yayın kartı ile aynı oran (3:4)
  static const storySize = 68.0;

  static const brandGradient = LinearGradient(
    colors: [Color(0xFFFF007F), Color(0xFFE9D5FF), Color(0xFFFFFFFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const storyRingGradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const liveGlow = BoxShadow(
    color: Color(0x388B5CF6),
    blurRadius: 14,
    spreadRadius: 0,
    offset: Offset(0, 3),
  );

  static const sectionTitleSize = 20.0;
  static const cardTitleSize = 15.0;

  // Temaya duyarlı karşılıklar — sayfa zemini üzerindeki metin/yüzeyler için.
  // Görsel veya koyu gradyan üzerindeki metinler sabit açık renk kalmalı.
  static Color textPrimaryOf(BuildContext context) =>
      context.isDarkTheme ? textPrimary : context.colors.onSurface;

  static Color textSecondaryOf(BuildContext context) =>
      context.isDarkTheme ? textSecondary : context.colors.onSurfaceVariant;

  static Color textMutedOf(BuildContext context) =>
      context.isDarkTheme ? textMuted : context.colors.onSurfaceMuted;

  static Color surfaceOf(BuildContext context) =>
      context.isDarkTheme ? surface : context.colors.surface;

  static Color searchFillOf(BuildContext context) =>
      context.isDarkTheme ? searchFill : context.colors.surfaceContainer;

  static Color borderOf(BuildContext context) =>
      context.isDarkTheme ? border : context.colors.outlineVariant;
}
