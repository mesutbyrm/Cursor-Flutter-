import 'package:flutter/material.dart';

/// Sesli sohbet — Premium 2026 (TikTok Live / Yalla / WePlay).
abstract final class VoiceRoomTokens {
  static const Color bgDeep = Color(0xFF05050D);
  static const Color bgCosmic = Color(0xFF0B0E1A);
  static const Color neonPurple = Color(0xFF9B4DFF);
  static const Color neonBlue = Color(0xFF00D2FF);
  static const Color neonPink = Color(0xFFFF2D7A);
  static const Color gold = Color(0xFFFFD54F);
  static const Color goldDeep = Color(0xFFE6A817);

  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A0B3D),
      Color(0xFF0D0820),
      Color(0xFF05050D),
    ],
  );

  static const LinearGradient roomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1458), bgDeep],
  );

  static const LinearGradient neonRing = LinearGradient(
    colors: [neonPink, neonPurple, neonBlue],
  );

  static const LinearGradient goldRing = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3B0), gold, goldDeep, Color(0xFFB8860B)],
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [Color(0xFFB832FF), Color(0xFF6B2DFF)],
  );

  static const LinearGradient micFabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE040FF), Color(0xFF7C4DFF), Color(0xFF512DA8)],
  );

  static const LinearGradient followGradient = LinearGradient(
    colors: [neonPink, Color(0xFFB832FF)],
  );

  static const LinearGradient titleGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFE8D4FF)],
  );

  static BorderRadius sheetRadius = const BorderRadius.vertical(
    top: Radius.circular(28),
  );

  static const double radiusCard = 24;
  static const double radiusPill = 999;

  static List<BoxShadow> neonGlow(Color c, {double blur = 20}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.55),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];

  static List<BoxShadow> goldGlow({double blur = 24}) => neonGlow(gold, blur: blur);

  static BoxDecoration glassCard({double radius = radiusCard}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static const List<VoiceCategoryDef> discoverCategories = [
    VoiceCategoryDef(
      id: 'night',
      label: 'Gece Muhabbeti',
      icon: Icons.nightlight_round,
      gradient: [Color(0xFF5B7CFF), Color(0xFF1E3A8A)],
    ),
    VoiceCategoryDef(
      id: 'game',
      label: 'Oyun',
      icon: Icons.sports_esports_rounded,
      gradient: [Color(0xFF00E5C3), Color(0xFF00695C)],
    ),
    VoiceCategoryDef(
      id: 'fortune',
      label: 'Fal & Tarot',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFFFFD54F), Color(0xFFB8860B)],
    ),
    VoiceCategoryDef(
      id: 'music',
      label: 'Müzik',
      icon: Icons.music_note_rounded,
      gradient: [Color(0xFFFF2D7A), Color(0xFF9B4DFF)],
    ),
    VoiceCategoryDef(
      id: 'pk',
      label: 'PK',
      icon: Icons.flash_on_rounded,
      gradient: [Color(0xFFFF6B35), Color(0xFFB832FF)],
    ),
    VoiceCategoryDef(
      id: 'vip',
      label: 'VIP',
      icon: Icons.workspace_premium_rounded,
      gradient: [Color(0xFFFFE082), Color(0xFFFF8F00)],
    ),
    VoiceCategoryDef(
      id: 'entertainment',
      label: 'Eğlence',
      icon: Icons.celebration_rounded,
      gradient: [Color(0xFF7C4DFF), Color(0xFF512DA8)],
    ),
    VoiceCategoryDef(
      id: 'flirt',
      label: 'Flört',
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFFFF5C8A), Color(0xFF9C27B0)],
    ),
  ];
}

class VoiceCategoryDef {
  const VoiceCategoryDef({
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
