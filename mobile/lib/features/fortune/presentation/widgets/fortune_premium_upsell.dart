import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:go_router/go_router.dart';

import 'fortune_glass_card.dart';

class FortunePremiumUpsell extends StatelessWidget {
  const FortunePremiumUpsell({super.key});

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: AppThemeColors.coinGold,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppThemeColors.coinGold, size: 28),
              SizedBox(width: 10),
              Text(
                "Premium'a Geç",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Sınırsız fal, reklamsız deneyim, özel rozetler ve derinlemesine yorumlar.',
            style: TextStyle(
              color: context.colors.onSurfaceVariant,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/jeton-store'),
              style: FilledButton.styleFrom(
                backgroundColor: AppThemeColors.coinGold,
                foregroundColor: const Color(0xFF1A1208),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
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
