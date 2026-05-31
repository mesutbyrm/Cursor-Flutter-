import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Cam efektli fal kartı — mockup glassmorphism.
class FortuneGlassCard extends StatelessWidget {
  const FortuneGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = accent ?? AppColors.accentPurple;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                border.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
            border: Border.all(
              color: border.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: AppColors.glowShadow(border, blur: 16),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: card),
    );
  }
}
