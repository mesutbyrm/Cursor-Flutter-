import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
  if (userId.isEmpty || !battle.isPending) return null;
  final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];

  final owned = rooms
      .where((r) => (r.ownerId?.trim() ?? '') == userId)
      .toList(growable: false);

  final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
  VoiceRoomEntity? activeRoom;
  if (activeKey.isNotEmpty) {
    for (final r in rooms) {
      if (r.apiRoomKey == activeKey || r.id == activeKey || r.slug == activeKey) {
        activeRoom = r;
        break;
      }
    }
  }

  final candidates = <VoiceRoomEntity>[
    if (activeRoom != null) activeRoom,
    ...owned,
  ];

  final oppRoomId = battle.opponentVoiceRoomId?.trim() ?? '';
  if (oppRoomId.isNotEmpty) {
    for (final r in rooms) {
      if (r.apiRoomKey == oppRoomId ||
          r.id == oppRoomId ||
          r.slug == oppRoomId) {
        candidates.add(r);
      }
    }
  }

  final seen = <String>{};
  for (final room in candidates) {
    final k = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (k.isEmpty || !seen.add(k)) continue;
    if (isPkInviteTarget(battle, room, userId: userId)) return room;
  }

  for (final room in rooms) {
    final k = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (k.isEmpty || !seen.add(k)) continue;
    if (isPkInviteTarget(battle, room, userId: userId)) return room;
  }
  return null;
}

String pkChallengerRoomLabel(WidgetRef ref, PkBattleRemote battle) {
  final rooms = ref.read(voiceRoomsProvider).valueOrNull;
  final roomId = battle.voiceRoomId?.trim() ?? '';
  if (rooms != null && roomId.isNotEmpty) {
    for (final r in rooms) {
      if (r.apiRoomKey == roomId || r.id == roomId || r.slug == roomId) {
        final name = r.nameTr.trim();
        return name.isNotEmpty ? name : r.slug;
      }
    }
  }
  final challenger = battle.challenger?.displayName?.trim();
  if (challenger != null && challenger.isNotEmpty) return challenger;
  return 'Bir oda';
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
      if (!context.mounted) return;
      VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
      context.push('/voice-room/$key/pk', extra: room);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PK başladı')),
      );
    } else {
      PkEventLog.reject(inviteId: inviteId);
      await remote.reject(inviteId, roomId: key, alternateRoomId: alt);
      remote.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PK daveti reddedildi')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}
