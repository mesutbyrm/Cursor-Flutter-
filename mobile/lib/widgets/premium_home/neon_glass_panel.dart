import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/premium_live_theme.dart';

/// Cam panel — blur + yarı saydam kenar.
class NeonGlassPanel extends StatelessWidget {
  const NeonGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.borderColor,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? Colors.white.withValues(alpha: 0.14);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PremiumLiveTheme.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: bc, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: PremiumLiveTheme.neonPurple.withValues(alpha: 0.12),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
