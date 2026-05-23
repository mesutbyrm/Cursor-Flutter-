import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/ui/premium/neon_quick_action_card.dart';
import 'discover_section_header.dart';

/// Ana sayfa — 5 neon cam hızlı işlem (yatay kaydırma).
class DiscoverQuickActions extends StatelessWidget {
  const DiscoverQuickActions({super.key});

  static const _cardSize = AppSpacing.quickActionSize + 4;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DiscoverSectionHeader(
          title: 'Hızlı İşlemler',
          actionLabel: '',
          onAction: null,
        ),
        SizedBox(
          height: _cardSize + 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              NeonQuickActionCard(
                label: 'Fal&Tarot',
                gradient: const [Color(0xFF9333EA), Color(0xFF4C1D95)],
                glowColor: const Color(0xFFA855F7),
                size: _cardSize,
                icon: const NeonQuickActionIcon(
                  glowColor: Color(0xFFE9D5FF),
                  child: _FortuneTarotIcon(),
                ),
                onTap: () => context.go('/fortune'),
              ),
              const SizedBox(width: 12),
              NeonQuickActionCard(
                label: 'Sesli Odaya\nGir',
                gradient: const [Color(0xFF6366F1), Color(0xFF312E81)],
                glowColor: const Color(0xFF818CF8),
                size: _cardSize,
                icon: const NeonQuickActionIcon(
                  glowColor: Color(0xFFC7D2FE),
                  child: _VoiceWaveIcon(),
                ),
                onTap: () => context.push('/voice-rooms'),
              ),
              const SizedBox(width: 12),
              NeonQuickActionCard(
                label: 'Arkadaşlarını\nDavet Et',
                gradient: const [Color(0xFFFBBF24), Color(0xFFEA580C)],
                glowColor: const Color(0xFFF59E0B),
                size: _cardSize,
                icon: const NeonQuickActionIcon(
                  glowColor: Color(0xFFFDE68A),
                  child: Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                onTap: () => context.push('/invite-friends'),
              ),
              const SizedBox(width: 12),
              NeonQuickActionCard(
                label: 'Hediye\nYolla',
                gradient: const [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                glowColor: const Color(0xFF60A5FA),
                size: _cardSize,
                icon: const NeonQuickActionIcon(
                  glowColor: Color(0xFFBFDBFE),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                onTap: () => context.push('/gift-send'),
              ),
              const SizedBox(width: 12),
              NeonQuickActionCard(
                label: 'Jeton\nYükle',
                gradient: const [Color(0xFF2DD4BF), Color(0xFF0F766E)],
                glowColor: const Color(0xFF14B8A6),
                size: _cardSize,
                icon: const NeonQuickActionIcon(
                  glowColor: Color(0xFF99F6E4),
                  child: Icon(
                    Icons.diamond_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                onTap: () => context.push('/jeton-store'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Kristal küre — yıldız + hilal.
class _FortuneTarotIcon extends StatelessWidget {
  const _FortuneTarotIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.blur_circular_rounded,
            size: 38,
            color: Colors.white.withValues(alpha: 0.95),
            shadows: [
              Shadow(
                color: AppColors.accentPurple.withValues(alpha: 0.9),
                blurRadius: 12,
              ),
            ],
          ),
          Icon(
            Icons.star_rounded,
            size: 14,
            color: const Color(0xFFFFE566),
            shadows: [
              Shadow(
                color: const Color(0xFFFFE566).withValues(alpha: 0.8),
                blurRadius: 8,
              ),
            ],
          ),
          Positioned(
            right: 6,
            bottom: 8,
            child: Icon(
              Icons.nightlight_round,
              size: 12,
              color: const Color(0xFFFFE566),
              shadows: [
                Shadow(
                  color: const Color(0xFFFFE566).withValues(alpha: 0.7),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dikey ses dalgası çubukları.
class _VoiceWaveIcon extends StatelessWidget {
  const _VoiceWaveIcon();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(10, const Color(0xFFC4B5FD)),
        const SizedBox(width: 3),
        _bar(18, const Color(0xFFE9D5FF)),
        const SizedBox(width: 3),
        _bar(26, Colors.white),
        const SizedBox(width: 3),
        _bar(18, const Color(0xFFE9D5FF)),
        const SizedBox(width: 3),
        _bar(10, const Color(0xFFC4B5FD)),
      ],
    );
  }

  Widget _bar(double h, Color c) {
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.75),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
