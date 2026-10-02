import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/room_access_providers.dart';
import '../providers/voice_room_join_request_provider.dart';

/// Oda sahibi — şifreli VIP odaya giriş isteği popup'ı.
///
/// 🚪 Odaya Giriş İsteği · @kullaniciadi odaya girmek istiyor. [❌ Hayır] [✅ Evet]
///
/// Onay/ret sunucuya gider (`join-request/{id}/approve|reject`); izin
/// istemcide bayrak olarak tutulmaz, sunucu join sırasında doğrular.
class VoiceRoomJoinRequestListener extends ConsumerStatefulWidget {
  const VoiceRoomJoinRequestListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceRoomJoinRequestListener> createState() =>
      _VoiceRoomJoinRequestListenerState();
}

class _VoiceRoomJoinRequestListenerState
    extends ConsumerState<VoiceRoomJoinRequestListener> {
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

    final queue = ref.read(voiceRoomJoinRequestQueueProvider);
    for (final entry in queue) {
      if (_seen.contains(entry.dedupKey)) continue;
      final room = ref.read(voiceRoomByIdProvider(entry.roomKey)).valueOrNull;
      final ownerId = room?.ownerId?.trim() ?? '';
      if (ownerId.isEmpty || ownerId != user.id) continue;

      _showing = true;
      _seen.add(entry.dedupKey);
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('🚪 Odaya Giriş İsteği'),
          content: Text('${entry.request.handle} odaya girmek istiyor.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('❌ Hayır'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('✅ Evet'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      try {
        await ref.read(roomAccessRemoteProvider).respond(
              entry.roomKey,
              entry.request.id,
              approve: approved == true,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                approved == true
                    ? '${entry.request.handle} için giriş izni verildi'
                    : 'Giriş isteği reddedildi',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
      } finally {
        ref
            .read(voiceRoomJoinRequestQueueProvider.notifier)
            .remove(entry.dedupKey);
        _showing = false;
        if (mounted) unawaited(_tryShowNext());
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(voiceJoinRequestSignalProvider, (_, _) {
      unawaited(_tryShowNext());
    });
    return widget.child;
  }
}
