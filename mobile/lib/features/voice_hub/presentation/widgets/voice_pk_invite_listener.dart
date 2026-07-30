import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_pk_owned_rooms_socket_provider.dart';
import '../utils/pk_invite_dialog_helper.dart';

/// Sesli oda PK davetleri — Socket.IO + REST poll; hedef odada popup.
class VoicePkInviteListener extends ConsumerStatefulWidget {
  const VoicePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoicePkInviteListener> createState() =>
      _VoicePkInviteListenerState();
}

class _VoicePkInviteListenerState extends ConsumerState<VoicePkInviteListener> {
  final Set<String> _seenRejections = {};
  var _showing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
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
    if (_showing || !mounted || battle == null) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    if (battle.isPending) {
      final room = resolvePkInviteTargetRoom(ref, battle, user.id);
      if (room != null) {
        final inviteId = battle.effectiveId;
        if (inviteId.isNotEmpty) {
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
    ref.watch(voicePkOwnedRoomsSocketProvider);
    ref.listen<PkBattleRemote?>(pkBattleRemoteProvider, (_, next) {
      _onBattleUpdate(next);
    });
    return widget.child;
  }
}
