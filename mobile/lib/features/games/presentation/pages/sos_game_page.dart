import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/diagnostics/cf_diag.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/sos/sos_game.dart';
import '../providers/game_providers.dart';

/// SOS masası — `GET /api/games/sos/{id}` (2 sn yoklama, web ile aynı),
/// hamle `PATCH` (`{row, col, letter}`; yapay zekâ masasında `aiMoves`).
class SosGamePage extends ConsumerStatefulWidget {
  const SosGamePage({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<SosGamePage> createState() => _SosGamePageState();
}

class _SosGamePageState extends ConsumerState<SosGamePage> {
  static const _pollInterval = Duration(seconds: 2);

  SosGameState? _game;
  Object? _error;
  Timer? _poll;
  var _busy = false;
  var _letter = 'S';

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(_pollInterval, (_) {
      if (!_busy && !(_game?.isFinished ?? false)) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final g = await ref.read(gameRemoteProvider).fetchSosGame(widget.gameId);
      if (!mounted || _busy) return;
      setState(() {
        _game = g;
        _error = null;
      });
    } catch (e, st) {
      if (silent) {
        CfDiag.recordError(e, st, category: CfCategory.network);
        return;
      }
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(Future<SosGameState> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final g = await action();
      if (mounted) setState(() => _game = g);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tapCell(SosGameState g, String userId, int row, int col) {
    final remote = ref.read(gameRemoteProvider);
    final body = g.isAI
        ? SosEngine.playAgainstAi(
            game: g,
            userId: userId,
            row: row,
            col: col,
            letter: _letter,
          )
        : {'row': row, 'col': col, 'letter': _letter};
    _run(() => remote.sendSosMove(widget.gameId, body));
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final g = _game;
    return Scaffold(
      body: DiscoverSubPage(
        title: 'SOS',
        subtitle: g == null ? null : '${g.gridSize} × ${g.gridSize}',
        onRefresh: _load,
        body: g == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(ApiException.userMessage(_error!)),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Yenile'),
                          ),
                        ],
                      ),
              )
            : _body(context, g, userId),
      ),
    );
  }

  Widget _body(BuildContext context, SosGameState g, String? userId) {
    final me = g.playerNumberOf(userId);
    final myTurn = g.isMyTurn(userId) && !_busy;
    final status = switch (g.status) {
      'waiting' => me == null ? 'Rakip bekliyor' : 'Rakip bekleniyor…',
      'completed' => g.winnerId == null
          ? (g.isAI && g.player2Score > g.player1Score
              ? 'Yapay zekâ kazandı'
              : 'Berabere')
          : (g.winnerId == userId ? 'Kazandın!' : 'Kaybettin'),
      'cancelled' => 'Oyun iptal edildi',
      _ => myTurn
          ? 'Senin sıran'
          : (me == null ? 'İzliyorsun' : 'Rakibin sırası'),
    };
    final onLine = <String>{
      for (final l in g.lines)
        for (var i = 0; i < 6; i += 2) '${l[i]}-${l[i + 1]}',
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _ScoreChip(
                name: g.player1Name,
                score: g.player1Score,
                active: g.isActive && g.currentTurn == 1,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreChip(
                name: g.player2Name,
                score: g.player2Score,
                active: g.isActive && g.currentTurn == 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          status,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        if (g.isWaiting && me == null && userId != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref.read(gameRemoteProvider).joinSosGame(g.id),
                    ),
            child: const Text('Oyuna katıl'),
          ),
        ],
        const SizedBox(height: 12),
        _SosBoard(
          game: g,
          highlighted: onLine,
          enabled: myTurn && userId != null,
          onTap: (r, c) => _tapCell(g, userId!, r, c),
        ),
        const SizedBox(height: 12),
        if (me != null && g.isActive)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'S', label: Text('S')),
              ButtonSegment(value: 'O', label: Text('O')),
            ],
            selected: {_letter},
            onSelectionChanged: (s) => setState(() => _letter = s.first),
          ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.name,
    required this.score,
    required this.active,
  });

  final String name;
  final int score;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: active ? color : Colors.white.withValues(alpha: 0.12),
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            '$score',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _SosBoard extends StatelessWidget {
  const _SosBoard({
    required this.game,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  final SosGameState game;
  final Set<String> highlighted;
  final bool enabled;
  final void Function(int row, int col) onTap;

  @override
  Widget build(BuildContext context) {
    final n = game.gridSize;
    final primary = Theme.of(context).colorScheme.primary;
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: n * n,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: n,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemBuilder: (context, i) {
          final r = i ~/ n, c = i % n;
          final value = game.board[r][c];
          final lit = highlighted.contains('$r-$c');
          return InkWell(
            onTap: enabled && value.isEmpty ? () => onTap(r, c) : null,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: lit
                    ? primary.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.07),
              ),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: value == 'S'
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFEC4899),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
