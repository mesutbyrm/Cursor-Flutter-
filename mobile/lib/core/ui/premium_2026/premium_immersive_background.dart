import 'package:flutter/material.dart';

import 'premium_2026_tokens.dart';

/// Immersive mesh gradient — Revolut / Airbnb tarzı derinlik.
class PremiumImmersiveBackground extends StatelessWidget {
  const PremiumImmersiveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.p26;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: t.meshTop),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: t.meshMid))),
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: t.meshBottom))),
                const _NoiseOverlay(),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.02),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.12),
            ],
          ),
        ),
      ),
    );
  }
}
