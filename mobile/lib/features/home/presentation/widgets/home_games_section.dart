import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../games/domain/game_center_models.dart';
import '../../../games/presentation/game_center/providers/game_center_providers.dart';
import '../../../games/presentation/game_center/widgets/game_center_widgets.dart';
import '../../domain/entities/home_game_entity.dart' show DailyRewardEntity;
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import '../theme/home_palette.dart';
import 'approved/home_section_title.dart';

/// Oyunlar şeridi + Oyun Merkezi CTA ve liderlik önizlemesi — birleşik bölüm.
class HomeGamesSection extends ConsumerWidget {
  const HomeGamesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(homeGamesProvider);
    final rewards = ref.watch(homeDailyRewardsProvider);
    final jeton = ref.watch(gameCenterJetonProvider);
    final leaderboard = ref.watch(
      gameCenterLeaderboardProvider(LeaderboardPeriod.weekly),
    );
    final formatter = NumberFormat.decimalPattern('tr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          emoji: '🎮',
          title: 'Oyunlar & Merkezi',
          actionLabel: 'Merkez >',
          onAction: () => context.push('/games-hub'),
        ),
        games.when(
          loading: () => SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const PremiumSkeleton(
                width: 96,
                height: 96,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
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
            return SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: merged.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final tile = merged[i];
                  return _GameCard(
                    tile: tile,
                    onTap: () {
                      final route = tile.route?.trim();
                      if (route != null && route.isNotEmpty) {
                        openNativeSitePath(context, route);
                      } else {
                        context.push('/games-hub');
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: Material(
            color: HomeApprovedDesign.surface,
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/games-hub'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
                  border: Border.all(color: HomeApprovedDesign.border),
                  gradient: LinearGradient(
                    colors: [
                      HomeApprovedDesign.purple.withValues(alpha: 0.22),
                      HomeApprovedDesign.pink.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Oyun Merkezi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: HomeApprovedDesign.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jeton.when(
                              data: (b) => '${formatter.format(b)} Jeton',
                              loading: () => 'Yakında yeni oyunlar',
                              error: (_, _) => 'Liderlik tablosu ve ödüller',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: HomeApprovedDesign.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: HomeApprovedDesign.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GameCenterLeaderboardPreview(
          entries: leaderboard.valueOrNull ?? const [],
          isLoading: leaderboard.isLoading,
          onSeeAll: () => context.push('/games-hub/leaderboard'),
        ),
      ],
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
