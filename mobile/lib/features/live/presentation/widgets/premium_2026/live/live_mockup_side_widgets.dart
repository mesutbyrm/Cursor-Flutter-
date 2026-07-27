import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

/// Sağ üst — Yıldız Turnuvası kartı (mockup). Soft UI; veri yoksa varsayılan gösterir.
class LiveStarTournamentCard extends StatelessWidget {
  const LiveStarTournamentCard({
    super.key,
    this.rank = 3,
    this.countdownLabel = '23:18:45',
    this.onTap,
  });

  final int rank;
  final String countdownLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 118,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Yıldız Turnuvası',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '🏆',
                      style: TextStyle(
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sıralaman: $rank',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFD54F),
                  ),
                ),
                Text(
                  countdownLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sağ şerit — beğeni kalpleri + Fal İste (hediye kutusu alt barda).
class LiveMockupSideRail extends StatelessWidget {
  const LiveMockupSideRail({
    super.key,
    required this.likeLabel,
    required this.onLike,
    this.onFortune,
    this.showFortune = false,
    this.onGiftPackages,
  });

  final String likeLabel;
  final VoidCallback onLike;
  final VoidCallback? onFortune;
  final bool showFortune;
  final VoidCallback? onGiftPackages;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onGiftPackages != null) ...[
          _PromoChip(
            title: 'Hediye Paketleri',
            subtitle: 'Özel İndirim',
            onTap: onGiftPackages!,
          ),
          const SizedBox(height: 12),
        ],
        if (showFortune && onFortune != null) ...[
          _PurpleCta(
            icon: Icons.auto_awesome_rounded,
            label: 'Fal İste',
            onTap: onFortune!,
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onDoubleTap: onLike,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2D7A), Color(0xFFE91E63)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeColors.accentPink.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                likeLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurpleCta extends StatelessWidget {
  const _PurpleCta({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27FF), Color(0xFF7C4DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.45),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoChip extends StatelessWidget {
  const _PromoChip({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF80AB).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.pinkAccent.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 4),
            const Text('🎁', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
