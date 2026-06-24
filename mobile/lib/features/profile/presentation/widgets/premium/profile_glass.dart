import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/themed_glass_card.dart';

/// Cam efektli kart — profil bileşenleri ([ThemedGlassCard]).
class ProfileGlass extends StatelessWidget {
  const ProfileGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppSpacing.radiusLg,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.blur = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ThemedGlassCard(
      padding: padding,
      onTap: onTap,
      blur: blur,
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: c.onSurface,
                ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

String profileFormatCount(num value) {
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  }
  if (value >= 10000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

String profileFormatCoins(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Profil ekranı tipografi — okunabilir minimum boyutlar.
abstract final class ProfileTypography {
  static TextStyle pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: context.colors.onSurface,
            height: 1.15,
          ) ??
      TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: context.colors.onSurface,
      );

  static TextStyle displayName(BuildContext context) => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: context.colors.onSurface,
        height: 1.1,
      );

  static TextStyle username(BuildContext context) => TextStyle(
        color: context.colors.onSurfaceMuted,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle statValue(BuildContext context) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        color: context.colors.onSurface,
        height: 1,
      );

  static TextStyle statLabel(BuildContext context) => TextStyle(
        color: context.colors.onSurfaceMuted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle body(BuildContext context) => TextStyle(
        color: context.colors.onSurfaceVariant,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w500,
      );

  static TextStyle cardTitle(BuildContext context) => TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: context.colors.onSurface,
        height: 1.2,
      );

  static TextStyle cardSubtitle(BuildContext context) => TextStyle(
        fontSize: 13,
        color: context.colors.onSurfaceMuted,
        height: 1.4,
        fontWeight: FontWeight.w500,
      );

  static TextStyle actionLabel(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: context.colors.onSurface,
      );
}
