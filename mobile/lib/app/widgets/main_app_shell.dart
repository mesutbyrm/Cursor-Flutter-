import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bootstrap/auth_route_paths.dart';
import '../../features/home/presentation/widgets/fortune_incoming_invite_host.dart';
import '../../features/shell/presentation/app_bottom_nav_host.dart';
import '../../features/voice_hub/presentation/widgets/voice_room/voice_room_global_music_bar.dart';
import '../router/app_router.dart';

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

  @override
  void initState() {
    super.initState();
    final router = ref.read(goRouterProvider);
    _location = router.routerDelegate.currentConfiguration.uri.path;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachRouter(ref.read(goRouterProvider));
    });
  }

  @override
  void dispose() {
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
    final router = ref.watch(goRouterProvider);
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
      body = FortuneIncomingInviteHost(child: body);
      body = AppBottomNavHost(location: location, child: body);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        body,
        if (showGlobalMusic)
          Align(
            alignment: Alignment.bottomCenter,
            child: VoiceRoomGlobalMusicBar(routePath: location),
          ),
      ],
    );
  }
}
