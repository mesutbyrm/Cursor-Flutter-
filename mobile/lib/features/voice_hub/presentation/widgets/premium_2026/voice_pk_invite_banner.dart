import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../providers/pk_battle_remote_provider.dart';
import '../../utils/pk_invite_dialog_helper.dart';

/// Koltukların altında — gelen PK daveti için popup tetikler (oda sahibi).
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadOnce());
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_loadOnce());
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
      if (!mounted || battle == null || !battle.isPending) return;
      final userId = ref.read(authControllerProvider).valueOrNull?.id;
      final room = resolvePkInviteTargetRoom(ref, battle, userId ?? '');
      if (room == null) return;
      _dialogOpen = true;
      await showPkInviteDialog(context, ref, battle: battle, room: room);
      _dialogOpen = false;
    } catch (_) {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
