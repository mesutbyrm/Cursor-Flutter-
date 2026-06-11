import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import 'app_startup_log.dart';

/// Yarım kalmış dialog / bottom sheet katmanlarını temizler.
abstract final class StuckOverlayGuard {
  /// [Navigator] üstündeki [PopupRoute] katmanlarını kaldırır;
  /// GoRouter sayfa rotalarına dokunmaz.
  static int dismissPopupRoutes(
    GlobalKey<NavigatorState> navigatorKey, {
    String reason = 'manual',
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      AppStartupLog.overlayHide(reason: reason, note: 'nav-null');
      return 0;
    }

    final couldPopBefore = nav.canPop();
    if (!couldPopBefore) {
      AppStartupLog.overlayHide(reason: reason, popped: 0, canStillPop: false);
      return 0;
    }

    var popped = 0;
    for (var i = 0; i < 8; i++) {
      if (!nav.canPop()) break;
      final before = nav.canPop();
      nav.popUntil((route) => route is! PopupRoute);
      if (before && !nav.canPop()) {
        popped++;
        break;
      }
      if (before && nav.canPop()) {
        popped++;
        continue;
      }
      break;
    }

    AppStartupLog.overlayHide(
      reason: reason,
      popped: popped,
      canStillPop: nav.canPop(),
    );
    return popped;
  }

  /// Kök navigator — uygulama geneli temizlik.
  static int dismissRoot({String reason = 'root'}) =>
      dismissPopupRoutes(rootNavigatorKey, reason: reason);
}
