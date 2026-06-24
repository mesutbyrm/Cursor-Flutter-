import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_colors.dart';
import 'profile_glass.dart';

/// Profil — reklam fal hakkı ve jeton özeti.
class ProfileFortuneAccessBadges extends StatelessWidget {
  const ProfileFortuneAccessBadges({
    super.key,
    required this.adCredits,
    required this.jeton,
  });

  final int adCredits;
  final int jeton;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.all(16),
      borderColor: AppThemeColors.accentPink.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fal erişimi', style: ProfileTypography.cardTitle(context)),
          const SizedBox(height: 12),
          _BadgeRow(
            emoji: '🎁',
            label: 'Reklamdan Kazanılan Fal Hakları',
            value: '$adCredits',
            accent: AppThemeColors.accentPurple,
          ),
          const SizedBox(height: 10),
          _BadgeRow(
            emoji: '🪙',
            label: 'Jeton Bakiyesi',
            value: '$jeton',
            accent: AppThemeColors.coinGold,
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String emoji;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: ProfileTypography.cardSubtitle(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
