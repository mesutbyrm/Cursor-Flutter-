import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'fortune_glass_card.dart';

class FortunePremiumUpsell extends StatelessWidget {
  const FortunePremiumUpsell({super.key});

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: AppColors.coinGold,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppColors.coinGold, size: 28),
              const SizedBox(width: 10),
              const Text(
                "Premium'a Geç",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Sınırsız fal, reklamsız deneyim, özel rozetler ve derinlemesine yorumlar.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/jeton-store'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coinGold,
                foregroundColor: const Color(0xFF1A1208),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Premium\'u Keşfet',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
