import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../providers/pk_battle_remote_provider.dart';
import 'voice_pk_room_strip.dart';

/// Oda içi PK şeridi — davet popup'ı `VoicePkInviteListener` üzerinden.
class VoicePkInviteBanner extends ConsumerWidget {
  const VoicePkInviteBanner({
    super.key,
    required this.room,
    required this.liveKey,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    return VoicePkRoomStrip(
      room: room,
      onOpenPk: () {
        if (key.isEmpty) return;
        context.push('/voice-room/$key/pk', extra: room);
      },
      onEndPk: isOwner
          ? (remote) async {
              final roomKey =
                  room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
              final battleId = remote.effectiveId;
              if (battleId.isEmpty || roomKey.isEmpty) return;
              await ref.read(pkBattleRemoteProvider.notifier).end(
                    battleId,
                    roomId: roomKey,
                    alternateRoomId:
                        room.slug != roomKey ? room.slug : null,
                  );
            }
          : null,
    );
  }
}
