import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/pk/pk_battle_remote_models.dart';
import '../../../domain/pk/pk_opponent_room_filter.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/pk_battle_remote_provider.dart';
import '../../theme/voice_room_tokens.dart';

/// Koltukların üstü — yalnızca oda sahibi görür; SSE/socket ile anlık güncellenir.
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
  Timer? _expireTimer;
  String? _dismissedInviteId;
  var _responding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOnce());
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOnce() async {
    if (!mounted) return;
    final key = widget.room.apiRoomKey.isNotEmpty
        ? widget.room.apiRoomKey
        : widget.room.id;
    if (key.isEmpty) return;
    try {
      await ref.read(pkBattleRemoteProvider.notifier).loadRoomBattle(
            key,
            alternateRoomId: widget.room.slug != key ? widget.room.slug : null,
          );
    } catch (_) {}
  }

  void _armExpiry(String inviteId, PkBattleRemote battle) {
    _expireTimer?.cancel();
    _expireTimer = Timer(const Duration(minutes: 1), () {
      if (!mounted) return;
      setState(() => _dismissedInviteId = inviteId);
      final key = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final alt = widget.room.slug != key ? widget.room.slug : null;
      final remote = ref.read(pkBattleRemoteProvider.notifier);
      unawaited(
        remote
            .reject(battle.effectiveId, roomId: key, alternateRoomId: alt)
            .then((_) => remote.clear())
            .catchError((_) => remote.clear()),
      );
    });
  }

  String _challengerLabel(PkBattleRemote battle) {
    final name = battle.challenger?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Bir oda';
  }

  Future<void> _respond(bool accept, PkBattleRemote battle) async {
    if (_responding) return;
    setState(() => _responding = true);
    final key = widget.room.apiRoomKey.isNotEmpty
        ? widget.room.apiRoomKey
        : widget.room.id;
    final alt = widget.room.slug != key ? widget.room.slug : null;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    try {
      if (accept) {
        await remote.accept(
          battle.effectiveId,
          roomId: key,
          alternateRoomId: alt,
        );
        if (!mounted) return;
        context.push('/voice-room/$key/pk', extra: widget.room);
      } else {
        await remote.reject(
          battle.effectiveId,
          roomId: key,
          alternateRoomId: alt,
        );
        remote.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwner) return const SizedBox.shrink();

    final battle = ref.watch(pkBattleRemoteProvider);
    if (battle == null ||
        !battle.isPending ||
        battle.effectiveId == _dismissedInviteId) {
      return const SizedBox.shrink();
    }

    final userId = ref.watch(authControllerProvider).valueOrNull?.id;
    if (!isPkInviteTarget(battle, widget.room, userId: userId)) {
      return const SizedBox.shrink();
    }

    _armExpiry(battle.effectiveId, battle);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VoiceRoomTokens.neonPink.withValues(alpha: 0.85),
                VoiceRoomTokens.neonBlue.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: VoiceRoomTokens.neonPink.withValues(alpha: 0.35),
                blurRadius: 16,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.sports_mma_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_challengerLabel(battle)} PK daveti gönderdi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _responding ? null : () => _respond(false, battle),
                  child: const Text('Reddet'),
                ),
                FilledButton(
                  onPressed: _responding ? null : () => _respond(true, battle),
                  child: const Text('Kabul'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
