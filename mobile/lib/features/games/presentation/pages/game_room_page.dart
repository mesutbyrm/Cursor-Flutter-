import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/game_models.dart';
import '../../domain/game_state_parser.dart';
import '../providers/game_providers.dart';
import '../widgets/game_board_widgets.dart';

class GameRoomPage extends ConsumerStatefulWidget {
  const GameRoomPage({
    super.key,
    required this.roomId,
    this.title,
    this.gameHint,
  });

  final String roomId;
  final String? title;
  final String? gameHint;

  @override
  ConsumerState<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends ConsumerState<GameRoomPage>
    with GameRoomLifecycleMixin {
  final _chat = TextEditingController();
  var _moveBusy = false;

  @override
  String get lifecycleRoomId => widget.roomId;

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  Future<void> _sendMove(Map<String, dynamic> move) async {
    if (_moveBusy) return;
    setState(() => _moveBusy = true);
    try {
      await ref
          .read(gameRoomControllerProvider(widget.roomId).notifier)
          .sendMove(move);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _moveBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final state = ref.watch(gameRoomControllerProvider(widget.roomId));
    return DiscoverSubPage(
      title: widget.title ?? 'Oyun odası',
      subtitle: 'Sunucu state canonical — 5 sn polling',
      onRefresh: () => ref
          .read(gameRoomControllerProvider(widget.roomId).notifier)
          .refresh(),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          state.when(
            loading: () => const PremiumSkeleton(
              width: double.infinity,
              height: 320,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            error: (e, _) => _ErrorCard(
              message: ApiException.userMessage(e),
              onRetry: () => ref
                  .read(gameRoomControllerProvider(widget.roomId).notifier)
                  .refresh(),
            ),
            data: (snapshot) => _RoomBody(
              snapshot: snapshot,
              userId: userId,
              gameHint: widget.gameHint,
              moveBusy: _moveBusy,
              onMove: _sendMove,
            ),
          ),
          const SizedBox(height: 14),
          _ChatPanel(roomId: widget.roomId, controller: _chat),
        ],
      ),
    );
  }
}

class _RoomBody extends StatelessWidget {
  const _RoomBody({
    required this.snapshot,
    required this.userId,
    required this.gameHint,
    required this.moveBusy,
    required this.onMove,
  });

  final GameRoomStateSnapshot snapshot;
  final String? userId;
  final String? gameHint;
  final bool moveBusy;
  final Future<void> Function(Map<String, dynamic> move) onMove;

  @override
  Widget build(BuildContext context) {
    final raw = snapshot.raw;
    final gameType = GameStateParser.normalizeGameType(
      GameStateParser.gameType(raw) ?? gameHint,
    );
    final myTurn = GameStateParser.isMyTurn(raw: raw, userId: userId);
    final finished = GameStateParser.isFinished(raw);
    final winner = GameStateParser.winner(raw) ?? snapshot.result;
    final scores = GameStateParser.parseScores(raw);
    final players = GameStateParser.uniquePlayers(raw);
    final board = GameStateParser.parseBoard(raw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard(
          status: GameStateParser.statusLabel(raw),
          turnLabel: myTurn
              ? 'Senin sıran'
              : snapshot.turn == null
              ? 'Sıra bekleniyor'
              : 'Rakibin sırası',
          winner: winner,
          scores: scores,
        ),
        if (players.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PlayersRow(players: players, currentUserId: userId),
        ],
        const SizedBox(height: 12),
        if (GameStateParser.supportsBoard(gameType))
          GameBoardPanel(
            board: board,
            enabled: myTurn && !finished && !moveBusy,
            onCellTap: (index) => onMove({
              'type': 'move',
              'action': 'move',
              'index': index,
              'row': index ~/ 3,
              'col': index % 3,
              if (gameType.isNotEmpty) 'gameType': gameType,
            }),
          )
        else
          _GenericStateCard(snapshot: snapshot),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: moveBusy
                    ? null
                    : () => onMove({'action': 'refresh'}),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yenile'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.turnLabel,
    this.winner,
    required this.scores,
  });

  final String status;
  final String turnLabel;
  final String? winner;
  final Map<String, int> scores;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: context.colors.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_esports_rounded, color: context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  turnLabel,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (winner != null && winner!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Kazanan: $winner',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              scores.entries.map((e) => '${e.key}: ${e.value}').join(' · '),
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayersRow extends StatelessWidget {
  const _PlayersRow({required this.players, required this.currentUserId});

  final List<Map<String, dynamic>> players;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: players.map((player) {
        final id = player['id']?.toString() ?? '';
        final name = player['name']?.toString() ?? id;
        final isMe = id.isNotEmpty && id == currentUserId;
        return Chip(
          avatar: CircleAvatar(
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
          ),
          label: Text(isMe ? '$name (Sen)' : name),
        );
      }).toList(),
    );
  }
}

class _GenericStateCard extends StatelessWidget {
  const _GenericStateCard({required this.snapshot});

  final GameRoomStateSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: context.colors.surface.withValues(alpha: 0.65),
        border: Border.all(color: context.colors.outline.withValues(alpha: 0.2)),
      ),
      child: Text(
        snapshot.raw.isEmpty
            ? 'Sunucu oda state alanı döndürmedi. Backend canonical state bekleniyor.'
            : 'Oyun tahtası bu oyun tipi için native UI gerektiriyor. '
                  'Hamleler backend state ile senkron kalır.',
        style: TextStyle(
          color: context.colors.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.scheme.error.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Oyun başlatılamadı',
            style: TextStyle(
              color: context.scheme.error,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}

class _ChatPanel extends ConsumerWidget {
  const _ChatPanel({required this.roomId, required this.controller});

  final String roomId;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Oyun sohbeti mesajı',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                controller.clear();
                ref
                    .read(gameRoomControllerProvider(roomId).notifier)
                    .sendChat(text);
              },
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
