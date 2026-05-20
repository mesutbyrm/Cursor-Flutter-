import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';

class DiscoverBackground extends StatelessWidget {
  const DiscoverBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppDesign.bgBase),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(
              size: 280,
              colors: [
                AppDesign.bgPurpleGlow.withValues(alpha: 0.85),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: -100,
            child: _GlowBlob(
              size: 240,
              colors: [
                AppDesign.accentPurple.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
            child: _GlowBlob(
              size: 200,
              colors: [
                AppDesign.bgBlueGlow.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
