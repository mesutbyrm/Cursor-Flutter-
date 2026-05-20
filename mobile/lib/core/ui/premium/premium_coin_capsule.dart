import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/canlifal_tokens.dart';

/// Jeton / coin göstergesi — profil header, keşfet üst bar.
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
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: tokens.coinGradient,
            border: Border.all(
              color: AppColors.accentPurple.withValues(alpha: 0.45),
            ),
            boxShadow: AppColors.glowShadow(AppColors.accentPurple, blur: 14),
          ),
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
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
