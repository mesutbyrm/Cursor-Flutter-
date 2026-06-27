import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../voice_hub/presentation/pages/voice_gold_vip_page.dart';
import '../../domain/voice_room_access.dart';
import '../providers/vip_membership_provider.dart';
import '../widgets/vip_locked_room_sheet.dart';

/// VIP / şifreli oda kapısı — tek giriş noktası.
Future<void> openVoiceRoomWithVipGate(
  BuildContext context,
  WidgetRef ref,
  VoiceRoomEntity room, {
  bool skipVipGateForOwner = false,
}) async {
  if (room.isPasswordLockedRoom) {
    final ok = await showVipLockedRoomSheet(context, ref, room: room);
    if (!ok || !context.mounted) return;
  }

  final me = ref.read(currentUserIdProvider);
  final isOwner = skipVipGateForOwner &&
      me != null &&
      me.isNotEmpty &&
      room.ownerId != null &&
      room.ownerId == me;

  final tier = ref.read(vipTierProvider);
  if (!isOwner && room.isVipGoldRoom && !canEnterVipRoom(tier)) {
    await VoiceGoldVipPage.show(
      context,
      room: room,
      onJoinRoom: () {
        if (context.mounted) {
          VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
          context.push('/voice-room/${room.apiRoomKey}', extra: room);
        }
      },
    );
    return;
  }

  if (!context.mounted) return;
  VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
  context.push('/voice-room/${room.apiRoomKey}', extra: room);
}
