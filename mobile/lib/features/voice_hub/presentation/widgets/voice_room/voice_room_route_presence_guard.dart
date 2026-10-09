import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../data/services/voice_room_debug_log.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_session_registry.dart';
import '../../utils/voice_room_leave_flow.dart';

/// Ana sayfa / başka sekmeye geçildiğinde aktif sesli oda oturumunu sunucuda kapatır.
///
/// Güvenlik ağıdır: normal çıkış oda sayfasının kendi leave akışıyla yapılır.
/// Önceden yalnız `build`'de rota okunuyordu; widget `MaterialApp`'in üstünde
/// olduğu için gezinmede yeniden çalışmıyor ve hiç tetiklenmiyordu. Ayrıca
/// `WidgetRef` → `Ref` dönüşümü çalışma anında hata verip kilidi açık
/// bırakıyordu.
class VoiceRoomRoutePresenceGuard extends ConsumerStatefulWidget {
  const VoiceRoomRoutePresenceGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoiceRoomRoutePresenceGuard> createState() =>
      _VoiceRoomRoutePresenceGuardState();
}

class _VoiceRoomRoutePresenceGuardState
    extends ConsumerState<VoiceRoomRoutePresenceGuard> {
  GoRouter? _router;
  bool? _lastInRoom;
  var _leaveInFlight = false;

  void _attach(GoRouter router) {
    if (identical(_router, router)) return;
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = router;
    _lastInRoom = null;
    router.routerDelegate.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    final router = _router;
    if (router == null || !mounted) return;
    final config = router.routerDelegate.currentConfiguration;
    final inRoom = VoiceRoomLeaveFlow.voiceRoomInStack([
      config.uri.path,
      for (final m in config.matches) m.matchedLocation,
    ]);
    if (inRoom == _lastInRoom) return;
    _lastInRoom = inRoom;
    if (inRoom) return;

    final active = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (active.isEmpty || _leaveInFlight) return;

    VoiceRoomDebugLog.log('ROUTE_LEFT_VOICE_ROOM', {
      'roomId': active,
      'path': config.uri.path,
    });
    _leaveInFlight = true;
    unawaited(() async {
      try {
        await ref
            .read(voiceRoomLiveProvider(active).notifier)
            .leaveRoomSession(
              source: 'route_left_voice_room',
              awaitBackend: true,
              // force:false → devam eden/biten leave ile birleşir; çift leave yok.
              force: false,
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        try {
          await ref.read(chatRoomRemoteProvider).leavePresence(active);
        } catch (_) {}
      } finally {
        _leaveInFlight = false;
      }
    }());
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _attach(ref.watch(goRouterProvider));
    return widget.child;
  }
}
