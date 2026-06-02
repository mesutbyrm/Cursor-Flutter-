import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../theme/home_palette.dart';

/// Cam kart — canlifal.com 2026 ana sayfa.
class HomeGlassCard extends StatelessWidget {
  const HomeGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.glowColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? HomePalette.radiusCard;
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DiscoverPremiumVisual.glassBlur,
          sigmaY: DiscoverPremiumVisual.glassBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: gradient,
            color: gradient == null ? DiscoverPremiumVisual.glassFill : null,
            border: Border.all(color: DiscoverPremiumVisual.glassBorder),
            boxShadow: DiscoverPremiumVisual.cardGlow(color: glowColor),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
