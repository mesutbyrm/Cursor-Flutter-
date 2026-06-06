import 'package:flutter/material.dart';

import '../premium_2026/liquid_glass.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

/// Neon çerçeveli liquid glass kart — feed / profil / liste.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradientBorder,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradientBorder;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LiquidGlass(
      padding: padding,
      elevated: elevated,
      onTap: onTap,
      gradientBorder: gradientBorder ?? tokens.brandGradient,
      borderRadius: BorderRadius.circular(tokens.radiusCard),
      blur: elevated ? 24 : 18,
      child: child,
    );
  }
}
