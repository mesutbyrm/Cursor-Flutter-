import 'dart:ui';

import 'package:flutter/material.dart';

import '../../performance/list_perf.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_spacing.dart';
import '../premium_2026/liquid_glass.dart';
import '../premium_2026/premium_motion.dart';

export '../premium_2026/liquid_glass.dart' show PressableScale;

/// TikTok / Discord seviyesi cam kart — blur, yarı saydam dolgu, yumuşak gölge.
class ProGlassCard extends StatelessWidget {
  const ProGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.blur = 18,
    this.elevated = false,
    this.animateIn = true,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double blur;
  final bool elevated;
  final bool animateIn;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    Widget card = LiquidGlass(
      padding: padding,
      margin: margin,
      borderRadius: radius,
      blur: blur,
      elevated: elevated,
      onTap: onTap,
      child: child,
    );

    card = ListPerf.repaint(card);

    if (!animateIn) return card;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: PremiumMotion.fast,
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: ((scale - 0.94) / 0.06).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}

/// Hafif cam — listelerde düşük blur (performans).
class ProGlassListTile extends StatelessWidget {
  const ProGlassListTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ProGlassCard(
      blur: 12,
      elevated: false,
      animateIn: false,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// Sabit üst cam header (Discord tarzı).
class ProGlassTopBar extends StatelessWidget {
  const ProGlassTopBar({
    super.key,
    required this.child,
    this.height = 56,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: palette.glassOverlay,
            border: Border(
              bottom: BorderSide(color: palette.divider),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
