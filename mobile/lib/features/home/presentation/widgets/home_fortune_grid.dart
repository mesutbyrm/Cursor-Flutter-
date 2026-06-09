import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../fortune/presentation/data/fortune_catalog.dart';
import '../../domain/entities/home_fortune_card_entity.dart';
import '../providers/home_providers.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

/// Fal & Tarot — 2×4 grid (canlifal.com API + yerel katalog yedek).
class HomeFortuneGrid extends ConsumerWidget {
  const HomeFortuneGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiAsync = ref.watch(homeFortuneCardsProvider);
    final entries = apiAsync.maybeWhen(
      data: (cards) => _tilesFromApi(cards),
      orElse: () => _tilesFromCatalog(),
    );

    return Column(
      children: [
        HomeSectionHeader(
          title: 'Fal & Tarot',
          leadingDotColor: const Color(0xFFB84DFF),
          onTrailing: () => context.go('/fortune'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return _FortuneTile(
                emoji: e.emoji,
                title: e.title,
                accent: e.accent,
                imageUrl: e.imageUrl,
                onTap: () => context.push('/fortune/${e.slug}'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: HomeGlassCard(
            onTap: () => context.push('/fortune/types'),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+6 daha fazla fal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_FortuneTileData> _tilesFromApi(List<HomeFortuneCardEntity> cards) {
    final active = cards.where((c) => c.title.isNotEmpty).take(8).toList();
    if (active.isEmpty) return _tilesFromCatalog();
    return active.map((c) {
      final slug = c.navigationSlug;
      final catalog = FortuneCatalog.bySlug(slug);
      return _FortuneTileData(
        slug: slug,
        title: c.title,
        emoji: c.icon.isNotEmpty ? c.icon : (catalog?.emoji ?? '🔮'),
        accent: catalog?.accent ?? c.accent,
        imageUrl: c.imageUrl,
      );
    }).toList();
  }

  List<_FortuneTileData> _tilesFromCatalog() {
    return FortuneCatalog.hubFortuneTypes
        .map(
          (e) => _FortuneTileData(
            slug: e.type.slug,
            title: e.type.title,
            emoji: e.type.emoji,
            accent: e.type.accent,
          ),
        )
        .toList();
  }
}

class _FortuneTileData {
  const _FortuneTileData({
    required this.slug,
    required this.title,
    required this.emoji,
    required this.accent,
    this.imageUrl,
  });

  final String slug;
  final String title;
  final String emoji;
  final Color accent;
  final String? imageUrl;
}

class _FortuneTile extends StatelessWidget {
  const _FortuneTile({
    required this.emoji,
    required this.title,
    required this.accent,
    required this.onTap,
    this.imageUrl,
  });

  final String emoji;
  final String title;
  final Color accent;
  final VoidCallback onTap;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final img = imageUrl?.trim();
    return HomeGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      glowColor: accent,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.35),
          const Color(0xFF12082A).withValues(alpha: 0.85),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (img != null && img.startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: img,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            )
          else
            Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
