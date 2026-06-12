import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import 'app_startup_log.dart';
import 'stuck_overlay_guard.dart';

/// MaterialApp içinde — kök navigator hazır olduktan sonra modal barrier temizler.
class NavigatorModalSanitizer extends StatefulWidget {
  const NavigatorModalSanitizer({
    super.key,
    required this.active,
    this.postAuthFeed = false,
    required this.child,
  });

  final bool active;
  /// Oturum açılışı sonrası /feed'e geçişte kalan modal barrier temizliği.
  final bool postAuthFeed;
  final Widget child;

  @override
  State<NavigatorModalSanitizer> createState() =>
      _NavigatorModalSanitizerState();
}

class _NavigatorModalSanitizerState extends State<NavigatorModalSanitizer> {
  Timer? _timer;
  var _ticks = 0;

  bool get _shouldScrub => widget.active || widget.postAuthFeed;

  @override
  void initState() {
    super.initState();
    if (_shouldScrub) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrub('post-frame'));
      _armTimer();
    }
  }

  @override
  void didUpdateWidget(covariant NavigatorModalSanitizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasScrubbing = oldWidget.active || oldWidget.postAuthFeed;
    if (_shouldScrub && !wasScrubbing) {
      _ticks = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrub('activated'));
      _armTimer();
    } else if (_shouldScrub && (widget.postAuthFeed && !oldWidget.postAuthFeed)) {
      _ticks = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrub('post-auth'));
      _armTimer();
    } else if (!_shouldScrub) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 75), (_) {
      if (!mounted || !_shouldScrub || _ticks >= 64) {
        _timer?.cancel();
        return;
      }
      _ticks++;
      _scrub('tick-$_ticks');
    });
  }

  void _scrub(String reason) {
    final keyNav = rootNavigatorKey.currentState;
    if (keyNav != null) {
      StuckOverlayGuard.dismissPopupRoutes(rootNavigatorKey, reason: reason);
      return;
    }
    final ctxNav = Navigator.maybeOf(context, rootNavigator: true);
    if (ctxNav != null) {
      StuckOverlayGuard.dismissNavigator(ctxNav, reason: reason);
      return;
    }
    AppStartupLog.overlayHide(reason: reason, note: 'nav-null');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
