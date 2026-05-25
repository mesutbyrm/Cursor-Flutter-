import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../voice_hub/presentation/pages/voice_gold_vip_page.dart';
import '../../domain/voice_room_access.dart';
import '../providers/vip_membership_provider.dart';
import '../widgets/vip_locked_room_sheet.dart';

/// VIP / şifreli oda kapısı — tek giriş noktası.
Future<void> openVoiceRoomWithVipGate(
  BuildContext context,
  WidgetRef ref,
  VoiceRoomEntity room,
) async {
  if (room.isPasswordLockedRoom) {
    final ok = await showVipLockedRoomSheet(context, ref, room: room);
    if (!ok || !context.mounted) return;
  }

  final tier = ref.read(vipTierProvider);
  if (room.isVipGoldRoom && !canEnterVipRoom(tier)) {
    await VoiceGoldVipPage.show(
      context,
      room: room,
      onJoinRoom: () {
        if (context.mounted) {
          context.push('/voice-room/${room.apiRoomKey}', extra: room);
        }
      },
    );
    return;
  }

  if (!context.mounted) return;
  context.push('/voice-room/${room.apiRoomKey}', extra: room);
}
