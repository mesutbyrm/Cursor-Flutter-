import 'package:canlifal_social/core/performance/effects_perf.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../ui/platform_blur.dart';

/// Premium cam / kart — koyu modda glassmorphism, açık modda yumuşak gölge.
class ThemedGlassCard extends StatelessWidget {
  const ThemedGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.borderRadius,
    this.elevated = false,
    this.blur,
    this.tier,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool elevated;
  final double? blur;
  final GlassTier? tier;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    final tierSigma = tier != null ? EffectsPerf.sigma(tier!, context) : null;
    final sigma = blur ??
        tierSigma ??
        (c.useGlassBlur && PlatformBlur.supportsBackdropBlur ? 18.0 : 0.0);
    final shadows = elevated ? c.elevatedShadow : c.cardShadow;

    Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: elevated ? c.glassFillElevated : c.glassFill,
        border: Border.all(
          color: c.glassBorder,
          width: 1,
        ),
        boxShadow: shadows,
      ),
      child: child,
    );

    content = EffectsPerf.backdrop(
      sigma: sigma,
      borderRadius: radius,
      child: content,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: c.primary.withValues(alpha: 0.12),
        highlightColor: c.primary.withValues(alpha: 0.06),
        child: content,
      ),
    );
  }
}
