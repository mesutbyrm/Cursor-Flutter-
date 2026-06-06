import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../core/ui/premium_2026/premium_immersive_background.dart';

/// Fal sayfaları — 2026 immersive mesh + mistik glow.
class FortuneMysticBackground extends StatelessWidget {
  const FortuneMysticBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumImmersiveBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
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
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.32),
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
                    color: AppThemeColors.accentCyan.withValues(alpha: 0.18),
                    blurRadius: 70,
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
