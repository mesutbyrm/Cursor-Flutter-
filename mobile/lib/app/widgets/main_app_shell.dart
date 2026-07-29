import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bootstrap/auth_route_paths.dart';
import '../../core/bootstrap/startup_perf.dart';
import '../../features/agency/presentation/providers/agency_providers.dart';
import '../../features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../features/live_psychics/presentation/widgets/psychic_incoming_host.dart';
import '../../features/live_psychics/presentation/widgets/psychic_session_ended_host.dart';
import '../../features/profile/presentation/widgets/jeton_payment_status_listener.dart';
import '../../features/shell/presentation/app_bottom_nav_host.dart';
import '../../features/live/presentation/widgets/live_pk_invite_listener.dart';
import '../../features/voice_hub/presentation/widgets/voice_pk_invite_listener.dart';
import '../../features/messages/presentation/widgets/dm_realtime_listener.dart';
import '../../features/messages/presentation/widgets/dm_voice_call_host.dart';
import '../../features/video_call/presentation/incoming_video_call_screen.dart';
import '../../features/voice_hub/presentation/widgets/voice_room/voice_room_global_music_bar.dart';
import '../../features/voice_hub/presentation/widgets/staff_entrance_marquee_host.dart';
import '../router/app_router.dart';
import '../../core/bootstrap/voice_rooms_presence_scope.dart';
import '../../core/network/sse/connectivity_sse_reconnect_provider.dart';
import '../../core/sse_client_provider.dart';
import '../../core/widgets/offline_status_banner.dart';
import '../../features/gifts/presentation/providers/gift_catalog_version_watcher.dart';
import '../../features/notifications/presentation/widgets/notifications_realtime_listener.dart';

/// MaterialApp.router [builder] içeriği — [ListenableBuilder] kullanmaz.
///
/// GoRouter ilk mount sırasında [GoRouterDelegate.notifyListeners] build
/// fazında tetiklenir; [ListenableBuilder] bu durumda "setState during build"
/// üretir ve overlay/barrier durumunu bozar (gri ekran).
class MainAppShell extends ConsumerStatefulWidget {
  const MainAppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends ConsumerState<MainAppShell> {
  GoRouter? _router;
  String _location = '/feed';
  var _listenerAttached = false;
  var _realtimeReady = false;
  Timer? _realtimeTimer;
  SseClientLifecycleBinding? _sseLifecycle;

  @override
  void initState() {
    super.initState();
    final router = ref.read(goRouterProvider);
    _location = router.routerDelegate.currentConfiguration.uri.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _attachRouter(ref.read(goRouterProvider));
      _sseLifecycle = ref.read(sseClientLifecycleProvider);
      _sseLifecycle?.attach();
    });
    _realtimeTimer = Timer(StartupPerf.shellRealtimeDelay, () {
      if (!mounted) return;
      setState(() => _realtimeReady = true);
      unawaited(ref.read(approvedPsychicProvider.notifier).refresh());
      unawaited(ref.read(approvedAgencyProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _sseLifecycle?.dispose();
    _detachRouter();
    super.dispose();
  }

  void _detachRouter() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = null;
    _listenerAttached = false;
  }

  void _attachRouter(GoRouter router) {
    if (identical(_router, router) && _listenerAttached) return;
    _detachRouter();
    _router = router;
    _location = router.routerDelegate.currentConfiguration.uri.path;
    router.routerDelegate.addListener(_onRouteChanged);
    _listenerAttached = true;
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final router = _router;
    if (router == null) return;
    final next = router.routerDelegate.currentConfiguration.uri.path;
    if (next == _location) return;
    // GoRouter ilk mount sırasında build fazında notifyListeners gönderir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _router == null) return;
      final latest =
          _router!.routerDelegate.currentConfiguration.uri.path;
      if (latest != _location) {
        setState(() => _location = latest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(connectivitySseReconnectProvider);
    watchGiftCatalogVersion(ref);

    final router = ref.read(goRouterProvider);
    if (!identical(router, _router)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _attachRouter(router);
      });
    }

    final location =
        router.routerDelegate.currentConfiguration.uri.path;
    final isAuthRoute = AuthRoutePaths.isPublicAuthPath(location);
    final showGlobalMusic =
        VoiceRoomGlobalMusicBar.shouldShowForRoute(location) && !isAuthRoute;

    var body = widget.child;
    if (!isAuthRoute) {
      body = NotificationsRealtimeListener(child: body);
      body = DmRealtimeListener(child: body);
      body = DmVoiceCallHost(child: body);
      body = JetonPaymentStatusListener(child: body);
      body = PsychicSessionEndedHost(child: body);
      body = PsychicIncomingHost(child: body);
      body = LivePkInviteListener(child: body);
      body = VoicePkInviteListener(child: body);
      body = VideoCallIncomingHost(child: body);
      body = AppBottomNavHost(location: location, child: body);
    }

    if (!isAuthRoute && _realtimeReady) {
      body = VoiceRoomsPresenceScope(child: body);
    }

    return OfflineStatusBanner(
      child: StaffEntranceMarqueeHost(
        routePath: location,
        child: Stack(
          fit: StackFit.expand,
          children: [
            body,
            if (showGlobalMusic)
              Align(
                alignment: Alignment.bottomCenter,
                child: VoiceRoomGlobalMusicBar(routePath: location),
              ),
          ],
        ),
      ),
    );
  }
}
