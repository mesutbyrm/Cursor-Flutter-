import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../../../fortune/presentation/data/fortune_type_images.dart';
import '../../../../fortune/presentation/widgets/fortune_type_cover_image.dart';
import '../../../domain/entities/home_fortune_card_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = entries[i];
              return _FortuneCard(
                title: e.title,
                accent: e.accent,
                slug: e.slug,
                imageUrl: e.imageUrl,
                emoji: e.emoji,
                onTap: () => context.push('/fortune/${e.slug}'),
              );
            },
          ),
        ),
      ],
    );
  }

  List<({String slug, String emoji, String title, Color accent, String? imageUrl})>
      _fromApi(List<HomeFortuneCardEntity> cards) {
    return cards.take(8).map((c) {
      final catalog = FortuneCatalog.bySlug(c.navigationSlug);
      return (
        slug: c.navigationSlug,
        emoji: c.icon.isNotEmpty ? c.icon : (catalog?.emoji ?? '🔮'),
        title: c.title,
        accent: c.accent,
        imageUrl: _fortuneImage(c.navigationSlug, c.imageUrl),
      );
    }).toList();
  }

  List<({String slug, String emoji, String title, Color accent, String? imageUrl})>
      _fromCatalog() {
    final out = <({String slug, String emoji, String title, Color accent, String? imageUrl})>[];
    for (final slug in _displaySlugs) {
      final type = FortuneCatalog.bySlug(slug);
      if (type != null) {
        out.add((
          slug: type.slug,
          emoji: type.emoji,
          title: type.title,
          accent: type.accent,
          imageUrl: FortuneTypeImages.urlFor(type.slug, width: 480),
        ));
      }
    }
    return out;
  }

  static String? _fortuneImage(String slug, String? apiUrl) {
    final raw = apiUrl?.trim();
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith('http')) return CanlifalImageUrls.resolve(raw);
      final resolved = CanlifalImageUrls.resolve(raw);
      if (resolved.isNotEmpty) return resolved;
      return FortuneTypeImages.urlFor(slug, width: 480);
    }
    return null;
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({
    required this.title,
    required this.accent,
    required this.slug,
    required this.onTap,
    this.imageUrl,
    this.emoji = '🔮',
  });

  final String title;
  final Color accent;
  final String slug;
  final VoidCallback onTap;
  final String? imageUrl;
  final String emoji;

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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FortuneTypeCoverImage(
              slug: slug,
              accent: accent,
              imageWidth: 480,
            ),
            if (imageUrl != null && imageUrl!.trim().isNotEmpty)
              CanlifalNetworkImage(
                url: CanlifalImageUrls.resolve(imageUrl),
                fit: BoxFit.cover,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
