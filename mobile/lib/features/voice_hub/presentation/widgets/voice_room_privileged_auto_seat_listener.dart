import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_room_providers.dart';

/// Yetkili auto-seat — presence + sunucu izinleri değişince yeniden değerlendirir.
class VoiceRoomPrivilegedAutoSeatListener extends ConsumerWidget {
  const VoiceRoomPrivilegedAutoSeatListener({
    super.key,
    required this.roomKey,
    required this.child,
  });

  final String roomKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      voiceRoomLiveProvider(roomKey).select(
        (s) => (
          s.presence.length,
          s.serverPermissions?.role,
          s.serverPermissions?.isRoomOwner,
          s.serverPermissions?.canModerate,
          s.serverPermissions?.canGiveVoice,
          s.ownerId,
          s.selfInRoom,
        ),
      ),
      (prev, next) {
        if (prev == next) return;
        if (next.$7 != true) return;
        ref
            .read(voiceRoomLiveProvider(roomKey).notifier)
            .scheduleReactivePrivilegedAutoSeatFromUi();
      },
    );
    return child;
  }
}
