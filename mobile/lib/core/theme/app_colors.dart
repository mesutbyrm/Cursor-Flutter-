import 'package:flutter/material.dart';

/// Tek renk kaynağı — TikTok × Bigo × Discord × Instagram premium koyu palet.
abstract final class AppColors {
  // Surfaces
  static const Color background = Color(0xFF0B0B1E);
  static const Color backgroundElevated = Color(0xFF12121F);
  static const Color surface = Color(0xFF14141C);
  static const Color surfaceElevated = Color(0xFF1C1C26);
  static const Color surfaceGlass = Color(0xCC12121F);

  // Glow backgrounds (discover)
  static const Color bgPurpleGlow = Color(0xFF1A0F3D);
  static const Color bgBlueGlow = Color(0xFF0A1A2E);

  // Brand accents (unified pink — eski AppTheme #FE2C55 ile uyumlu)
  static const Color accentPink = Color(0xFFFE2C55);
  static const Color accentPurple = Color(0xFFB832FF);
  static const Color accentCyan = Color(0xFF25F4EE);

  // Semantic
  static const Color liveRed = Color(0xFFFF3B5C);
  static const Color onlineGreen = Color(0xFF3DFF6E);
  static const Color diamondBlue = Color(0xFF5B8CFF);
  static const Color coinGold = Color(0xFFFFD54F);
  static const Color warning = Color(0xFFFFB347);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);
  static const Color textMuted = Color(0xFF6E6E82);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentPink, accentPurple],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF4EC8), Color(0xFFD52DFF)],
  );

  static const LinearGradient coinCapsuleGradient = LinearGradient(
    colors: [Color(0xFF2A1548), Color(0xFF1A0F32)],
  );

  static List<BoxShadow> glowShadow(Color color, {double blur = 24}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];
}
