import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../domain/entities/home_game_entity.dart' show DailyRewardEntity, HomeGameEntity;
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

class HomeGamesRow extends ConsumerWidget {
  const HomeGamesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(homeGamesProvider);
    final rewards = ref.watch(homeDailyRewardsProvider);

    return games.when(
      loading: () => Column(
        children: [
          const HomeSectionHeader(title: 'Oyunlar & Etkinlikler'),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: 96,
                height: 96,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (gameItems) {
        final rewardItems = rewards.valueOrNull ?? const <DailyRewardEntity>[];
        final merged = <_GameTile>[
          ...gameItems.map(
            (g) => _GameTile(
              id: g.id,
              title: g.title,
              icon: g.icon ?? '🎮',
              route: g.route,
              color: g.accentColorArgb != null
                  ? Color(g.accentColorArgb! | 0xFF000000)
                  : HomePalette.primary,
            ),
          ),
          ...rewardItems.map(
            (r) => _GameTile(
              id: r.id,
              title: r.title,
              icon: '🎁',
              route: r.route,
              color: HomePalette.accentGold,
            ),
          ),
        ];
        if (merged.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const HomeSectionHeader(title: 'Oyunlar & Etkinlikler'),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: merged.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final tile = merged[i];
                  return _GameCard(
                    tile: tile,
                    onTap: () {
                      final route = tile.route;
                      if (route != null && route.isNotEmpty) {
                        openNativeSitePath(context, route);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GameTile {
  const _GameTile({
    required this.id,
    required this.title,
    required this.icon,
    this.route,
    required this.color,
  });

  final String id;
  final String title;
  final String icon;
  final String? route;
  final Color color;
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.tile, required this.onTap});

  final _GameTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tile.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tile.color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tile.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              tile.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
