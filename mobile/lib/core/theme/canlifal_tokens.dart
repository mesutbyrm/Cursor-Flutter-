import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

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
    brandGradient: AppColors.brandGradient,
    fabGradient: AppColors.fabGradient,
    coinGradient: AppColors.coinCapsuleGradient,
    navBarBackground: AppColors.surfaceGlass,
    glassBorder: Color(0x40B832FF),
    liveBadgeColor: AppColors.liveRed,
    radiusCard: AppSpacing.radiusLg,
    radiusChip: AppSpacing.radiusMd,
  );

  static const light = CanlifalTokens(
    brandGradient: LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
    ),
    fabGradient: AppColors.fabGradient,
    coinGradient: LinearGradient(
      colors: [Color(0xFFF3E8FF), Color(0xFFE8DEF8)],
    ),
    navBarBackground: Color(0xF5FFFFFF),
    glassBorder: Color(0x339C27B0),
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
    return CanlifalTokens(
      brandGradient: brandGradient,
      fabGradient: fabGradient,
      coinGradient: coinGradient,
      navBarBackground: Color.lerp(navBarBackground, other.navBarBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      liveBadgeColor: Color.lerp(liveBadgeColor, other.liveBadgeColor, t)!,
      radiusCard: radiusCard,
      radiusChip: radiusChip,
    );
  }
}

extension CanlifalTokensX on BuildContext {
  CanlifalTokens get tokens =>
      Theme.of(this).extension<CanlifalTokens>() ?? CanlifalTokens.dark;
}
