import 'package:flutter/material.dart';

/// Ultra Premium Fal & Tarot — mistik lüks palet (2026 Liquid Glass).
abstract final class UltraFortuneTokens {
  static const electricPurple = Color(0xFF7A2FFF);
  static const softLilac = Color(0xFFB57DFF);
  static const metallicGold = Color(0xFFFFD67A);
  static const deepNight = Color(0xFF050014);
  static const spaceBlack = Color(0xFF030008);
  static const spaceIndigo = Color(0xFF080018);
  static const spaceViolet = Color(0xFF12002B);
  static const glassFill = Color(0x14FFFFFF);

  static const liquidBlur = 42.0;
  static const cardRadius = 32.0;
  static const glassRadius = 24.0;

  static const crystalRotation = Duration(seconds: 20);
  static const nebulaBreath = Duration(seconds: 30);
  static const particleLoop = Duration(seconds: 24);

  static const deepSpaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [spaceBlack, spaceIndigo, spaceViolet],
    stops: [0.0, 0.45, 1.0],
  );

  static const goldTypography = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8E7),
      metallicGold,
      Color(0xFFE8B84A),
      Color(0xFFFFD67A),
    ],
  );

  static const glassBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x66FFFFFF),
      Color(0x1AFFFFFF),
      Color(0x667A2FFF),
      Color(0x4DFFD67A),
    ],
  );

  static List<BoxShadow> purpleGlow({double blur = 32, double spread = 2}) => [
        BoxShadow(
          color: electricPurple.withValues(alpha: 0.35),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> goldGlow({double blur = 24}) => [
        BoxShadow(
          color: metallicGold.withValues(alpha: 0.28),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];
}
