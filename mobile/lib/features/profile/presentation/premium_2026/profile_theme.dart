import 'package:flutter/material.dart';

/// Premium 2026 profil — dark purple + glass tasarım sabitleri.
abstract final class ProfilePremiumTheme {
  static const radiusLg = 26.0;
  static const radiusMd = 22.0;
  static const radiusSm = 18.0;

  static const coverHeight = 148.0;
  static const avatarSize = 108.0;

  static const neonPurple = Color(0xFFB832FF);
  static const neonPink = Color(0xFFFF4D9D);
  static const deepBg = Color(0xFF0A0612);
  static const glassBorder = Color(0x33B832FF);

  static LinearGradient coverGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1048), Color(0xFF12081F), Color(0xFF050308)],
  );

  static LinearGradient premiumGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFF6F00), Color(0xFFB832FF)],
  );

  static BoxDecoration glassDecoration({Color? border}) => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: border ?? glassBorder, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: neonPurple.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
