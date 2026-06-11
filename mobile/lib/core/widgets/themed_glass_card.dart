import 'dart:ui';

import 'package:flutter/material.dart';

import '../performance/list_perf.dart';
import '../theme/app_spacing.dart';
import '../ui/platform_blur.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool elevated;
  final double? blur;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg);
    final sigma = blur ??
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

    if (PlatformBlur.supportsBackdropBlur && c.useGlassBlur && sigma > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: content,
        ),
      );
    }

    content = ListPerf.repaint(content);

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
