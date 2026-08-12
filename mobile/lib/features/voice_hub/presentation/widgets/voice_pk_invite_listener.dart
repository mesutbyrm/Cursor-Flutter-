import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/pk_event_log.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_session_registry.dart';
import '../utils/pk_invite_dialog_helper.dart';

/// Sesli oda PK davetleri — oda poll + global davet poll; aktif PK'da yönlendirme.
class VoicePkInviteListener extends ConsumerStatefulWidget {
  const VoicePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoicePkInviteListener> createState() =>
      _VoicePkInviteListenerState();
}

class _VoicePkInviteListenerState extends ConsumerState<VoicePkInviteListener> {
  final Set<String> _seenRejections = {};
  final Set<String> _autoNavigatedBattleIds = {};
  var _showing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _showing) return;
      unawaited(_pollPendingInvites());
    });
    Future.microtask(_pollPendingInvites);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onBattleUpdate(PkBattleRemote? battle) {
    if (!mounted || battle == null) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    if (battle.isActive && !battle.isEnded) {
      _maybeAutoNavigateToPk(battle, user.id);
      return;
    }

    if (_showing) return;

    if (battle.isPending) {
      final room = resolvePkInviteTargetRoom(ref, battle, user.id);
      if (room != null) {
        final inviteId = battle.effectiveId;
        if (inviteId.isNotEmpty) {
          PkEventLog.incomingRequest(inviteId: inviteId);
          unawaited(_showInviteDialog(battle, room));
        }
      }
      return;
    }

    if (battle.status == 'rejected') {
      final id = battle.effectiveId;
      if (id.isEmpty || !_seenRejections.add(id)) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${pkChallengerRoomLabel(ref, battle)} odası isteğinizi reddetti',
            ),
          ),
        );
      }
      ref.read(pkBattleRemoteProvider.notifier).clear();
    }
  }

  void _maybeAutoNavigateToPk(PkBattleRemote battle, String userId) {
    final id = battle.effectiveId;
    if (id.isEmpty || _autoNavigatedBattleIds.contains(id)) return;
    final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
    VoiceRoomEntity? room;
    for (final r in rooms) {
      if (isPkChallengerRoom(battle, r) ||
          isPkInviteTarget(battle, r, userId: userId)) {
        room = r;
        break;
      }
    }
  final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (room == null && activeKey.isNotEmpty) {
      for (final r in rooms) {
        if (r.apiRoomKey == activeKey || r.id == activeKey || r.slug == activeKey) {
          room = r;
          break;
        }
      }
    }
    if (room == null) return;
    final route = GoRouter.of(context).routeInformationProvider.value.uri.path;
    if (route.contains('/pk')) return;
    _autoNavigatedBattleIds.add(id);
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
    context.push('/voice-room/$key/pk', extra: room);
  }

  Future<void> _showInviteDialog(
    PkBattleRemote battle,
    VoiceRoomEntity room,
  ) async {
    if (!mounted || _showing) return;
    _showing = true;
    try {
      await showPkInviteDialog(context, ref, battle: battle, room: room);
    } finally {
      _showing = false;
    }
  }

  Future<void> _pollPendingInvites() async {
    if (_showing || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);

      final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
      if (activeKey.isNotEmpty) {
        final roomBattle = await api.fetchRoomBattle(activeKey);
        if (roomBattle != null && !roomBattle.isEnded) {
          ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(roomBattle);
          _onBattleUpdate(roomBattle);
          if (roomBattle.isPending || roomBattle.isActive) return;
        }
      }

      final rooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
      for (final room in rooms) {
        if ((room.ownerId?.trim() ?? '') != user.id) continue;
        final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
        if (key.isEmpty) continue;
        final battle = await api.fetchRoomBattle(
          key,
          alternateRoomId: room.slug != key ? room.slug : null,
        );
        if (battle != null && !battle.isEnded) {
          ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
          _onBattleUpdate(battle);
          if (battle.isPending || battle.isActive) return;
        }
      }

      final invites = await api.fetchMyInvites();
      for (final battle in invites) {
        if (!battle.isPending) continue;
        _onBattleUpdate(battle);
        return;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PkBattleRemote?>(pkBattleRemoteProvider, (_, next) {
      _onBattleUpdate(next);
    });
    return widget.child;
  }
}
