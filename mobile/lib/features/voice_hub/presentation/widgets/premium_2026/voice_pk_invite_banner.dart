import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../../providers/pk_battle_remote_provider.dart';
import '../../theme/voice_room_tokens.dart';

/// Koltukların üstü — yalnızca oda sahibi görür; 60 sn sonra kaybolur.
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
  Timer? _expireTimer;
  String? _dismissedInviteId;
  var _responding = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pollOnce());
      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollOnce());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _expireTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollOnce() async {
    if (!mounted || !widget.isOwner) return;
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

  void _armExpiry(String inviteId) {
    _expireTimer?.cancel();
    _expireTimer = Timer(const Duration(minutes: 1), () {
      if (!mounted) return;
      setState(() => _dismissedInviteId = inviteId);
      ref.read(pkBattleRemoteProvider.notifier).clear();
    });
  }

  String _challengerLabel(PkBattleRemote battle) {
    final name = battle.challenger?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final roomId = battle.voiceRoomId?.trim();
    if (roomId != null && roomId.isNotEmpty) {
      final rooms = ref.read(voiceRoomsProvider).valueOrNull;
      if (rooms != null) {
        for (final r in rooms) {
          if (r.apiRoomKey == roomId || r.id == roomId || r.slug == roomId) {
            return r.nameTr.trim().isNotEmpty ? r.nameTr.trim() : r.slug;
          }
        }
      }
    }
    return 'Bir oda';
  }

  Future<void> _respond({required bool accept, required String inviteId}) async {
    if (_responding) return;
    setState(() => _responding = true);
    final key = widget.room.apiRoomKey.isNotEmpty
        ? widget.room.apiRoomKey
        : widget.room.id;
    final alt = widget.room.slug != key ? widget.room.slug : null;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    try {
      if (accept) {
        await remote.accept(inviteId, roomId: key, alternateRoomId: alt);
        if (!mounted) return;
        setState(() => _dismissedInviteId = inviteId);
        context.push('/voice-room/$key/pk', extra: widget.room);
      } else {
        await remote.reject(inviteId, roomId: key, alternateRoomId: alt);
        if (!mounted) return;
        setState(() => _dismissedInviteId = inviteId);
        remote.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOwner) return const SizedBox.shrink();

    final battle = ref.watch(pkBattleRemoteProvider);
    if (battle == null || !battle.isPending) return const SizedBox.shrink();

    final userId = ref.watch(authControllerProvider).valueOrNull?.id;
    if (!isPkInviteTarget(battle, widget.room, userId: userId)) {
      return const SizedBox.shrink();
    }

    final inviteId = battle.effectiveId;
    if (inviteId.isEmpty || _dismissedInviteId == inviteId) {
      return const SizedBox.shrink();
    }

    _armExpiry(inviteId);
    final challenger = _challengerLabel(battle);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VoiceRoomTokens.neonPink.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: VoiceRoomTokens.gold.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_mma_rounded, color: VoiceRoomTokens.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$challenger sizinle PK atmak istiyor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
              TextButton(
                onPressed: _responding
                    ? null
                    : () => _respond(accept: false, inviteId: inviteId),
                child: const Text('Reddet'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _responding
                    ? null
                    : () => _respond(accept: true, inviteId: inviteId),
                style: FilledButton.styleFrom(
                  backgroundColor: VoiceRoomTokens.neonPink,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 34),
                ),
                child: _responding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kabul Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
