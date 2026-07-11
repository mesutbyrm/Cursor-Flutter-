import 'package:flutter/material.dart';

import 'package:canlifal_social/core/performance/effects_perf.dart';
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
    this.tier,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double blur;
  final bool elevated;
  final bool animateIn;
  final BorderRadius? borderRadius;

  /// Liste/grid satırı için [GlassTier.static] — blur kapalı.
  final GlassTier? tier;

  @override
  Widget build(BuildContext context) {
    final effectiveBlur = tier == GlassTier.static
        ? 0.0
        : (EffectsPerf.blurEnabled(context) ? blur : 0.0);
    final card = ThemedGlassCard(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: effectiveBlur,
      elevated: elevated,
      onTap: onTap,
      child: child,
    );

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

/// Hafif cam — listelerde blur yok (gölge + fill).
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
      tier: GlassTier.static,
      blur: 0,
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
    return EffectsPerf.chromeBar(
      context: context,
      decoration: BoxDecoration(
        color: c.glassFill,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: SizedBox(height: height, child: child),
    );
  }
}
