import 'package:flutter/material.dart';

/// Tanış Kaynaş 2026 renkleri — koyu tema referans tasarım, açık temada
/// aynı bileşenler açık cam yüzeylerle çizilir. Renkler tek yerden gelir.
@immutable
class TkPalette {
  const TkPalette._({
    required this.isDark,
    required this.background,
    required this.backgroundTop,
    required this.glass,
    required this.glassStrong,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
  });

  final bool isDark;
  final Color background;
  final Color backgroundTop;
  final Color glass;
  final Color glassStrong;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textFaint;

  static const pink = Color(0xFFFF3D8B);
  static const magenta = Color(0xFFE63BD6);
  static const purple = Color(0xFF8B5CF6);
  static const blue = Color(0xFF3B82F6);
  static const cyan = Color(0xFF22D3EE);
  static const online = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF4D8D), Color(0xFFE63BD6)],
  );
  static const ctaGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
  );
  static const ringGradient = SweepGradient(
    colors: [pink, purple, blue, cyan, pink],
  );

  static const _dark = TkPalette._(
    isDark: true,
    background: Color(0xFF0B0A1E),
    backgroundTop: Color(0xFF17123A),
    glass: Color(0x1AFFFFFF),
    glassStrong: Color(0x26FFFFFF),
    border: Color(0x26FFFFFF),
    text: Colors.white,
    textMuted: Color(0xFFC9C3E6),
    textFaint: Color(0xFF8E88B0),
  );

  static const _light = TkPalette._(
    isDark: false,
    background: Color(0xFFF6F3FF),
    backgroundTop: Color(0xFFEDE6FF),
    glass: Color(0xB3FFFFFF),
    glassStrong: Color(0xE6FFFFFF),
    border: Color(0x1F5B21B6),
    text: Color(0xFF1B1530),
    textMuted: Color(0xFF4B4466),
    textFaint: Color(0xFF7A7396),
  );

  static TkPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}
