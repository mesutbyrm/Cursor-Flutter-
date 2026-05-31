import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// CanlıFal marka logosu — yıldız + gradyan wordmark (raster ikon gerekmez).
class CanlifalLogo extends StatelessWidget {
  const CanlifalLogo({
    super.key,
    this.size = 88,
    this.showWordmark = true,
    this.animateGlow = false,
  });

  final double size;
  final bool showWordmark;
  final bool animateGlow;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: AppColors.glowShadow(AppColors.accentPink, blur: size * 0.35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.42,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          Positioned(
            bottom: size * 0.18,
            child: Text(
              'CF',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.18,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: size * 0.28),
        ShaderMask(
          shaderCallback: (b) => AppColors.brandGradient.createShader(b),
          child: Text(
            'CanlıFal',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
