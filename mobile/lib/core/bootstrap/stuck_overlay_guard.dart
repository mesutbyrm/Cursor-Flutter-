import 'package:flutter/material.dart';

import 'app_startup_log.dart';

/// Yarım kalmış dialog / bottom sheet katmanlarını temizler.
abstract final class StuckOverlayGuard {
  /// [Navigator] üstündeki yalnızca [PopupRoute] katmanlarını kaldırır;
  /// GoRouter [PageRoute] sayfalarına dokunmaz.
  static void dismissPopupRoutes(GlobalKey<NavigatorState> navigatorKey) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final couldPopBefore = nav.canPop();
    nav.popUntil((route) => route is! PopupRoute);

    AppStartupLog.overlay(
      action: 'popUntil(!PopupRoute)',
      popupRoutesPopped: couldPopBefore && !nav.canPop() ? 1 : 0,
      canStillPop: nav.canPop(),
    );
  }
}
