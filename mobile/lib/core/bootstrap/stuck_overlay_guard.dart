import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import 'app_startup_log.dart';

/// Yarım kalmış dialog / bottom sheet katmanlarını temizler.
abstract final class StuckOverlayGuard {
  /// Üstteki [PopupRoute] veya görünür modal barrier katmanlarını kaldırır.
  static int dismissPopupRoutes(
    GlobalKey<NavigatorState> navigatorKey, {
    String reason = 'manual',
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      AppStartupLog.overlayHide(reason: reason, note: 'nav-null');
      return 0;
    }
    return dismissNavigator(nav, reason: reason);
  }

  static int dismissNavigator(
    NavigatorState nav, {
    String reason = 'manual',
  }) {
    var popped = 0;
    for (var guard = 0; guard < 16; guard++) {
      if (!nav.canPop()) break;
      if (!_shouldPopTopRoute(nav)) break;
      nav.pop();
      popped++;
    }

    AppStartupLog.overlayHide(
      reason: reason,
      popped: popped,
      canStillPop: nav.canPop(),
    );
    return popped;
  }

  static bool _shouldPopTopRoute(NavigatorState nav) {
    final route = _topRoute(nav);
    if (route == null) return false;
    if (route is PopupRoute) return true;
    if (route is ModalRoute) {
      final barrier = route.barrierColor;
      if (barrier != null && barrier.a > 0) return true;
    }
    return false;
  }

  static Route<dynamic>? _topRoute(NavigatorState nav) {
    Route<dynamic>? top;
    nav.popUntil((route) {
      if (route.isCurrent) top = route;
      return true;
    });
    return top;
  }

  static int dismissRoot({String reason = 'root'}) =>
      dismissPopupRoutes(rootNavigatorKey, reason: reason);
}
