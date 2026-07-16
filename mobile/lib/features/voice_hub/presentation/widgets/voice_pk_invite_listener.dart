import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_pk_owned_rooms_socket_provider.dart';

/// Sesli oda PK davetleri — Socket.IO + SSE; HTTP polling yok.
class VoicePkInviteListener extends ConsumerStatefulWidget {
  const VoicePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoicePkInviteListener> createState() =>
      _VoicePkInviteListenerState();
}

class _VoicePkInviteListenerState extends ConsumerState<VoicePkInviteListener> {
  final Set<String> _seenInvites = {};
  final Set<String> _seenRejections = {};
  var _showing = false;

  List<VoiceRoomEntity> _ownedRooms(List<VoiceRoomEntity> rooms, String userId) {
    if (userId.isEmpty) return const [];
    return rooms
        .where((r) => (r.ownerId?.trim() ?? '') == userId)
        .toList(growable: false);
  }

  String _roomLabel(PkBattleRemote battle, VoiceRoomEntity? fallbackRoom) {
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
    final fb = fallbackRoom?.nameTr.trim();
    if (fb != null && fb.isNotEmpty) return fb;
    return fallbackRoom?.slug ?? 'Bir oda';
  }

  String _opponentRoomLabel(PkBattleRemote battle) {
    final rooms = ref.read(voiceRoomsProvider).valueOrNull;
    final roomId = battle.opponentVoiceRoomId?.trim() ?? '';
    if (rooms != null && roomId.isNotEmpty) {
      for (final r in rooms) {
        if (r.apiRoomKey == roomId || r.id == roomId || r.slug == roomId) {
          final name = r.nameTr.trim();
          return name.isNotEmpty ? name : r.slug;
        }
      }
    }
    final opp = battle.opponent?.displayName?.trim();
    if (opp != null && opp.isNotEmpty) return opp;
    return 'Karşı oda';
  }

  void _onBattleUpdate(PkBattleRemote? battle) {
    if (_showing || !mounted || battle == null) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
    final owned = _ownedRooms(rooms, user.id);

    if (battle.isPending) {
      for (final room in owned) {
        if (!isPkInviteTarget(battle, room, userId: user.id)) continue;
        final inviteId = battle.effectiveId;
        if (inviteId.isEmpty || !_seenInvites.add(inviteId)) continue;
        unawaited(_showInviteDialog(battle, room));
        return;
      }
    }

    if (battle.status == 'rejected') {
      for (final room in owned) {
        if (!isPkChallengerRoom(battle, room)) continue;
        final id = battle.effectiveId;
        if (id.isEmpty || !_seenRejections.add(id)) continue;
        final opp = _opponentRoomLabel(battle);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$opp odası isteğinizi reddetti')),
          );
        }
        ref.read(pkBattleRemoteProvider.notifier).clear();
        return;
      }
    }
  }

  Future<void> _showInviteDialog(PkBattleRemote battle, VoiceRoomEntity room) async {
    if (!mounted || _showing) return;
    _showing = true;
    final roomLabel = _roomLabel(battle, room);
    final inviteId = battle.effectiveId;
    final minutes = (battle.durationSeconds / 60).round();
    final durationHint = minutes > 0 ? '\nSüre: $minutes dk' : '';
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
        content: Text(
          '$roomLabel odasında PK isteği var.$durationHint\nKabul ediyor musunuz?',
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
    _showing = false;
    if (!mounted || accept == null) return;

    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final alt = room.slug != key ? room.slug : null;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    try {
      if (accept) {
        await remote.accept(inviteId, roomId: key, alternateRoomId: alt);
        if (!mounted) return;
        VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
        context.push('/voice-room/$key/pk', extra: room);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PK başladı')),
          );
        }
      } else {
        await remote.reject(inviteId, roomId: key, alternateRoomId: alt);
        remote.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PK daveti reddedildi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(voicePkOwnedRoomsSocketProvider);
    ref.listen<PkBattleRemote?>(pkBattleRemoteProvider, (_, next) {
      _onBattleUpdate(next);
    });
    return widget.child;
  }
}
