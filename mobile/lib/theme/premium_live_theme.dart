import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mockup referansına yakın palet (koyu zemin, neon pembe/mor/mavi).
abstract final class PremiumLiveTheme {
  /// Mockup: çok koyu lacivert/siyah.
  static const Color voidBlack = Color(0xFF0D0B14);
  static const Color deepPurple = Color(0xFF12081E);
  static const Color nebula = Color(0xFF1A0F2E);
  /// Birincil mor — mockup #6A1B9A.
  static const Color primaryViolet = Color(0xFF6A1B9A);
  /// Neon pembe — mockup #FF4081.
  static const Color neonPink = Color(0xFFFF4081);
  static const Color neonPurple = Color(0xFFE040FB);
  static const Color neonBlue = Color(0xFF4FACFE);
  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color neonGold = Color(0xFFFFD166);
  static const Color cosmicPurple = Color(0xFF4A2F7A);
  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color textMuted = Color(0xFFB0A8C9);

  static LinearGradient get backdropGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2D1B4E),
          Color(0xFF151018),
          voidBlack,
        ],
        stops: [0.0, 0.42, 1.0],
      );

  static LinearGradient get heroTitleGradient => const LinearGradient(
        colors: [
          Color(0xFFFF4081),
          Color(0xFFE040FB),
          Color(0xFF4FACFE),
        ],
      );

  static LinearGradient actionGradient(int index) {
    const pairs = <List<Color>>[
      [Color(0xFFFF4081), Color(0xFFFF6B9D)],
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
      GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.4,
        color: Colors.white,
      );

  static TextStyle bodyMuted(BuildContext context) =>
      GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
      );

  static TextStyle labelStrong(BuildContext context) =>
      GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      );
}
