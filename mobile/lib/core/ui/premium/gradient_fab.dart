import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Orta alt navigasyon FAB — tam yuvarlak, gradient, isteğe bağlı nabız.
class GradientFab extends StatelessWidget {
  const GradientFab({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = AppSpacing.centerFabSize,
    this.pulse = true,
    this.offsetY = -18,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool pulse;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    Widget fab = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.fabGradient,
          boxShadow: AppColors.glowShadow(AppColors.accentPink, blur: 28),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.52),
      ),
    );

    if (pulse) {
      fab = fab
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1400.ms,
            curve: Curves.easeInOut,
          );
    }

    return Transform.translate(offset: Offset(0, offsetY), child: fab);
  }
}
