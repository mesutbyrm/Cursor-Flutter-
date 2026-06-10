import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/discover_tab_layout.dart';
import '../../../domain/game_center_models.dart';
import '../providers/game_center_providers.dart';
import '../widgets/game_center_widgets.dart';

/// Profesyonel Oyun Merkezi — canlifal.com jeton ve skor API'leriyle entegre.
class GameCenterPage extends ConsumerWidget {
  const GameCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jeton = ref.watch(gameCenterJetonProvider);
    final leaderboard = ref.watch(
      gameCenterLeaderboardProvider(LeaderboardPeriod.weekly),
    );
    final liveRooms = ref.watch(gameCenterLiveRoomsProvider);

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
            const SizedBox(height: 22),
            GameCenterSectionHeader(
              title: 'Popüler Oyunlar',
              trailing: TextButton(
                onPressed: () => context.push('/games-hub/leaderboard'),
                child: const Text('Liderlik'),
              ),
            ),
            GameCenterPopularRow(
              items: GameCenterCatalog.popular,
              onTap: (item) => _openGame(context, ref, item),
            ),
            const SizedBox(height: 20),
            GameCenterSectionHeader(title: 'Canlı Oyunlar'),
            ...GameCenterCatalog.live.map((item) {
              final roomCount = liveRooms.valueOrNull
                  ?.where((r) => r.gameId.contains(item.id.split('-').first))
                  .length;
              return GameCenterLiveCard(
                item: item,
                playerCount: roomCount ?? item.liveCount,
                onJoin: () => _openLiveGame(context, ref, item),
              );
            }),
            const SizedBox(height: 8),
            GameCenterSectionHeader(title: 'Ödüllü Oyunlar'),
            ...GameCenterCatalog.rewarded.map(
              (item) => GameCenterRewardCard(
                item: item,
                onTap: () => _openGame(context, ref, item),
              ),
            ),
            const SizedBox(height: 16),
            _LeaderboardTeaser(
              entries: leaderboard.valueOrNull ?? const [],
              isLoading: leaderboard.isLoading,
              onTap: () => context.push('/games-hub/leaderboard'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/games-hub/lobby'),
              icon: const Icon(Icons.hub_rounded),
              label: const Text('Klasik oyun lobisi (API odaları)'),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _openGame(
    BuildContext context,
    WidgetRef ref,
    GameCenterItem item,
  ) async {
    if (item.jetonCost > 0) {
      final balance = await ref.read(gameCenterJetonProvider.future);
      if (!context.mounted) return;
      if (balance < item.jetonCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yetersiz jeton (${item.jetonCost} gerekli)'),
            action: SnackBarAction(
              label: 'Yükle',
              onPressed: () => context.push('/jeton-store'),
            ),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    context.push(item.route);
  }

  Future<void> _openLiveGame(
    BuildContext context,
    WidgetRef ref,
    GameCenterItem item,
  ) async {
    await _openGame(context, ref, item);
  }
}

class _LeaderboardTeaser extends StatelessWidget {
  const _LeaderboardTeaser({
    required this.entries,
    required this.isLoading,
    required this.onTap,
  });

  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const GameCenterLoadingBody();
    final top = entries.take(3).toList();
    if (top.isEmpty) {
      return GameCenterLeaderboardPreview(
        entries: const [
          LeaderboardEntry(id: '1', name: 'Merve', score: 28560, rank: 1),
          LeaderboardEntry(id: '2', name: 'Yiğit', score: 22450, rank: 2),
          LeaderboardEntry(id: '3', name: 'Ece', score: 18750, rank: 3),
        ],
        onSeeAll: onTap,
      );
    }
    return GameCenterLeaderboardPreview(entries: top, onSeeAll: onTap);
  }
}
