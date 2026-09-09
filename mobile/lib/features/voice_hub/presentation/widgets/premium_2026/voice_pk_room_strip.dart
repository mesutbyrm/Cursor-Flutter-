import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/widgets/broadcast_room/live_pk_score_bar.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../../domain/pk/pk_opponent_room_filter.dart';
import '../../providers/pk_battle_remote_provider.dart';

/// Oda içi PK durumu — aktif skor şeridi veya bekleyen davet metni.
/// Davet popup'ı uygulama geneli `VoicePkInviteListener` ile gösterilir.
class VoicePkRoomStrip extends ConsumerStatefulWidget {
  const VoicePkRoomStrip({
    super.key,
    required this.room,
    required this.onOpenPk,
    this.onEndPk,
  });

  final VoiceRoomEntity room;
  final VoidCallback onOpenPk;
  final Future<void> Function(PkBattleRemote remote)? onEndPk;

  @override
  ConsumerState<VoicePkRoomStrip> createState() => _VoicePkRoomStripState();
}

class _VoicePkRoomStripState extends ConsumerState<VoicePkRoomStrip> {
  Timer? _tick;
  int? _displaySeconds;
  String? _battleId;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _syncTimer(PkBattleRemote? remote) {
    if (remote == null || !remote.isActive) {
      _tick?.cancel();
      _tick = null;
      _displaySeconds = null;
      _battleId = null;
      return;
    }
    if (_battleId != remote.id || _displaySeconds == null) {
      _battleId = remote.id;
      _displaySeconds = remote.secondsLeft;
    } else if ((_displaySeconds! - remote.secondsLeft).abs() > 4) {
      _displaySeconds = remote.secondsLeft;
    }
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = (_displaySeconds ?? 0) - 1;
      setState(() => _displaySeconds = next < 0 ? 0 : next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(pkBattleForRoomProvider(widget.room));
    _syncTimer(remote);

    if (remote == null || remote.isEnded) return const SizedBox.shrink();

    if (remote.isPending) {
      final isChallenger = isPkChallengerRoom(remote, widget.room);
      if (!isChallenger) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.sports_mma_outlined, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PK daveti gönderildi — rakip kabul edene kadar bekleniyor…',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenPk,
                  child: const Text('Detay'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!remote.isActive) return const SizedBox.shrink();

    final isChallengerSide = isPkChallengerRoom(remote, widget.room);
    final leftScore =
        isChallengerSide ? remote.challengerScore : remote.opponentScore;
    final rightScore =
        isChallengerSide ? remote.opponentScore : remote.challengerScore;
    final leftName = remote.challenger?.displayName ?? 'Biz';
    final rightName = remote.opponent?.displayName ?? 'Rakip';
    final seconds = _displaySeconds ?? remote.secondsLeft;
    final timerLabel = _formatPkSeconds(seconds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: GestureDetector(
        onTap: widget.onOpenPk,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$leftName vs $rightName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  timerLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            LivePkScoreBar(
              leftScore: leftScore,
              rightScore: rightScore,
              status: 'active',
              isHost: widget.onEndPk != null,
              onEnd: widget.onEndPk == null ? null : () => widget.onEndPk!(remote),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPkSeconds(int seconds) {
  final s = seconds.clamp(0, 86400);
  final m = s ~/ 60;
  final r = s % 60;
  return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
}
