import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_session_registry.dart';
import '../utils/voice_room_permissions.dart';

/// Moderatör/oda sahibi — el kaldıran kullanıcı için anlık popup.
class VoiceSpeakRequestListener extends ConsumerStatefulWidget {
  const VoiceSpeakRequestListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceSpeakRequestListener> createState() =>
      _VoiceSpeakRequestListenerState();
}

class _VoiceSpeakRequestListenerState
    extends ConsumerState<VoiceSpeakRequestListener> {
  final Set<String> _seenRequestIds = {};
  var _showing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _showing) return;
      unawaited(_pollPending());
    });
    Future.microtask(_pollPending);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  int? _firstFreeSeat(VoiceRoomLiveState live) {
    final occupied = live.presence
        .map((p) => p.seatIndex)
        .whereType<int>()
        .toSet();
    for (var i = 2; i <= 11; i++) {
      if (!occupied.contains(i)) return i;
    }
    return null;
  }

  Future<void> _pollPending() async {
    if (!mounted || _showing) return;
    final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (activeKey.isEmpty) return;

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final live = ref.read(voiceRoomLiveProvider(activeKey));
    final room = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull ??
        VoiceRoomEntity(id: activeKey, slug: activeKey, nameTr: 'Oda');
    ChatRoomPresence? self;
    for (final p in live.presence) {
      if (p.id == user.id) {
        self = p;
        break;
      }
    }
    final perms = VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: self,
      server: live.serverPermissions,
    );
    if (!perms.canAssignSeats && !perms.isRoomOwner && !perms.isSiteAdmin) {
      return;
    }

    final ctrl = ref.read(voiceRoomLiveProvider(activeKey).notifier);
    final ids = await ctrl.fetchSpeakRequests();
    if (!mounted) return;

    for (final id in ids) {
      if (id.isEmpty || _seenRequestIds.contains(id)) continue;
      if (id == user.id) continue;
      ChatRoomPresence? target;
      for (final p in live.presence) {
        if (p.id == id) {
          target = p;
          break;
        }
      }
      final name = target?.displayName.trim().isNotEmpty == true
          ? target!.displayName.trim()
          : 'Bir kullanıcı';
      _seenRequestIds.add(id);
      await _showDialog(
        activeKey,
        live: live,
        userId: id,
        displayName: name,
      );
      break;
    }
  }

  Future<void> _showDialog(
    String liveKey, {
    required VoiceRoomLiveState live,
    required String userId,
    required String displayName,
  }) async {
    if (!mounted || _showing) return;
    _showing = true;
    try {
      final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
      final action = await showDialog<_SpeakAction>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A0F2E),
          title: Text(
            '$displayName konuşmak istiyor',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: const Text(
            'Koltuğa alınsın mı?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SpeakAction.block),
              child: const Text('Engelle'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, _SpeakAction.reject),
              child: const Text('Hayır'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, _SpeakAction.approve),
              child: const Text('Evet'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) return;

      switch (action) {
        case _SpeakAction.approve:
          final err = await ctrl.approveSpeakRequest(userId);
          if (err != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err)),
            );
            break;
          }
          final seat = _firstFreeSeat(live);
          if (seat == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Boş koltuk yok')),
              );
            }
            break;
          }
          final seatErr = await ctrl.assignSeat(seatIndex: seat, userId: userId);
          if (seatErr != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(seatErr)),
            );
          }
        case _SpeakAction.reject:
          final err = await ctrl.rejectSpeakRequest(userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err ?? 'Konuşma isteği reddedildi.'),
              ),
            );
          }
        case _SpeakAction.block:
          final err = await ctrl.blockSpeakRequestUser(userId: userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  err ?? '$displayName konuşma isteği gönderemez.',
                ),
              ),
            );
          }
      }
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _SpeakAction { approve, reject, block }
