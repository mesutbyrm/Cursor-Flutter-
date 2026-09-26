import 'package:flutter/material.dart';
import '../../../../core/theme/canlifal_brand_colors.dart';

/// Ana sayfa tasarım token'ları (2026).
abstract final class HomePalette {
  static const darkBackground = CanlifalBrandColors.ink;
  static const lightBackground = CanlifalBrandColors.paper;
  static const lightSurface = Color(0xFFF8F8FC);

  static const primary = CanlifalBrandColors.violet;
  static const secondary = CanlifalBrandColors.turquoise;
  static const accentGold = Color(0xFFFFD700);

  static const radiusCard = 24.0;
  static const radiusPill = 999.0;

  static const glassFill = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
}
