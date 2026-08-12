import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/widgets/broadcast_room/live_pk_score_bar.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../../domain/pk/pk_opponent_room_filter.dart';
import '../../providers/pk_battle_provider.dart';
import '../../providers/pk_battle_remote_provider.dart';

/// Oda içi PK durumu — aktif skor şeridi veya bekleyen davet metni.
/// Davet popup'ı uygulama geneli `VoicePkInviteListener` ile gösterilir.
class VoicePkRoomStrip extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(pkBattleRemoteProvider);
    if (remote == null || remote.isEnded) return const SizedBox.shrink();

    if (remote.isPending) {
      final isChallenger = isPkChallengerRoom(remote, room);
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
                  onPressed: onOpenPk,
                  child: const Text('Detay'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!remote.isActive) return const SizedBox.shrink();

    final pk = ref.watch(pkBattleProvider);
    final leftName = pk.left.leader?.name ?? 'Biz';
    final rightName = pk.right.leader?.name ?? 'Rakip';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: GestureDetector(
        onTap: onOpenPk,
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
                  pk.timerLabel,
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
              leftScore: pk.left.score,
              rightScore: pk.right.score,
              status: 'active',
              isHost: onEndPk != null,
              onEnd: onEndPk == null ? null : () => onEndPk!(remote),
            ),
          ],
        ),
      ),
    );
  }
}
