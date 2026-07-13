import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../voice_hub/presentation/pages/voice_gold_vip_page.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';
import '../../../voice_hub/presentation/utils/voice_room_session_utils.dart';
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
    final isStaff = ref.read(staffAccessProvider).isSiteAdmin;
    if (isStaff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oda şifreli — yönetici olarak girildi')),
      );
    } else {
      final ok = await showVipLockedRoomSheet(context, ref, room: room);
      if (!ok || !context.mounted) return;
    }
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
          unawaited(_enterVoiceRoom(context, ref, room));
        }
      },
    );
    return;
  }

  if (!context.mounted) return;
  await _enterVoiceRoom(context, ref, room);
}

Future<void> _enterVoiceRoom(
  BuildContext context,
  WidgetRef ref,
  VoiceRoomEntity room,
) async {
  final nextKey = room.liveKey;
  final rooms = ref.read(voiceRoomsProvider).valueOrNull;
  if (rooms != null) {
    for (final r in rooms) {
      final key = r.liveKey;
      if (key.isEmpty || key == nextKey) continue;
      if (r.ownerId == ref.read(currentUserIdProvider)) {
        await teardownVoiceRoomBeforeSwitch(ref, liveKey: key);
      }
    }
  }

  VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
  if (!context.mounted) return;
  context.go('/voice-room/${room.apiRoomKey}', extra: room);
}
