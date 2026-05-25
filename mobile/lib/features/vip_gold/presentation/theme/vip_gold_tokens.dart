import 'package:flutter/material.dart';

/// Luxury gold / VIP tasarım tokenları.
abstract final class VipGoldTokens {
  static const Color bgDeep = Color(0xFF050508);
  static const Color bgCard = Color(0xFF12101A);

  static const Color goldLight = Color(0xFFFFF3B0);
  static const Color goldMid = Color(0xFFFFD54F);
  static const Color goldDeep = Color(0xFFE6A817);
  static const Color goldBronze = Color(0xFFB8860B);

  static const Color diamondBlue = Color(0xFF5B8CFF);
  static const Color svipPurple = Color(0xFF9B4DFF);

  static const LinearGradient goldLuxury = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8E1),
      Color(0xFFFFD54F),
      Color(0xFFFF8F00),
      Color(0xFFE65100),
    ],
  );

  static const LinearGradient goldRadial = RadialGradient(
    colors: [
      Color(0x66FFD54F),
      Color(0x22FFD54F),
      Colors.transparent,
    ],
  );

  static const LinearGradient cardGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x08FFFFFF),
    ],
  );

  static List<BoxShadow> goldGlow({double blur = 24}) => [
        BoxShadow(
          color: goldMid.withValues(alpha: 0.55),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];

  static BoxDecoration luxuryCard({double radius = 20}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: cardGlass,
        border: Border.all(color: goldMid.withValues(alpha: 0.35)),
        boxShadow: goldGlow(blur: 12),
      );
}
