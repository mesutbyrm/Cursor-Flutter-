import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import 'premium_motion.dart';

/// Yüzen blur kart — feed / hero bölümleri.
class PremiumFloatingCard extends StatelessWidget {
  const PremiumFloatingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: PremiumMotion.slow,
      curve: PremiumMotion.expo,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: LiquidGlass(
        margin: margin,
        padding: padding,
        elevated: true,
        blur: 26,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Yatay kaydırmalı yüzen kart şeridi sarmalayıcı.
class PremiumFloatingStrip extends StatelessWidget {
  const PremiumFloatingStrip({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        physics: PremiumMotion.listPhysics,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: itemBuilder,
      ),
    );
  }
}
