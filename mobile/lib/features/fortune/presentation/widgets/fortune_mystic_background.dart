import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Fal & Tarot sayfaları — mor/mavi mistik arka plan.
class FortuneMysticBackground extends StatelessWidget {
  const FortuneMysticBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B0618),
                AppColors.background,
                Color(0xFF0A1528),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.35),
                  blurRadius: 80,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCyan.withValues(alpha: 0.2),
                  blurRadius: 70,
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
