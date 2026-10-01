import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../pk/presentation/providers/pk_session_notifier.dart';
import '../../../../pk/presentation/widgets/pk_pending_banner.dart';
import '../../../../pk/presentation/widgets/pk_score_bar.dart';
import '../../../../pk/data/pk_models.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../../domain/pk/pk_opponent_room_filter.dart';
import '../../../domain/pk/pk_team_label_helper.dart';
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
    final remote = ref.watch(pkBattleForRoomProvider(room));
    if (remote == null || remote.isEnded || remote.isInRoomUser) {
      return const SizedBox.shrink(); // oda içi PK: VoicePkRoomPanel gösterir
    }

    if (remote.isPending && !remote.isActive) {
      final isChallenger = isPkChallengerRoom(remote, room);
      if (!isChallenger) return const SizedBox.shrink();
      final key =
          room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: PkPendingBanner(
          args: PkSessionArgs(contextId: key, kind: PkContextKind.voice),
        ),
      );
    }

    if (!remote.isActive) return const SizedBox.shrink();

    final userId = ref.watch(authControllerProvider).valueOrNull?.id;
    final presentation = resolveVoicePkTeamPresentation(
      battle: remote,
      currentUserId: userId,
      room: room,
    );
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
                    '${presentation.leftLabel} vs ${presentation.rightLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            PkScoreBar(
              battle: PkBattle(
                id: remote.id,
                status: remote.status == 'paused'
                    ? PkStatus.paused
                    : PkStatus.active,
                score1: presentation.leftScore,
                score2: presentation.rightScore,
              ),
              leftLabel: presentation.leftLabel,
              rightLabel: presentation.rightLabel,
              remaining: Duration(seconds: remote.resolvedSecondsLeft()),
            ),
          ],
        ),
      ),
    );
  }
}
