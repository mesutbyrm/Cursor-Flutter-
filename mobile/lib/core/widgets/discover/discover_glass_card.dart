import 'package:flutter/material.dart';

import '../themed_glass_card.dart';

/// Keşfet cam kartı — [ThemedGlassCard] sarmalayıcı.
class DiscoverGlassCard extends StatelessWidget {
  const DiscoverGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.blur = 16,
    this.useBlur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double blur;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    return ThemedGlassCard(
      padding: padding,
      onTap: onTap,
      blur: useBlur ? blur : 0,
      child: child,
    );
  }
}
