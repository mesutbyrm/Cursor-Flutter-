import 'dart:ui';

import 'package:flutter/material.dart';

/// Pixel tokens — Sesli Odalar Premium 2026 (referans görsel).
abstract final class VoiceRoomsUiTokens {
  static const Color bgAmoled = Color(0xFF050505);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF6B6B6B);

  static const Color purpleStart = Color(0xFF8E2DE2);
  static const Color purpleEnd = Color(0xFF4A00E0);
  static const Color purpleGlow = Color(0xFFB832FF);
  static const Color magenta = Color(0xFFE040FB);
  static const Color teal = Color(0xFF00BFA5);
  static const Color coral = Color(0xFFFF5252);
  static const Color orange = Color(0xFFFF9100);
  static const Color blue = Color(0xFF448AFF);
  static const Color onlineGreen = Color(0xFF3DFF6E);
  static const Color badgeRed = Color(0xFFFF3B5C);
  static const Color gold = Color(0xFFFFD54F);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleStart, purpleEnd],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE040FF), Color(0xFF7C4DFF), Color(0xFF512DA8)],
  );

  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  static const double padScreenH = 16;
  static const double padSection = 20;
  static const double gapXs = 6;
  static const double gapSm = 8;
  static const double gapMd = 12;
  static const double gapLg = 16;

  static List<BoxShadow> glowShadow(Color color, {double blur = 24, double spread = 0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.55),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];

  static List<BoxShadow> purpleGlowShadow({double blur = 28}) =>
      glowShadow(purpleGlow, blur: blur, spread: 2);

  static BoxDecoration glass({
    double radius = radiusMd,
    Color? tint,
    Border? border,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: (tint ?? Colors.white).withValues(alpha: 0.07),
        border: border ??
            Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: purpleGlow.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static Widget glassBlur({
    required Widget child,
    double radius = radiusMd,
    double sigma = 18,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding,
          decoration: decoration ?? glass(radius: radius),
          child: child,
        ),
      ),
    );
  }
}
