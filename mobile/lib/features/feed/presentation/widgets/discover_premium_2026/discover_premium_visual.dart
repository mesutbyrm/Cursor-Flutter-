import 'package:flutter/material.dart';

/// Keşfet ana sayfa — 2026 premium görsel sabitleri (yapı değişmez).
abstract final class DiscoverPremiumVisual {
  static const primary = Color(0xFF7B2FF7);
  static const secondary = Color(0xFFB84DFF);
  static const accent = Color(0xFFFF4FD8);

  static const backgroundTop = Color(0xFF1A0E38);
  static const backgroundMid = Color(0xFF12082A);
  static const backgroundBottom = Color(0xFF0A0618);

  /// Kart köşeleri — tüm keşfet kartları.
  static const cardRadius = 24.0;

  /// Gerçek cam efekti.
  static const glassBlur = 24.0;
  static const glassFill = Color(0x1FFFFFFF);
  static const glassBorder = Color(0x33FFFFFF);

  static List<BoxShadow> cardGlow({Color? color, bool pressed = false}) => [
        BoxShadow(
          color: (color ?? primary).withValues(alpha: pressed ? 0.45 : 0.28),
          blurRadius: pressed ? 28 : 18,
          spreadRadius: pressed ? -2 : -4,
          offset: const Offset(0, 10),
        ),
        const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary, accent],
  );

  static const meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundTop, backgroundMid, backgroundBottom],
  );
}
