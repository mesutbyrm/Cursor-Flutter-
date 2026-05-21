import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/fortune_type_entity.dart';
import 'fortune_glass_card.dart';

/// Grid kartı — ikon, başlık, açıklama, Keşfet.
class FortuneTypeGridCard extends StatelessWidget {
  const FortuneTypeGridCard({
    super.key,
    required this.type,
    required this.onExplore,
  });

  final FortuneTypeEntity type;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: type.accent,
      padding: const EdgeInsets.all(14),
      onTap: onExplore,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  type.accent.withValues(alpha: 0.5),
                  type.accent.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: AppColors.glowShadow(type.accent, blur: 12),
            ),
            child: Text(type.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            type.title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            type.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: type.accent.withValues(alpha: 0.85),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Keşfet',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
