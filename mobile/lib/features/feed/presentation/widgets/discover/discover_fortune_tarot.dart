import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';
import 'discover_section_header.dart';

class DiscoverFortuneTarot extends StatelessWidget {
  const DiscoverFortuneTarot({super.key});

  static const _cards = <_FortuneCard>[
    _FortuneCard(
      title: 'Tarot',
      subtitle: 'Kartların sırrını keşfet',
      border: Color(0xFFB832FF),
      emoji: '🃏',
      gradient: [Color(0xFF2E1064), Color(0xFF1E1B4B)],
    ),
    _FortuneCard(
      title: 'Aşk Falı',
      subtitle: 'Kalbinin sesini dinle',
      border: Color(0xFFFF4EC8),
      emoji: '💜',
      gradient: [Color(0xFF4A044E), Color(0xFF1E1B4B)],
    ),
    _FortuneCard(
      title: 'Kahve Falı',
      subtitle: 'Fincanındaki işaretler',
      border: Color(0xFFD97706),
      emoji: '☕',
      gradient: [Color(0xFF451A03), Color(0xFF1C1917)],
    ),
    _FortuneCard(
      title: 'Yıldız Haritası',
      subtitle: 'Burcunun mesajı',
      border: Color(0xFF38BDF8),
      emoji: '✨',
      gradient: [Color(0xFF0C4A6E), Color(0xFF1E1B4B)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DiscoverSectionHeader(
          title: 'Fal & Tarot',
          actionLabel: 'Tüm Falcılar',
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: _cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _FortuneTile(card: _cards[i]),
          ),
        ),
      ],
    );
  }
}

class _FortuneCard {
  const _FortuneCard({
    required this.title,
    required this.subtitle,
    required this.border,
    required this.emoji,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final Color border;
  final String emoji;
  final List<Color> gradient;
}

class _FortuneTile extends StatelessWidget {
  const _FortuneTile({required this.card});

  final _FortuneCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesign.radiusCard),
        border: Border.all(
          color: card.border.withValues(alpha: 0.65),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: card.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: card.border.withValues(alpha: 0.25),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        child: Column(
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 42)),
            const Spacer(),
            Text(
              card.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              card.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                color: AppDesign.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
