import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/game_models.dart';
import '../providers/game_providers.dart';

class GamesHubPage extends ConsumerWidget {
  const GamesHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(gameCatalogProvider);
    final rooms = ref.watch(gameRoomsProvider);
    final leaderboard = ref.watch(gameLeaderboardProvider);
    final miniScores = ref.watch(gameMiniScoresProvider);
    final tournaments = ref.watch(gameTournamentsProvider);

    return DiscoverSubPage(
      title: 'Oyunlar',
      subtitle: 'Canlifal.com oyun lobisi, odalar ve skor tabloları',
      onRefresh: () => _refresh(ref),
      body: RefreshIndicator(
        color: context.accentPink,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            _Hero(),
            const SizedBox(height: 16),
            _ScoreStrip(
              leaderboard: leaderboard.valueOrNull ?? const [],
              miniScores: miniScores.valueOrNull ?? const [],
              tournaments: tournaments.valueOrNull ?? const [],
            ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Oyun listesi',
              trailing: catalog.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            catalog.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: ApiException.userMessage(e)),
              data: (items) => _CatalogGrid(items: items),
            ),
            const SizedBox(height: 18),
            const _SectionTitle(title: 'Açık odalar'),
            rooms.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: ApiException.userMessage(e)),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyCard(
                    message:
                        'Açık oyun odası yok. Bir oyun seçip oda oluşturabilirsin.',
                  );
                }
                return Column(
                  children: [
                    for (final room in items.take(20)) _RoomTile(room: room),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(gameCatalogProvider);
    ref.invalidate(gameRoomsProvider);
    ref.invalidate(gameLeaderboardProvider);
    ref.invalidate(gameMiniScoresProvider);
    ref.invalidate(gameTournamentsProvider);
    await Future.wait([
      ref.read(gameCatalogProvider.future),
      ref.read(gameRoomsProvider.future),
    ]);
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: context.colors.brandGradient,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_esports_rounded,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Webdeki oyunlar Flutter içinde listelenir; oda oluşturma, katılma, skor tabloları ve oda durumu 5 sn polling ile takip edilir.',
              style: const TextStyle(
                color: Colors.white,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({required this.items});

  final List<GameCatalogItem> items;

  @override
  Widget build(BuildContext context) {
    final multiplayer = items
        .where((e) => e.kind == GameKind.multiplayer)
        .toList();
    final mini = items.where((e) => e.kind == GameKind.mini).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GameGroup(title: 'Çok oyunculu', items: multiplayer),
        const SizedBox(height: 14),
        _GameGroup(title: 'Mini oyunlar', items: mini),
      ],
    );
  }
}

class _GameGroup extends StatelessWidget {
  const _GameGroup({required this.title, required this.items});

  final String title;
  final List<GameCatalogItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.92,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final game = items[index];
            return _GameTile(game: game);
          },
        ),
      ],
    );
  }
}

class _GameTile extends ConsumerWidget {
  const _GameTile({required this.game});

  final GameCatalogItem game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showGameActions(context, ref, game),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(game.icon, color: context.colors.primary, size: 28),
              const SizedBox(height: 8),
              Text(
                game.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (game.jetonCost > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${game.jetonCost} Jeton',
                  style: TextStyle(
                    color: context.coinGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGameActions(
    BuildContext context,
    WidgetRef ref,
    GameCatalogItem game,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                game.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                game.subtitle ??
                    (game.kind == GameKind.mini
                        ? 'Mini oyun skorunu kaydet ve sıralamada yüksel.'
                        : 'Web oyun odası API ile oda oluştur, eşleş ve sonucu takip et.'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _createRoom(ctx, ref, game),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Oda oluştur'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _autoMatch(ctx, ref, game),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Otomatik eşleş'),
              ),
              if (game.kind == GameKind.mini) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(gameRemoteProvider)
                        .saveMiniScore(gameId: game.id, score: 0);
                    if (ctx.mounted) Navigator.pop(ctx);
                    ref.invalidate(gameMiniScoresProvider);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Mini skor kaydı dene'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createRoom(
    BuildContext context,
    WidgetRef ref,
    GameCatalogItem game,
  ) async {
    try {
      final room = await ref.read(gameRemoteProvider).createRoom(game);
      ref.invalidate(gameRoomsProvider);
      if (!context.mounted) return;
      Navigator.pop(context);
      if (room != null) {
        context.push(
          '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    }
  }

  Future<void> _autoMatch(
    BuildContext context,
    WidgetRef ref,
    GameCatalogItem game,
  ) async {
    try {
      final room = await ref.read(gameRemoteProvider).autoMatch(game);
      ref.invalidate(gameRoomsProvider);
      if (!context.mounted) return;
      Navigator.pop(context);
      if (room != null) {
        context.push(
          '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    }
  }
}

class _RoomTile extends ConsumerWidget {
  const _RoomTile({required this.room});

  final GameRoomItem room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.meeting_room_rounded),
        title: Text(room.title),
        subtitle: Text(
          '${room.status} • ${room.playerCount}/${room.maxPlayers} oyuncu • ${room.viewerCount} izleyici',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          await ref.read(gameRemoteProvider).joinRoom(room.id);
          ref.invalidate(gameRoomsProvider);
          if (context.mounted) {
            context.push(
              '/games-room/${room.id}?title=${Uri.encodeComponent(room.title)}',
            );
          }
        },
      ),
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({
    required this.leaderboard,
    required this.miniScores,
    required this.tournaments,
  });

  final List<GameScoreItem> leaderboard;
  final List<GameScoreItem> miniScores;
  final List<GameScoreItem> tournaments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScoreCard(title: 'Liderlik', value: '${leaderboard.length}'),
        const SizedBox(width: 10),
        _ScoreCard(title: 'Mini skor', value: '${miniScores.length}'),
        const SizedBox(width: 10),
        _ScoreCard(title: 'Turnuva', value: '${tournaments.length}'),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _EmptyCard(message: message);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}
