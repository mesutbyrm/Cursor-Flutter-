import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'canlifal_brand_colors.dart';
import 'app_theme_colors.dart';

/// Material 3 ThemeExtension — premium gradient / glow / layout token'ları.
@immutable
class CanlifalTokens extends ThemeExtension<CanlifalTokens> {
  const CanlifalTokens({
    required this.brandGradient,
    required this.fabGradient,
    required this.coinGradient,
    required this.navBarBackground,
    required this.glassBorder,
    required this.liveBadgeColor,
    required this.radiusCard,
    required this.radiusChip,
  });

  final Gradient brandGradient;
  final Gradient fabGradient;
  final Gradient coinGradient;
  final Color navBarBackground;
  final Color glassBorder;
  final Color liveBadgeColor;
  final double radiusCard;
  final double radiusChip;

  static const dark = CanlifalTokens(
    brandGradient: CanlifalBrandColors.primaryGradient,
    fabGradient: CanlifalBrandColors.primaryGradient,
    coinGradient: LinearGradient(
      colors: [Color(0xFF1F1A2C), Color(0xFF15121D)],
    ),
    navBarBackground: Color(0xF50C0C11),
    glassBorder: Color(0x1FFFFFFF),
    liveBadgeColor: AppThemeColors.liveRed,
    radiusCard: AppSpacing.radiusLg,
    radiusChip: AppSpacing.radiusMd,
  );

  static const light = CanlifalTokens(
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        CanlifalBrandColors.violet,
        CanlifalBrandColors.violetStrong,
        CanlifalBrandColors.violetDeep,
      ],
    ),
    fabGradient: CanlifalBrandColors.primaryGradient,
    coinGradient: LinearGradient(
      colors: [Color(0xFFF3EEFF), Color(0xFFE9E2FB)],
    ),
    navBarBackground: Color(0xF7FFFFFF),
    glassBorder: Color(0x1F7C3AED),
    liveBadgeColor: Color(0xFFE53935),
    radiusCard: AppSpacing.radiusLg,
    radiusChip: AppSpacing.radiusMd,
  );

  @override
  CanlifalTokens copyWith({
    Gradient? brandGradient,
    Gradient? fabGradient,
    Gradient? coinGradient,
    Color? navBarBackground,
    Color? glassBorder,
    Color? liveBadgeColor,
    double? radiusCard,
    double? radiusChip,
  }) {
    return CanlifalTokens(
      brandGradient: brandGradient ?? this.brandGradient,
      fabGradient: fabGradient ?? this.fabGradient,
      coinGradient: coinGradient ?? this.coinGradient,
      navBarBackground: navBarBackground ?? this.navBarBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      liveBadgeColor: liveBadgeColor ?? this.liveBadgeColor,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusChip: radiusChip ?? this.radiusChip,
    );
  }

  @override
  CanlifalTokens lerp(ThemeExtension<CanlifalTokens>? other, double t) {
    if (other is! CanlifalTokens) return this;
    return t < 0.5 ? this : other;
  }
}
