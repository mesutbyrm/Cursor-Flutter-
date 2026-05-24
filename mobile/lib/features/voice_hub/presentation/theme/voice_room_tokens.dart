import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Sesli sohbet odası — premium koyu / neon tasarım jetonları.
abstract final class VoiceRoomTokens {
  static const Color bgDeep = Color(0xFF0B0E14);
  static const Color neonPurple = Color(0xFF8A2BE2);
  static const Color neonBlue = Color(0xFF00D2FF);
  static const Color neonPink = AppColors.accentPink;

  static const LinearGradient roomGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0F3D), VoiceRoomTokens.bgDeep],
  );

  static const LinearGradient neonRing = LinearGradient(
    colors: [neonPink, neonPurple, neonBlue],
  );

  static const LinearGradient fabGradient = LinearGradient(
    colors: [Color(0xFFB832FF), Color(0xFF6B2DFF)],
  );

  static BorderRadius sheetRadius = const BorderRadius.vertical(
    top: Radius.circular(28),
  );

  static List<BoxShadow> neonGlow(Color c, {double blur = 20}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.55),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];
}
