import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../domain/entities/fortune_type_entity.dart';
import 'fortune_glass_card.dart';
import 'fortune_type_network_image.dart';

/// Fal & Tarot hub — görsel vitrin kartı (2026 premium).
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
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FortuneTypeNetworkImage(
              slug: type.slug,
              accent: type.accent,
              emoji: type.emoji,
              borderRadius: 0,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: type.accent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppThemeColors.glowShadow(type.accent, blur: 8),
                    ),
                    child: Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
