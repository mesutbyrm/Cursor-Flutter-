import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';

/// Fal kartı — Pro Glass (blur + cam kenarlık).
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
    return ProGlassCard(
      padding: padding,
      elevated: elevated,
      onTap: onTap,
      blur: elevated ? 20 : 14,
      animateIn: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
