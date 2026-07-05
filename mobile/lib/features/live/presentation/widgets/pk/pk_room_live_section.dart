import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/pk/pk_room_models.dart';
import '../../providers/pk_room_providers.dart';
import 'pk_room_control_bar.dart';
import 'pk_room_score_overlay.dart';

/// Canlı yayında PK Faz 2 (çoklu misafir / takım) katmanı — tek satırla bağlanır.
/// Yayına ait aktif bir çoklu/takım PK maçı yoksa hiçbir şey göstermez;
/// mevcut 1v1 PK ve guest-grid akışını etkilemez.
class PkRoomLiveSection extends ConsumerWidget {
  const PkRoomLiveSection({
    super.key,
    required this.streamId,
    required this.myUserId,
  });

  final String streamId;
  final String myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (streamId.isEmpty) return const SizedBox.shrink();
    final discovered = ref.watch(activePkRoomProvider(streamId)).asData?.value;
    if (discovered == null || discovered.mode == PkRoomMode.oneVsOne) {
      return const SizedBox.shrink();
    }
    final matchId = discovered.id;
    if (matchId.isEmpty) return const SizedBox.shrink();

    // Canlı takibe al (poll) — keşif sonrası state'i besle.
    final live = ref.watch(pkRoomProvider(matchId)) ?? discovered;
    if (live.mode == PkRoomMode.oneVsOne) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PkRoomScoreOverlay(matchId: matchId),
        PkRoomControlBar(
          matchId: matchId,
          myUserId: myUserId,
          myStreamId: streamId,
        ),
      ],
    );
  }
}
