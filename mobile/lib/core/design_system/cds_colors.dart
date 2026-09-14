import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';
import '../theme/app_theme_extensions.dart';

/// CDS renk semantiği — [AppThemeColors] / [context.colors] üzerinden.
abstract final class CdsColors {
  static Color background(BuildContext context) =>
      context.colors.scaffoldBackground;

  static Color surface(BuildContext context) => context.colors.surface;

  static Color surfaceElevated(BuildContext context) =>
      context.colors.surfaceElevated;

  static Color primary(BuildContext context) => context.colors.primary;

  static const Color accentPink = AppThemeColors.accentPink;
  static const Color accentCyan = AppThemeColors.accentCyan;
  static const Color gold = AppThemeColors.coinGold;
  static const Color fortuneMystic = AppThemeColors.accentPurple;
  static const Color liveHot = AppThemeColors.liveRed;
  static const Color error = AppThemeColors.liveRed;
  static const Color success = AppThemeColors.onlineGreen;
}
