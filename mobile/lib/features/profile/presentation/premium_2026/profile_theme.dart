import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/theme/canlifal_brand_colors.dart';

/// Premium 2026 profil — dark purple + glass tasarım sabitleri.
abstract final class ProfilePremiumTheme {
  static const radiusLg = 26.0;
  static const radiusMd = 22.0;
  static const radiusSm = 18.0;

  /// Kapak kısa tutulur; avatar kapak üzerine biner (aşağı kayma hissi olmasın).
  static const coverHeight = 96.0;
  static const avatarSize = 108.0;
  static const avatarOverlap = 36.0;

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

  // ── Temaya duyarlı karşılıklar ──────────────────────────────────────────
  // Koyu temada mevcut "koyu cam" görünüm korunur; açık temada beyaz kart +
  // ince kenar + koyu metin. Renkli/gradyanlı yüzeylerdeki metin beyaz kalır.

  static bool _dark(BuildContext c) => c.isDarkTheme;

  /// Kart dolgusu ([deepBg] yarı saydam yerine).
  static Color surfaceOf(BuildContext c, {double darkAlpha = 0.55}) =>
      _dark(c) ? deepBg.withValues(alpha: darkAlpha) : c.colors.surface;

  /// Kart içindeki ikincil yüzey (çip, satır zemini).
  static Color insetOf(BuildContext c, {double darkAlpha = 0.06}) => _dark(c)
      ? Colors.white.withValues(alpha: darkAlpha)
      : c.colors.surfaceContainer;

  static Color borderOf(BuildContext c) =>
      _dark(c) ? glassBorder : c.colors.outlineVariant;

  static Color textOf(BuildContext c) =>
      _dark(c) ? Colors.white : c.colors.onSurface;

  static Color textSecondaryOf(BuildContext c) => _dark(c)
      ? Colors.white.withValues(alpha: 0.72)
      : c.colors.onSurfaceVariant;

  static Color textMutedOf(BuildContext c) => _dark(c)
      ? Colors.white.withValues(alpha: 0.55)
      : c.colors.onSurfaceMuted;

  /// Küçük metin/ikon vurgusu — açık temada koyu mor (okunur).
  static Color accentOf(BuildContext c) =>
      _dark(c) ? neonPurple : CanlifalBrandColors.violetStrong;

  static List<BoxShadow>? shadowOf(BuildContext c) =>
      _dark(c) ? null : c.colors.cardShadow;

  /// [glassDecoration]'ın temaya duyarlı hali.
  static BoxDecoration glassDecorationOf(BuildContext c, {Color? border}) =>
      _dark(c)
          ? glassDecoration(border: border)
          : BoxDecoration(
              borderRadius: BorderRadius.circular(radiusMd),
              color: c.colors.surface,
              border: Border.all(color: border ?? c.colors.outlineVariant),
              boxShadow: c.colors.cardShadow,
            );
}
