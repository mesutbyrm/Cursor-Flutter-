import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium canlı yayın ana sayfa — neon, cam, altın aksanlar.
abstract final class PremiumLiveTheme {
  static const Color voidBlack = Color(0xFF050210);
  static const Color deepPurple = Color(0xFF12081E);
  static const Color nebula = Color(0xFF1A0F2E);
  static const Color neonPink = Color(0xFFFF2D7A);
  static const Color neonPurple = Color(0xFFB400FF);
  static const Color neonBlue = Color(0xFF4FACFE);
  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color neonGold = Color(0xFFFFD166);
  static const Color cosmicPurple = Color(0xFF4A2F7A);
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color textMuted = Color(0xFFB0A8C9);

  static LinearGradient get backdropGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E1040),
          Color(0xFF0D0618),
          Color(0xFF050210),
        ],
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get heroTitleGradient => const LinearGradient(
        colors: [neonPink, neonPurple, neonBlue],
      );

  static LinearGradient actionGradient(int index) {
    const pairs = <List<Color>>[
      [Color(0xFFFF2D7A), Color(0xFFFF6B9D)],
      [Color(0xFF7B2CBF), Color(0xFFB388FF)],
      [Color(0xFFFF8A00), Color(0xFFFFC107)],
      [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      [Color(0xFF00F5D4), Color(0xFF00BBF9)],
    ];
    final c = pairs[index % pairs.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: c,
    );
  }

  static TextStyle displaySm(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.4,
        color: Colors.white,
      );

  static TextStyle bodyMuted(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
      );

  static TextStyle labelStrong(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      );
}
