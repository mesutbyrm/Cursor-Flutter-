import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Keşfet arka plan glow — RepaintBoundary ile izole.
class DiscoverBackground extends StatelessWidget {
  const DiscoverBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(child: _DiscoverGlowLayer()),
          child,
        ],
      ),
    );
  }
}

class _DiscoverGlowLayer extends StatelessWidget {
  const _DiscoverGlowLayer();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          top: -120,
          left: -80,
          child: _GlowBlob(
            size: 280,
            colors: [Color(0xD91A0F3D), Colors.transparent],
          ),
        ),
        Positioned(
          top: 40,
          right: -100,
          child: _GlowBlob(
            size: 240,
            colors: [Color(0x59B832FF), Colors.transparent],
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: _GlowBlob(
            size: 200,
            colors: [Color(0xB30A1A2E), Colors.transparent],
          ),
        ),
      ],
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
