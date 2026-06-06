import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../voice_hub/presentation/providers/pk_battle_provider.dart';
import '../../../voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_gift_event.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../gifts/providers/live_gift_providers.dart';
import '../widgets/broadcast_room/live_pk_score_bar.dart';

/// Canlı yayın split-screen PK — sol kendi yayın, sağ rakip.
class LivePkBattlePage extends ConsumerStatefulWidget {
  const LivePkBattlePage({
    super.key,
    required this.session,
    this.opponentStream,
  });

  final LiveBroadcastSession session;
  final LiveStreamEntity? opponentStream;

  @override
  ConsumerState<LivePkBattlePage> createState() => _LivePkBattlePageState();
}

class _LivePkBattlePageState extends ConsumerState<LivePkBattlePage> {
  String? get _streamId => widget.session.streamId?.trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final streamId = _streamId;
    if (streamId == null || streamId.isEmpty) return;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    await remote.loadStreamBattle(streamId);
    remote.connectSocket(streamId: streamId, battleId: ref.read(pkBattleRemoteProvider)?.id);
    ref.read(liveGiftSocketBridgeProvider).connect(
      streamId: streamId,
      onEvent: _onGift,
      onPkBattle: (battle) {
        final remote = PkBattleRemote.fromJson(battle);
        if (remote.id.isEmpty) return;
        ref.read(pkBattleProvider.notifier).applyRemoteBattle(remote);
      },
    );
  }

  void _onGift(LiveGiftEvent event) {
    if (!mounted) return;
    final challengerId = ref.read(pkBattleRemoteProvider)?.challengerId;
    final toLeft = challengerId == null || event.senderId == challengerId;
    ref.read(pkBattleProvider.notifier).applyGift(event, toLeft: toLeft);
  }

  @override
  void dispose() {
    ref.read(liveGiftSocketBridgeProvider).disconnect();
    ref.read(pkBattleRemoteProvider.notifier).disconnectSocket();
    super.dispose();
  }

  Future<void> _accept() async {
    final id = ref.read(pkBattleRemoteProvider)?.id;
    if (id == null) return;
    await ref.read(pkBattleRemoteProvider.notifier).accept(id);
  }

  Future<void> _reject() async {
    final id = ref.read(pkBattleRemoteProvider)?.id;
    if (id == null) return;
    await ref.read(pkBattleRemoteProvider.notifier).reject(id);
    if (mounted) context.pop();
  }

  Future<void> _end() async {
    final id = ref.read(pkBattleRemoteProvider)?.id;
    if (id == null) return;
    await ref.read(pkBattleRemoteProvider.notifier).end(id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(pkBattleRemoteProvider);
    final pk = ref.watch(pkBattleProvider);
    final leftScore = remote?.challengerScore ?? pk.left.total;
    final rightScore = remote?.opponentScore ?? pk.right.total;
    final status = remote?.status ?? 'active';
    final isHost = widget.session.isHost;
    final leftName = widget.session.streamerName ?? 'Sen';
    final rightName = widget.opponentStream?.streamerName ??
        remote?.opponent?.displayName ??
        'Rakip';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Canlı PK'),
        actions: [
          if (remote?.secondsLeft != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${remote!.secondsLeft ~/ 60}:${(remote.secondsLeft % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: LivePkScoreBar(
              leftScore: leftScore,
              rightScore: rightScore,
              status: status,
              isHost: isHost,
              onAccept: _accept,
              onReject: _reject,
              onEnd: _end,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _PkVideoPane(label: leftName, accent: Colors.pinkAccent)),
                Container(width: 2, color: Colors.white24),
                Expanded(child: _PkVideoPane(label: rightName, accent: Colors.cyanAccent)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Geri'),
                  ),
                ),
                const SizedBox(width: 12),
                if (remote?.isActive == true)
                  Expanded(
                    child: FilledButton(
                      onPressed: isHost ? _end : null,
                      child: const Text('PK Bitir'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PkVideoPane extends StatelessWidget {
  const _PkVideoPane({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF120A1E),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.15),
                  Colors.black,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_rounded, size: 48, color: accent),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
