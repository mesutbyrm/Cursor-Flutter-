import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'app_startup_log.dart';
import 'stuck_overlay_guard.dart';

/// Soğuk açılışta takılı modal barrier — auth bitene ve birkaç kareye kadar temizler.
class StartupOverlayGuard extends ConsumerStatefulWidget {
  const StartupOverlayGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StartupOverlayGuard> createState() =>
      _StartupOverlayGuardState();
}

class _StartupOverlayGuardState extends ConsumerState<StartupOverlayGuard> {
  Timer? _retryTimer;
  var _attempts = 0;
  var _authFinished = false;
  var _loggedHome = false;
  String? _lastClearedPath;
  static const _maxAttempts = 15;

  static const _authPaths = {
    '/login',
    '/register',
    '/splash',
    '/auth/forgot-password',
    '/auth/otp-verify',
  };

  @override
  void initState() {
    super.initState();
    AppStartupLog.appStart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearOverlays('post-frame-0');
      _scheduleRetries();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetries() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _attempts >= _maxAttempts) {
        _retryTimer?.cancel();
        return;
      }
      _attempts++;
      _clearOverlays('retry-$_attempts');
    });
  }

  void _clearOverlays(String reason) {
    final path = _currentPath();
    if (!_authPaths.contains(path) && !(_authFinished && path == '/feed')) {
      return;
    }
    if (_lastClearedPath == path && reason.startsWith('route-')) return;
    _lastClearedPath = path;
    StuckOverlayGuard.dismissRoot(reason: reason);
  }

  String _currentPath() {
    final router = ref.read(goRouterProvider);
    return router.routerDelegate.currentConfiguration.uri.path;
  }

  bool _isAuthPath(String path) => _authPaths.contains(path);

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      final wasLoading = prev?.isLoading ?? true;
      if (wasLoading && !next.isLoading) {
        _authFinished = true;
        AppStartupLog.authFinish(
          hasUser: next.valueOrNull != null,
          error: next.hasError,
        );
        _attempts = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _clearOverlays('auth-finish');
          _scheduleRetries();
        });
      }
    });

    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final path = router.routerDelegate.currentConfiguration.uri.path;
        if (path == '/feed' && !_loggedHome) {
          _loggedHome = true;
          AppStartupLog.homeScreenRender(path);
        }
        if (_isAuthPath(path) || (_authFinished && path == '/feed')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _clearOverlays('route-$path');
          });
        }
        return widget.child;
      },
    );
  }
}
