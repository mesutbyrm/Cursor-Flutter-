import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../fortune/domain/entities/fortune_type_entity.dart';
import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Onaylı mockup — yatay Fal & Tarot kartları.
class FortuneSection extends StatelessWidget {
  const FortuneSection({super.key});

  static const _displaySlugs = [
    'tarot',
    'kahve-fali',
    'katina',
    'el-fali',
    'yildiz-haritasi',
  ];

  static const _mockCounts = [2345, 1890, 1560, 1240, 980];

  @override
  Widget build(BuildContext context) {
    final entries = <({FortuneTypeEntity type, int count})>[];
    for (var i = 0; i < _displaySlugs.length; i++) {
      final type = FortuneCatalog.bySlug(_displaySlugs[i]);
      if (type != null) {
        entries.add((type: type, count: _mockCounts[i]));
      }
    }

    return Column(
      children: [
        const HomeSectionTitle(
          emoji: '🔮',
          title: 'Fal & Tarot',
        ),
        SizedBox(
          height: HomeApprovedDesign.fortuneCardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = entries[i];
              return _FortuneCard(
                emoji: e.type.emoji,
                title: e.type.title,
                count: e.count,
                accent: e.type.accent,
                onTap: () => context.push('/fortune/${e.type.slug}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({
    required this.emoji,
    required this.title,
    required this.count,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final int count;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: HomeApprovedDesign.fortuneCardW,
        height: HomeApprovedDesign.fortuneCardH,
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(color: HomeApprovedDesign.border),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HomeApprovedDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatCount(count)} kişi',
              style: const TextStyle(
                fontSize: 9,
                color: HomeApprovedDesign.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
