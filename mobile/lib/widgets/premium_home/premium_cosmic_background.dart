import 'package:flutter/material.dart';

import '../../theme/premium_live_theme.dart';
import 'premium_starfield_painter.dart';

class PremiumCosmicBackground extends StatelessWidget {
  const PremiumCosmicBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: PremiumLiveTheme.backdropGradient),
        ),
        CustomPaint(
          painter: PremiumStarfieldPainter(),
          size: Size.infinite,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PremiumLiveTheme.neonPurple.withValues(alpha: 0.08),
                  Colors.transparent,
                  PremiumLiveTheme.neonPink.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
