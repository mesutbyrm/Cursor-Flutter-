import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/discover_tab_layout.dart';
import '../../../domain/game_center_models.dart';
import '../../../domain/game_models.dart';
import '../../providers/game_providers.dart';
import '../providers/game_center_providers.dart';
import '../widgets/game_center_widgets.dart';
import '../../widgets/game_catalog_card.dart';

/// Profesyonel Oyun Merkezi — canlifal.com jeton ve skor API'leriyle entegre.
class GameCenterPage extends ConsumerWidget {
  const GameCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jeton = ref.watch(gameCenterJetonProvider);
    final leaderboard = ref.watch(
      gameCenterLeaderboardProvider(LeaderboardPeriod.weekly),
    );
    final catalog = ref.watch(gameCatalogProvider);
    final rooms = ref.watch(gameCenterLiveRoomsProvider);

    return DiscoverSubPage(
      title: 'Oyun Merkezi',
      subtitle: 'Popüler oyunlar, canlı odalar ve ödüller',
      actions: [
        GameCenterJetonChip(
          balance: jeton.valueOrNull ?? 0,
          isLoading: jeton.isLoading,
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Yardım',
          onPressed: () => _showHelp(context),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
      onRefresh: () => refreshGameCenter(ref),
      body: RefreshIndicator(
        color: context.accentPink,
        onRefresh: () => refreshGameCenter(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            GameCenterHeroBanner(
              onSpin: () => context.push('/games-hub/wheel'),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/games-hub/okey101'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.view_module_rounded,
                          color: Color(0xFF059669),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Okey 101',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: context.colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '4 oyunculu · 101 puanla aç · çok oyunculu',
                              style: TextStyle(
                                color: context.colors.onSurfaceMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const GameCenterSectionHeader(title: 'Oyun kataloğu'),
            catalog.when(
              loading: () => const GameCenterLoadingBody(),
              error: (e, _) => GameCenterEmptyState(
                message: ApiException.userMessage(e),
                onRetry: () => ref.invalidate(gameCatalogProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const GameCenterEmptyState(
                    message: 'Şu anda listelenecek oyun yok.',
                  );
                }
                final roomCounts = _roomCountsByGame(rooms.valueOrNull);
                return Column(
                  children: [
                    for (final game in items.take(12))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GameCatalogCard(
                          game: game,
                          activeRooms: roomCounts[game.id],
                          onTap: () => _openGame(context, ref, game),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            leaderboard.when(
              loading: () => const GameCenterLoadingBody(),
              error: (e, _) => GameCenterEmptyState(
                message: ApiException.userMessage(e),
                onRetry: () => ref.invalidate(
                  gameCenterLeaderboardProvider(LeaderboardPeriod.weekly),
                ),
              ),
              data: (entries) => _LeaderboardTeaser(
                entries: entries,
                onTap: () => context.push('/games-hub/leaderboard'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/games-hub'),
              icon: const Icon(Icons.hub_rounded),
              label: const Text('Klasik oyun lobisi (API odaları)'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _roomCountsByGame(List<GameRoomItem>? rooms) {
    if (rooms == null) return const {};
    final counts = <String, int>{};
    for (final room in rooms) {
      final key = room.gameId.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _openGame(
    BuildContext context,
    WidgetRef ref,
    GameCatalogItem game,
  ) async {
    final route = game.route;
    if (route != null && route.isNotEmpty) {
      context.push(route);
      return;
    }
    try {
      final room = await ref.read(gameRemoteProvider).createRoom(game);
      ref.invalidate(gameRoomsProvider);
      if (!context.mounted) return;
      if (room != null) {
        context.push(
          '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}&game=${Uri.encodeComponent(game.id)}',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oyun başlatılamadı: ${ApiException.userMessage(e)}'),
        ),
      );
    }
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oyun Merkezi'),
        content: const Text(
          'Jeton harcayan oyunlarda bakiyeniz otomatik kontrol edilir. '
          'Skorlarınız canlifal.com veritabanına kaydedilir ve liderlik '
          'tablosunda görünür.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTeaser extends StatelessWidget {
  const _LeaderboardTeaser({
    required this.entries,
    required this.onTap,
  });

  final List<LeaderboardEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final top = entries.take(3).toList();
    if (top.isEmpty) {
      return const GameCenterEmptyState(
        message: 'Henüz liderlik verisi yok.',
      );
    }
    return GameCenterLeaderboardPreview(entries: top, onSeeAll: onTap);
  }
}
