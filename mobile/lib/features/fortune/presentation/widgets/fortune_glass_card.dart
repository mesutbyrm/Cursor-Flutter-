import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/premium_2026/liquid_glass.dart';

/// Fal kartı — Liquid Glass (2026).
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
    final border = accent ?? AppColors.accentPurple;
    return LiquidGlass(
      padding: padding,
      elevated: elevated,
      onTap: onTap,
      blur: elevated ? 24 : 18,
      gradientBorder: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          border.withValues(alpha: 0.55),
          border.withValues(alpha: 0.15),
        ],
      ),
      child: child,
    );
  }
}
