import 'package:flutter/material.dart';

/// Keşfet kategori tanımları (PART 2).
class DiscoverCategoryDef {
  const DiscoverCategoryDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<Color> gradient;
}

abstract final class DiscoverCategories {
  static const all = <DiscoverCategoryDef>[
    DiscoverCategoryDef(
      id: 'night',
      label: 'Gece Muhabbeti',
      icon: Icons.nightlight_round,
      gradient: [Color(0xFF5B7CFF), Color(0xFF1E3A8A)],
    ),
    DiscoverCategoryDef(
      id: 'game',
      label: 'Oyun',
      icon: Icons.sports_esports_rounded,
      gradient: [Color(0xFF00E5C3), Color(0xFF00695C)],
    ),
    DiscoverCategoryDef(
      id: 'fortune',
      label: 'Fal & Tarot',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFFFFD54F), Color(0xFFB8860B)],
    ),
    DiscoverCategoryDef(
      id: 'music',
      label: 'Müzik',
      icon: Icons.music_note_rounded,
      gradient: [Color(0xFFFF2D7A), Color(0xFF9B4DFF)],
    ),
    DiscoverCategoryDef(
      id: 'pk',
      label: 'PK',
      icon: Icons.flash_on_rounded,
      gradient: [Color(0xFFFF6B35), Color(0xFFB832FF)],
    ),
    DiscoverCategoryDef(
      id: 'vip',
      label: 'VIP',
      icon: Icons.workspace_premium_rounded,
      gradient: [Color(0xFFFFE082), Color(0xFFFF8F00)],
    ),
    DiscoverCategoryDef(
      id: 'entertainment',
      label: 'Eğlence',
      icon: Icons.celebration_rounded,
      gradient: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
    ),
    DiscoverCategoryDef(
      id: 'flirt',
      label: 'Flört',
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFFFF5C8A), Color(0xFF9C27B0)],
    ),
  ];
}
