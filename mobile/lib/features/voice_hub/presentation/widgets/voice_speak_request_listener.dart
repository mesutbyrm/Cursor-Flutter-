import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_session_registry.dart';
import '../providers/voice_speak_request_signal_provider.dart';
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
  final Set<String> _pendingDialogKeys = {};
  var _showing = false;
  Timer? _pollTimer;

  static String _dedupKey(String roomKey, String userId) => '$roomKey:$userId';

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
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

  bool _canModerateSpeakRequests({
    required UserEntity user,
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
  }) {
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
    if (perms.canAssignSeats || perms.isRoomOwner || perms.isSiteAdmin) {
      return true;
    }
    final oid = room.ownerId?.trim() ?? '';
    final uname = user.username.trim().toLowerCase();
    return (oid.isNotEmpty && oid == user.id) ||
        (uname.isNotEmpty && room.slug.trim().toLowerCase() == uname);
  }

  Future<List<String>> _fetchSpeakRequestIds(
    String liveKey,
    VoiceRoomEntity room,
    String activeKey,
  ) async {
    if (liveKey == activeKey) {
      return ref.read(voiceRoomLiveProvider(liveKey).notifier).fetchSpeakRequests();
    }
    final alt = room.slug != liveKey ? room.slug : null;
    return ref.read(chatRoomRemoteProvider).fetchSpeakRequests(
          liveKey,
          alternateKey: alt,
        );
  }

  Future<void> _pollPending() async {
    if (!mounted || _showing) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    final roomsByKey = <String, VoiceRoomEntity>{};

    if (activeKey.isNotEmpty) {
      final room = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull ??
          VoiceRoomEntity(id: activeKey, slug: activeKey, nameTr: 'Oda');
      roomsByKey[activeKey] = room;
    }

    for (final room in ref.read(myOwnedVoiceRoomsProvider)) {
      final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      if (key.isEmpty) continue;
      roomsByKey.putIfAbsent(
        key,
        () => room,
      );
    }

    for (final entry in roomsByKey.entries) {
      final liveKey = entry.key;
      final room = entry.value;
      final live = ref.read(voiceRoomLiveProvider(liveKey));
      if (!_canModerateSpeakRequests(user: user, room: room, live: live)) {
        continue;
      }

      final ids = await _fetchSpeakRequestIds(liveKey, room, activeKey);
      if (!mounted) return;

      for (final id in ids) {
        if (id.isEmpty || id == user.id) continue;
        final key = _dedupKey(liveKey, id);
        if (_pendingDialogKeys.contains(key)) continue;

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
        _pendingDialogKeys.add(key);
        await _showDialog(
          liveKey,
          live: live,
          userId: id,
          displayName: name,
          dedupKey: key,
        );
        return;
      }
    }
  }

  void _releaseDedup(String dedupKey) {
    _pendingDialogKeys.remove(dedupKey);
  }

  Future<void> _showDialog(
    String liveKey, {
    required VoiceRoomLiveState live,
    required String userId,
    required String displayName,
    required String dedupKey,
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
      if (!mounted) return;
      if (action == null) {
        _releaseDedup(dedupKey);
        return;
      }

      switch (action) {
        case _SpeakAction.approve:
          final err = await ctrl.approveSpeakRequest(userId);
          if (err != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(err)),
            );
            _releaseDedup(dedupKey);
            break;
          }
          final seat = _firstFreeSeat(live);
          if (seat == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Boş koltuk yok')),
              );
            }
            _releaseDedup(dedupKey);
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
  Widget build(BuildContext context) {
    ref.listen(voiceSpeakRequestSignalProvider, (_, __) {
      unawaited(_pollPending());
    });
    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.valueOrNull == null && next.valueOrNull != null) {
        unawaited(_pollPending());
      }
    });
    return widget.child;
  }
}

enum _SpeakAction { approve, reject, block }
