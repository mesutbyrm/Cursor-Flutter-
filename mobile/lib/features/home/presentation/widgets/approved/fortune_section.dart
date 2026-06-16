import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../../domain/entities/home_fortune_card_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Web uyumlu — `GET /api/homepage-fortune-cards` + yerel katalog yedek.
class FortuneSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(homeFortuneCardsProvider);
    final entries = api.maybeWhen(
      data: (cards) => cards.isNotEmpty ? _fromApi(cards) : _fromCatalog(),
      orElse: _fromCatalog,
    );

    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔮',
          title: 'Fal & Tarot',
          actionLabel: 'Tümü >',
          onAction: () => context.go('/fortune'),
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
                emoji: e.emoji,
                title: e.title,
                count: e.count,
                accent: e.accent,
                imageUrl: e.imageUrl,
                onTap: () => context.push('/fortune/${e.slug}'),
              );
            },
          ),
        ),
      ],
    );
  }

  List<({String slug, String emoji, String title, int count, Color accent, String? imageUrl})>
      _fromApi(List<HomeFortuneCardEntity> cards) {
    return cards.take(8).map((c) {
      final catalog = FortuneCatalog.bySlug(c.navigationSlug);
      return (
        slug: c.navigationSlug,
        emoji: c.icon.isNotEmpty ? c.icon : (catalog?.emoji ?? '🔮'),
        title: c.title,
        count: 0,
        accent: c.accent,
        imageUrl: c.imageUrl,
      );
    }).toList();
  }

  List<({String slug, String emoji, String title, int count, Color accent, String? imageUrl})>
      _fromCatalog() {
    final out = <({String slug, String emoji, String title, int count, Color accent, String? imageUrl})>[];
    for (var i = 0; i < _displaySlugs.length; i++) {
      final type = FortuneCatalog.bySlug(_displaySlugs[i]);
      if (type != null) {
        out.add((
          slug: type.slug,
          emoji: type.emoji,
          title: type.title,
          count: _mockCounts[i],
          accent: type.accent,
          imageUrl: null,
        ));
      }
    }
    return out;
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({
    required this.emoji,
    required this.title,
    required this.count,
    required this.accent,
    required this.onTap,
    this.imageUrl,
  });

  final String emoji;
  final String title;
  final int count;
  final Color accent;
  final VoidCallback onTap;
  final String? imageUrl;

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
          image: imageUrl != null && imageUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.35),
                    BlendMode.darken,
                  ),
                )
              : null,
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
            if (count > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${_formatCount(count)} kişi',
                style: const TextStyle(
                  fontSize: 9,
                  color: HomeApprovedDesign.textMuted,
                ),
              ),
            ],
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
