import 'dart:ui';

import 'package:flutter/material.dart';

import 'home_approved_design.dart';

/// Ana sayfa V1 premium tasarım token'ları (2026).
abstract final class HomePremiumDesign {
  static const background = Color(0xFF070A12);
  static const surface = Color(0xFF111827);
  static const surfaceElevated = Color(0xFF1A2234);
  static const glassFill = Color(0x14FFFFFF);
  static const glassBorder = Color(0x28FFFFFF);
  static const accent = Color(0xFF8B5CF6);
  static const accentMuted = Color(0xFF6D28D9);

  static const sectionTitleSize = 20.0;
  static const cardTitleSize = 15.0;
  static const secondarySize = 12.0;

  static const cardRadius = 16.0;
  static const chipRadius = 14.0;

  static BoxDecoration glassCard({
    Color? tint,
    double radius = cardRadius,
    Border? border,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: tint ?? surface,
      border: border ??
          Border.all(
            color: glassBorder,
            width: 1,
          ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static Widget glassBackdrop({
    required Widget child,
    double sigma = 8,
    double radius = cardRadius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }

  static TextStyle sectionTitleStyle = const TextStyle(
    fontSize: sectionTitleSize,
    fontWeight: FontWeight.w800,
    color: HomeApprovedDesign.textPrimary,
    letterSpacing: -0.35,
    height: 1.15,
  );

  static TextStyle actionLabelStyle = TextStyle(
    fontSize: secondarySize,
    fontWeight: FontWeight.w700,
    color: accent.withValues(alpha: 0.95),
  );
}
