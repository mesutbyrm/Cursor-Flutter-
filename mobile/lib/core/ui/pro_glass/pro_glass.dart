import 'dart:ui';

import 'package:flutter/material.dart';

import '../../performance/list_perf.dart';
import '../../theme/app_spacing.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import '../../widgets/themed_glass_card.dart';
import '../premium_2026/premium_motion.dart';

/// TikTok / Discord seviyesi cam kart — tema uyumlu glassmorphism.
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
    final c = context.colors;
    final effectiveBlur = c.useGlassBlur ? blur : 0.0;
    Widget card = ThemedGlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: effectiveBlur,
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
    final c = context.colors;
    final sigma = c.useGlassBlur ? 20.0 : 0.0;
    Widget bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: child,
    );
    if (sigma > 0) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: bar,
        ),
      );
    }
    return bar;
  }
}
