import 'package:flutter/material.dart';

/// Onaylı ana sayfa mockup — sabit ölçü ve renkler.
abstract final class HomeApprovedDesign {
  static const background = Color(0xFF0B0B15);
  static const surface = Color(0xFF14141F);
  static const searchFill = Color(0xFF1A1A24);
  static const border = Color(0xFF2A2A38);

  static const purple = Color(0xFFA020F0);
  static const pink = Color(0xFFFF007F);
  static const gold = Color(0xFFFFD700);
  static const liveRed = Color(0xFFFF2D55);
  static const green = Color(0xFF22C55E);
  static const orange = Color(0xFFFF9500);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0BC);
  static const textMuted = Color(0xFF6B6B7B);

  static const hPad = 16.0;
  static const cardRadius = 14.0;
  static const searchRadius = 12.0;
  static const pillRadius = 20.0;

  static const liveCardW = 132.0;
  static const liveCardH = 176.0; // 3:4
  static const voiceCardW = 300.0;
  static const voiceCardH = 100.0;
  static const trendThumb = 120.0;
  static const fortuneCardW = 100.0;
  static const fortuneCardH = 120.0;
  static const storySize = 68.0;

  static const brandGradient = LinearGradient(
    colors: [Color(0xFFFF007F), Color(0xFFE9D5FF), Color(0xFFFFFFFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const storyRingGradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const liveGlow = BoxShadow(
    color: Color(0x66A020F0),
    blurRadius: 14,
    spreadRadius: 0,
    offset: Offset(0, 4),
  );
}
