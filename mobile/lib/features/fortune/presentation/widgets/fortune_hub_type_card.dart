import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../domain/entities/fortune_type_entity.dart';
import 'fortune_glass_card.dart';

/// Fal & Tarot hub — 2×4 grid kartı (mockup: kenarlık, ikon, başlık, alt metin).
class FortuneHubTypeCard extends StatelessWidget {
  const FortuneHubTypeCard({
    super.key,
    required this.type,
    required this.subtitle,
    required this.onTap,
  });

  final FortuneTypeEntity type;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      accent: type.accent,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  type.accent.withValues(alpha: 0.55),
                  type.accent.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: AppThemeColors.glowShadow(type.accent, blur: 10),
            ),
            child: Text(type.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const Spacer(),
          Text(
            type.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.92),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
