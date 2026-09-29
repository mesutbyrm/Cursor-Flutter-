import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../../../../app/router/app_router.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_session_registry.dart';
import '../../utils/voice_room_leave_flow.dart';
import '../../utils/voice_room_stale_session_guard.dart';

/// Ana sayfa / başka sekmeye geçildiğinde aktif sesli oda oturumunu sunucuda kapatır.
class VoiceRoomRoutePresenceGuard extends ConsumerStatefulWidget {
  const VoiceRoomRoutePresenceGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceRoomRoutePresenceGuard> createState() =>
      _VoiceRoomRoutePresenceGuardState();
}

class _VoiceRoomRoutePresenceGuardState
    extends ConsumerState<VoiceRoomRoutePresenceGuard> {
  String? _lastPath;
  var _leaveInFlight = false;

  bool _onVoiceRoomRoute(String path) {
    return VoiceRoomLeaveFlow.shouldLeaveVoiceRoomRoute(path);
  }

  void _syncRoute(String path) {
    if (path == _lastPath) return;
    _lastPath = path;

    if (_onVoiceRoomRoute(path)) return;

    final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (active.isEmpty || _leaveInFlight) return;

    _leaveInFlight = true;
    unawaited(() async {
      try {
        final notifier = ref.read(voiceRoomLiveProvider(active).notifier);
        await notifier.leaveRoomSession(
          source: 'route_left_voice_room',
          awaitBackend: true,
          force: true,
        );
      } catch (_) {
        try {
          await ref.read(chatRoomRemoteProvider).leavePresence(active);
        } catch (_) {}
      }
      await clearStaleVoicePresenceOnAuth(ref as Ref);
      _leaveInFlight = false;
    }());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncRoute(path);
    });
    return widget.child;
  }
}
