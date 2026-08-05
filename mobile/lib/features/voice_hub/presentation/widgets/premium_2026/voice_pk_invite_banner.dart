import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../providers/pk_battle_remote_provider.dart';
import '../../utils/pk_invite_dialog_helper.dart';

/// SSE + poll — gelen PK daveti anında popup (oda sahibi).
class VoicePkInviteBanner extends ConsumerStatefulWidget {
  const VoicePkInviteBanner({
    super.key,
    required this.room,
    required this.liveKey,
    required this.isOwner,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final bool isOwner;

  @override
  ConsumerState<VoicePkInviteBanner> createState() =>
      _VoicePkInviteBannerState();
}

class _VoicePkInviteBannerState extends ConsumerState<VoicePkInviteBanner> {
  Timer? _pollTimer;
  var _dialogOpen = false;
  String? _lastShownBattleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadOnce());
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        unawaited(_loadOnce());
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeShow(PkBattleRemote battle) async {
    if (!mounted || !widget.isOwner || _dialogOpen) return;
    if (!battle.isPending) return;
    final battleId = battle.effectiveId;
    if (battleId == _lastShownBattleId) return;

    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final room = resolvePkInviteTargetRoom(ref, battle, userId ?? '');
    if (room == null) return;

    _dialogOpen = true;
    _lastShownBattleId = battleId;
    try {
      await showPkInviteDialog(context, ref, battle: battle, room: room);
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _loadOnce() async {
    if (!mounted || !widget.isOwner || _dialogOpen) return;
    final key = widget.room.apiRoomKey.isNotEmpty
        ? widget.room.apiRoomKey
        : widget.room.id;
    if (key.isEmpty) return;
    try {
      final battle = await ref.read(pkBattleRemoteProvider.notifier).loadRoomBattle(
            key,
            alternateRoomId: widget.room.slug != key ? widget.room.slug : null,
          );
      if (battle != null) await _maybeShow(battle);
    } catch (_) {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PkBattleRemote?>(pkBattleRemoteProvider, (prev, next) {
      if (next != null && next != prev) {
        unawaited(_maybeShow(next));
      }
    });
    return const SizedBox.shrink();
  }
}
