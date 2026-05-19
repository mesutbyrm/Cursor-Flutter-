import 'package:flutter/material.dart';

/// Pixel tasarım token'ları — keşfet ana sayfa.
abstract final class AppDesign {
  static const Color bgBase = Color(0xFF0B0B1E);
  static const Color bgPurpleGlow = Color(0xFF1A0F3D);
  static const Color bgBlueGlow = Color(0xFF0A1A2E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);
  static const Color textMuted = Color(0xFF6E6E82);

  static const Color accentPink = Color(0xFFFF2D9A);
  static const Color accentPurple = Color(0xFFB832FF);
  static const Color accentCyan = Color(0xFF25F4EE);
  static const Color liveRed = Color(0xFFFF3B5C);
  static const Color onlineGreen = Color(0xFF3DFF6E);

  static const double radiusCard = 22;
  static const double radiusChip = 14;
  static const double liveCardWidth = 160;
  static const double liveCardHeight = 220;
  static const double quickActionSize = 88;
  static const double orbSize = 88;

  static const LinearGradient heroGradient = LinearGradient(
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
