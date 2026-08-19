import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../../app/router/app_router.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_session_registry.dart';

/// Aynı PK daveti için çift popup önlenir (listener + oda banner).
final pkSeenInviteIdsProvider = StateProvider<Set<String>>((ref) => {});

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
  return pickPkInviteTargetRoom(
    battle: battle,
    userId: userId,
    rooms: rooms,
    activeRoom: activeRoom,
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
  final minutes = (battle.durationSeconds / 60).round();
  final durationHint = minutes > 0 ? '\nSüre: $minutes dk' : '';
  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final alt = room.slug != key ? room.slug : null;
  final remote = ref.read(pkBattleRemoteProvider.notifier);

  final accept = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
      content: Text(
        '$challengerLabel odası size PK isteği attı.$durationHint\nKabul ediyor musunuz?',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Reddet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Kabul Et'),
        ),
      ],
    ),
  ).timeout(
    const Duration(seconds: 30),
    onTimeout: () => null,
  );

  if (!context.mounted) return;

  unawaited(
    Future<void>.microtask(() async {
      try {
        if (accept == null) {
          PkEventLog.reject(inviteId: inviteId);
          await remote.reject(inviteId, roomId: key, alternateRoomId: alt);
          remote.clear();
          return;
        }
        if (accept) {
          PkEventLog.acceptStart(inviteId: inviteId);
          await remote.accept(inviteId, roomId: key, alternateRoomId: alt);
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
          final nav = rootNavigatorKey.currentContext;
          if (nav != null && nav.mounted) {
            ScaffoldMessenger.of(nav).showSnackBar(
              const SnackBar(content: Text('PK daveti reddedildi')),
            );
          }
        }
      } catch (e) {
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
