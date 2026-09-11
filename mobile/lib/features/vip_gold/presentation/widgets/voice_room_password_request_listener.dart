import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';
import '../providers/room_password_access_request_provider.dart';
import '../providers/voice_room_password_request_provider.dart';

/// Oda sahibi — şifre erişim isteği (İzin ver / Reddet).
class VoiceRoomPasswordRequestListener extends ConsumerStatefulWidget {
  const VoiceRoomPasswordRequestListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceRoomPasswordRequestListener> createState() =>
      _VoiceRoomPasswordRequestListenerState();
}

class _VoiceRoomPasswordRequestListenerState
    extends ConsumerState<VoiceRoomPasswordRequestListener> {
  var _showing = false;
  final Set<String> _seen = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_tryShowNext);
  }

  Future<void> _tryShowNext() async {
    if (!mounted || _showing) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final queue = ref.read(voiceRoomPasswordRequestQueueProvider);
    for (final entry in queue) {
      if (_seen.contains(entry.dedupKey)) continue;
      final room = ref.read(voiceRoomByIdProvider(entry.roomKey)).valueOrNull;
      final ownerId = room?.ownerId?.trim() ?? '';
      final isOwner = ownerId.isNotEmpty && ownerId == user.id;
      if (!isOwner) continue;

      _showing = true;
      _seen.add(entry.dedupKey);
      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Oda şifresi isteği'),
          content: Text(
            '${entry.requesterName} şifreli odanıza girmek istiyor.\n'
            '${entry.message?.trim().isNotEmpty == true ? entry.message!.trim() : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Reddet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('İzin ver'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      try {
        await ref.read(chatRoomRemoteProvider).respondPasswordAccessRequest(
              entry.roomKey,
              entry.requesterUserId,
              approve: approved == true,
              alternateKey: room?.slug,
            );
        if (approved != true) {
          await RoomPasswordAccessCooldown.markRejectedUntilMidnight(
            entry.roomKey,
            entry.requesterUserId,
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İşlem gönderilemedi. Lütfen tekrar deneyin.'),
            ),
          );
        }
      } finally {
        ref
            .read(voiceRoomPasswordRequestQueueProvider.notifier)
            .remove(entry.dedupKey);
        _showing = false;
        if (mounted) unawaited(_tryShowNext());
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(voicePasswordRequestSignalProvider, (_, __) {
      unawaited(_tryShowNext());
    });
    return widget.child;
  }
}
