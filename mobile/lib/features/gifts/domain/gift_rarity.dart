import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

enum GiftRarity {
  common,
  rare,
  epic,
  legendary,
  mythic;

  static GiftRarity parse(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'rare' => GiftRarity.rare,
      'epic' => GiftRarity.epic,
      'legendary' => GiftRarity.legendary,
      'mythic' => GiftRarity.mythic,
      _ => GiftRarity.common,
    };
  }

  String get label => switch (this) {
        GiftRarity.common => 'Common',
        GiftRarity.rare => 'Rare',
        GiftRarity.epic => 'Epic',
        GiftRarity.legendary => 'Legendary',
        GiftRarity.mythic => 'Mythic',
      };

  Color get glowColor => switch (this) {
        GiftRarity.common => AppThemeColors.dark.onSurfaceMuted,
        GiftRarity.rare => AppThemeColors.diamondBlue,
        GiftRarity.epic => AppThemeColors.accentPurple,
        GiftRarity.legendary => AppThemeColors.coinGold,
        GiftRarity.mythic => AppThemeColors.accentPink,
      };

  Color get borderColor => glowColor.withValues(alpha: 0.85);

  Duration get fullscreenDuration => switch (this) {
        GiftRarity.common => const Duration(seconds: 2),
        GiftRarity.rare => const Duration(seconds: 3),
        GiftRarity.epic => const Duration(seconds: 4),
        GiftRarity.legendary => const Duration(seconds: 5),
        GiftRarity.mythic => const Duration(seconds: 6),
      };
}
