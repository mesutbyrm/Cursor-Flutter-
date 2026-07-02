import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../domain/okey101/okey101_models.dart';
import '../providers/game_providers.dart';
import 'widgets/okey101_tile_widget.dart';

/// 101 Okey oyun masası — HTTP polling ile çok oyunculu.
class Okey101RoomPage extends ConsumerStatefulWidget {
  const Okey101RoomPage({
    super.key,
    required this.roomId,
    this.title,
  });

  final String roomId;
  final String? title;

  @override
  ConsumerState<Okey101RoomPage> createState() => _Okey101RoomPageState();
}

class _Okey101RoomPageState extends ConsumerState<Okey101RoomPage> {
  String? _selectedTileId;
  final _chatCtrl = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _move(Map<String, dynamic> move) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(gameRoomControllerProvider(widget.roomId).notifier)
          .sendMove(move);
      if (mounted) setState(() => _selectedTileId = null);
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

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final state = ref.watch(gameRoomControllerProvider(widget.roomId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B3D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF065F46),
        foregroundColor: Colors.white,
        title: Text(widget.title ?? 'Okey 101'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref
                .read(gameRoomControllerProvider(widget.roomId).notifier)
                .refresh(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (snapshot) {
          final game = parseOkey101FromRoomRaw(snapshot.raw);
          if (game == null) {
            return const Center(
              child: Text(
                'Okey 101 durumu yüklenemedi',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return _Board(
            game: game,
            userId: userId,
            busy: _busy,
            selectedTileId: _selectedTileId,
            chatCtrl: _chatCtrl,
            roomId: widget.roomId,
            localFallback: snapshot.raw['localFallback'] == true,
            onSelectTile: (id) => setState(() => _selectedTileId = id),
            onMove: _move,
          );
        },
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({
    required this.game,
    required this.userId,
    required this.busy,
    required this.selectedTileId,
    required this.chatCtrl,
    required this.roomId,
    required this.localFallback,
    required this.onSelectTile,
    required this.onMove,
  });

  final Okey101PublicState game;
  final String? userId;
  final bool busy;
  final String? selectedTileId;
  final TextEditingController chatCtrl;
  final String roomId;
  final bool localFallback;
  final ValueChanged<String?> onSelectTile;
  final Future<void> Function(Map<String, dynamic>) onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = game.me;
    final myTurn = game.isMyTurn(userId);
    final isHost = userId != null && userId == game.hostUserId;
    final waiting = game.phase == 'waiting';
    final finished = game.phase == 'finished';

    return Column(
      children: [
        if (game.lastMove != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black26,
            child: Text(
              game.lastMove!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        if (localFallback)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.orange.withValues(alpha: 0.25),
            child: const Text(
              'Site oyun API uçları henüz hazır değil — yerel oda modu aktif.',
              style: TextStyle(color: Colors.amber, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _OpponentsRow(game: game, me: me),
                const Spacer(),
                _TableCenter(game: game),
                const Spacer(),
                if (waiting) ...[
                  Text(
                    '${game.players.length}/${game.maxPlayers} oyuncu bekleniyor',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  if (isHost)
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => onMove({'type': 'start'}),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Oyunu başlat'),
                    )
                  else
                    const Text(
                      'Oda sahibi oyunu başlatacak…',
                      style: TextStyle(color: Colors.white54),
                    ),
                ] else if (finished) ...[
                  Text(
                    '🎉 ${game.winnerName ?? 'Kazanan'} okey attı!',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ] else ...[
                  if (myTurn)
                    const Text(
                      'Sıra sende',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else
                    Text(
                      'Sıra: ${game.turnName ?? "…"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (myTurn) ...[
                        OutlinedButton(
                          onPressed: busy ? null : () => onMove({'type': 'draw'}),
                          child: const Text('Desteden çek'),
                        ),
                        OutlinedButton(
                          onPressed: busy || game.discardTop == null
                              ? null
                              : () => onMove({'type': 'takeDiscard'}),
                          child: const Text('Atılanı al'),
                        ),
                        if (me != null && !me.opened)
                          OutlinedButton(
                            onPressed: busy ||
                                    game.myHandPoints < game.openScoreTarget
                                ? null
                                : () => onMove({'type': 'open'}),
                            child: Text('101 Aç (${game.myHandPoints})'),
                          ),
                        FilledButton(
                          onPressed: busy || selectedTileId == null
                              ? null
                              : () => onMove({
                                    'type': 'discard',
                                    'tileId': selectedTileId,
                                  }),
                          child: const Text('Taş at'),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (me != null && !waiting)
                  _HandRack(
                    hand: me.hand,
                    okey: game.okey,
                    selectedTileId: selectedTileId,
                    onSelect: onSelectTile,
                  ),
              ],
            ),
          ),
        ),
        _ChatBar(roomId: roomId, controller: chatCtrl),
      ],
    );
  }
}

class _OpponentsRow extends StatelessWidget {
  const _OpponentsRow({required this.game, required this.me});

  final Okey101PublicState game;
  final Okey101PlayerView? me;

  @override
  Widget build(BuildContext context) {
    final others = game.players.where((p) => p.userId != me?.userId).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final p in others)
          Column(
            children: [
              CircleAvatar(
                backgroundColor: p.opened ? Colors.amber : Colors.white24,
                child: Text('${p.handCount}'),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 72,
                child: Text(
                  p.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: game.turnUserId == p.userId
                        ? Colors.amber
                        : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (p.penalty > 0)
                Text(
                  '${p.penalty} ceza',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                ),
            ],
          ),
      ],
    );
  }
}

class _TableCenter extends StatelessWidget {
  const _TableCenter({required this.game});

  final Okey101PublicState game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            const Text('Deste', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 6),
            Container(
              width: 52,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF14532D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                '${game.deckCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Column(
          children: [
            const Text('Gösterge / Okey', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 6),
            Row(
              children: [
                if (game.indicator != null)
                  Okey101TileWidget(tile: game.indicator!, okey: game.okey),
                if (game.okey != null) ...[
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white38),
                  Okey101TileWidget(tile: game.okey!, okey: game.okey),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(width: 24),
        Column(
          children: [
            const Text('Atık', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 6),
            if (game.discardTop != null)
              Okey101TileWidget(tile: game.discardTop!, okey: game.okey)
            else
              Container(
                width: 44,
                height: 62,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HandRack extends StatelessWidget {
  const _HandRack({
    required this.hand,
    required this.okey,
    required this.selectedTileId,
    required this.onSelect,
  });

  final List<Okey101Tile> hand;
  final Okey101Tile? okey;
  final String? selectedTileId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final sorted = [...hand]
      ..sort((a, b) {
        final c = a.color.index.compareTo(b.color.index);
        return c != 0 ? c : a.value.compareTo(b.value);
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tile in sorted)
              Okey101TileWidget(
                tile: tile,
                okey: okey,
                selected: tile.id == selectedTileId,
                onTap: () => onSelect(
                  tile.id == selectedTileId ? null : tile.id,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatBar extends ConsumerWidget {
  const _ChatBar({required this.roomId, required this.controller});

  final String roomId;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Oyun sohbeti…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
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
