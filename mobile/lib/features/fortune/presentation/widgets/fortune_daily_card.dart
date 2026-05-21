import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/fortune_type_entity.dart';
import 'fortune_glass_card.dart';

/// Günlük fal — öne çıkan büyük kart (sandık / hazine).
class FortuneDailyCard extends StatelessWidget {
  const FortuneDailyCard({
    super.key,
    required this.type,
    required this.onOpen,
  });

  final FortuneTypeEntity type;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: type.accent,
      padding: const EdgeInsets.all(20),
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.coinGold.withValues(alpha: 0.6),
                  type.accent.withValues(alpha: 0.4),
                ],
              ),
              boxShadow: AppColors.glowShadow(AppColors.coinGold, blur: 20),
            ),
            child: Text(type.emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.brandGradient.createShader(b),
                  child: const Text(
                    'Günlük Fal',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  type.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              type.ctaLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
