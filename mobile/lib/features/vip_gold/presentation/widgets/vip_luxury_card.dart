import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vip_gold_tokens.dart';

/// Glassmorphism luxury kart.
class VipLuxuryCard extends StatelessWidget {
  const VipLuxuryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: highlighted
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: VipGoldTokens.goldLuxury,
                  boxShadow: VipGoldTokens.goldGlow(blur: 20),
                )
              : VipGoldTokens.luxuryCard(radius: 22),
          child: DefaultTextStyle(
            style: TextStyle(
              color: highlighted ? Colors.black87 : Colors.white,
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: card,
        ),
      );
    }

    return card.animate().fadeIn(duration: 360.ms).slideY(begin: 0.06, end: 0);
  }
}
