import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/game_models.dart';
import '../providers/game_providers.dart';

class GameRoomPage extends ConsumerStatefulWidget {
  const GameRoomPage({super.key, required this.roomId, this.title});

  final String roomId;
  final String? title;

  @override
  ConsumerState<GameRoomPage> createState() => _GameRoomPageState();
}

class _GameRoomPageState extends ConsumerState<GameRoomPage> {
  final _chat = TextEditingController();

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameRoomControllerProvider(widget.roomId));
    return DiscoverSubPage(
      title: widget.title ?? 'Oyun odası',
      subtitle: '5 saniyede bir web API polling ile güncellenir',
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
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(ApiException.userMessage(e)),
              ),
            ),
            data: (snapshot) => _RoomStateCard(snapshot: snapshot),
          ),
          const SizedBox(height: 14),
          _MovePanel(roomId: widget.roomId),
          const SizedBox(height: 14),
          _ChatPanel(roomId: widget.roomId, controller: _chat),
        ],
      ),
    );
  }
}

class _RoomStateCard extends StatelessWidget {
  const _RoomStateCard({required this.snapshot});

  final GameRoomStateSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final raw = snapshot.raw;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_rounded, color: context.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Oda durumu',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  snapshot.status.toString().isEmpty
                      ? 'polling'
                      : snapshot.status.toString(),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (snapshot.turn != null)
              Text(
                'Sıra: ${snapshot.turn}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            if (snapshot.result != null)
              Text(
                'Sonuç: ${snapshot.result}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 12),
            Text(
              raw.isEmpty
                  ? 'Sunucu oda state alanı döndürmedi; polling açık.'
                  : const JsonEncoder.withIndent('  ').convert(raw),
              maxLines: 12,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            if (snapshot.chat.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Oyun sohbeti',
                style: TextStyle(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              for (final msg in snapshot.chat.take(5)) Text('• $msg'),
            ],
          ],
        ),
      ),
    );
  }
}

class _MovePanel extends ConsumerWidget {
  const _MovePanel({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hamle / sonuç kontrolü',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Web oyunları HTTP polling tabanlıdır. Flutter bu ekranda aynı oda state endpointini izler; hamle payload şekli oyun tipine göre backend tarafından yorumlanır.',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(gameRoomControllerProvider(roomId).notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Yenile'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => ref
                        .read(gameRoomControllerProvider(roomId).notifier)
                        .sendMove({
                          'clientMove': 'ping',
                          'at': DateTime.now().toIso8601String(),
                        }),
                    icon: const Icon(Icons.touch_app_rounded),
                    label: const Text('Hamle dene'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
