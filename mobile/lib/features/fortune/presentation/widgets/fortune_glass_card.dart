import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/themed_glass_card.dart';

/// Fal kartı — tema uyumlu cam yüzey.
class FortuneGlassCard extends StatelessWidget {
  const FortuneGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final border = accent ?? AppThemeColors.accentPurple;
    return ThemedGlassCard(
      padding: padding,
      elevated: elevated,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: border.withValues(alpha: 0.35)),
        ),
        child: child,
      ),
    );
  }
}
