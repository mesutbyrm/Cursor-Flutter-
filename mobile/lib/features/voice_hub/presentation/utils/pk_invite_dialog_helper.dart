import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_session_registry.dart';
import '../widgets/premium_2026/voice_pk_invite_center_modal.dart';
import 'voice_room_session_utils.dart';

/// Aynı PK daveti için çift popup önlenir (listener + oda banner).
final pkSeenInviteIdsProvider = StateProvider<Set<String>>((ref) => {});

void clearPkInviteDedup(WidgetRef ref, String inviteId) {
  final id = inviteId.trim();
  if (id.isEmpty) return;
  ref.read(pkSeenInviteIdsProvider.notifier).update(
        (seen) => seen.where((e) => e != id).toSet(),
      );
}

/// Gelen PK daveti için oda eşlemesi.
VoiceRoomEntity? resolvePkInviteTargetRoom(
  WidgetRef ref,
  PkBattleRemote battle,
  String userId,
) {
  final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
  VoiceRoomEntity? activeRoom;
  if (activeKey.isNotEmpty) {
    activeRoom = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull;
  }
  final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
  final user = ref.read(authControllerProvider).valueOrNull;
  return pickPkInviteTargetRoom(
    battle: battle,
    userId: userId,
    rooms: rooms,
    activeRoom: activeRoom,
    username: user?.username,
  );
}

String pkChallengerRoomLabel(WidgetRef ref, PkBattleRemote battle) {
  final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
  return pkChallengerRoomLabelFromRooms(battle, rooms);
}

/// Hedef odada popup: «X odası size PK isteği attı».
Future<void> showPkInviteDialog(
  BuildContext context,
  WidgetRef ref, {
  required PkBattleRemote battle,
  required VoiceRoomEntity room,
}) async {
  final inviteId = battle.effectiveId;
  if (inviteId.isEmpty) return;

  final seen = ref.read(pkSeenInviteIdsProvider);
  if (seen.contains(inviteId)) return;
  ref.read(pkSeenInviteIdsProvider.notifier).state = {...seen, inviteId};

  final challengerLabel = pkChallengerRoomLabel(ref, battle);
  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final alt = room.slug != key ? room.slug : null;
  final remote = ref.read(pkBattleRemoteProvider.notifier);

  final accept = await showVoicePkInviteCenterModal(
    context: context,
    challengerLabel: challengerLabel,
    battle: battle,
  ).timeout(
    const Duration(seconds: 30),
    onTimeout: () => null,
  );

  if (!context.mounted) {
    clearPkInviteDedup(ref, inviteId);
    return;
  }

  unawaited(
    Future<void>.microtask(() async {
      try {
        if (accept == null) {
          PkEventLog.reject(inviteId: inviteId);
          await remote.reject(inviteId, roomId: key, alternateRoomId: alt);
          remote.clear();
          clearPkInviteDedup(ref, inviteId);
          return;
        }
        if (accept) {
          PkEventLog.acceptStart(inviteId: inviteId);
          await remote.accept(inviteId, roomId: key, alternateRoomId: alt);
          await prepareVoiceRoomSwitch(
            ref,
            nextLiveKey: key,
            source: 'pk_invite_accept',
          );
          final nav = rootNavigatorKey.currentContext;
          if (nav != null && nav.mounted) {
            VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
            GoRouter.of(nav).push('/voice-room/$key/pk', extra: room);
            ScaffoldMessenger.of(nav).showSnackBar(
              const SnackBar(content: Text('PK başladı')),
            );
          }
        } else {
          PkEventLog.reject(inviteId: inviteId);
          await remote.reject(inviteId, roomId: key, alternateRoomId: alt);
          remote.clear();
          clearPkInviteDedup(ref, inviteId);
          final nav = rootNavigatorKey.currentContext;
          if (nav != null && nav.mounted) {
            ScaffoldMessenger.of(nav).showSnackBar(
              const SnackBar(content: Text('PK daveti reddedildi')),
            );
          }
        }
      } catch (e) {
        clearPkInviteDedup(ref, inviteId);
        final nav = rootNavigatorKey.currentContext;
        if (nav != null && nav.mounted) {
          ScaffoldMessenger.of(nav).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
      }
    }),
  );
}
