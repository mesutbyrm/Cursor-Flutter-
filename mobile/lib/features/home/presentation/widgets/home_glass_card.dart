import 'package:canlifal_social/core/performance/effects_perf.dart';
import 'package:canlifal_social/core/widgets/themed_glass_card.dart';
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
    this.tier = GlassTier.static,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? glowColor;

  /// Grid hücreleri: [GlassTier.static] (blur yok). CTA: [GlassTier.elevated].
  final GlassTier tier;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? HomePalette.radiusCard;
    final sigma = EffectsPerf.sigma(tier, context);

    if (sigma <= 0) {
      return EffectsPerf.listSurface(
        onTap: onTap,
        padding: padding ?? const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(radius),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? DiscoverPremiumVisual.glassFill : null,
          border: Border.all(color: DiscoverPremiumVisual.glassBorder),
          boxShadow: DiscoverPremiumVisual.cardGlow(color: glowColor),
        ),
        child: child,
      );
    }

    return ThemedGlassCard(
      onTap: onTap,
      padding: padding ?? const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(radius),
      blur: sigma,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? DiscoverPremiumVisual.glassFill : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: DiscoverPremiumVisual.glassBorder),
          boxShadow: DiscoverPremiumVisual.cardGlow(color: glowColor),
        ),
        child: child,
      ),
    );
  }
}
