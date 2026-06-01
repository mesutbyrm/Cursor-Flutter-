import 'package:flutter/material.dart';

import '../premium_2026/liquid_glass.dart';
import '../../theme/app_colors.dart';

/// Jeton kapsülü — liquid glass + gradient ikon.
class PremiumCoinCapsule extends StatelessWidget {
  const PremiumCoinCapsule({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(24),
      blur: 16,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF7DD3FC), Color(0xFFC084FC)],
            ).createShader(b),
            child: const Icon(
              Icons.diamond_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
