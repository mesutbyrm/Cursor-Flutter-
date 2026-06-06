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
          if (trailing != null) trailing!,
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
