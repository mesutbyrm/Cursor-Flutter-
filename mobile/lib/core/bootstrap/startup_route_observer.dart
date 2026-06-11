import 'package:flutter/material.dart';

import 'app_startup_log.dart';

/// Navigator yığını — gri overlay / takılı modal teşhisi.
class StartupRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final modal = route is ModalRoute<dynamic> ? route : null;
    final barrier = modal?.barrierColor;
    AppStartupLog.log(
      'didPush ${route.settings.name ?? route.runtimeType} '
      'barrier=$barrier opaque=${modal?.opaque ?? true}',
    );
    if (route is PopupRoute || (barrier != null && barrier.a > 0)) {
      AppStartupLog.overlayShow(
        source: route.runtimeType.toString(),
        detail: 'barrier=$barrier',
      );
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppStartupLog.log(
      'didPop ${route.settings.name ?? route.runtimeType}',
    );
    if (route is PopupRoute) {
      AppStartupLog.overlayHide(reason: 'didPop-${route.runtimeType}');
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppStartupLog.log(
      'didRemove ${route.settings.name ?? route.runtimeType}',
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppStartupLog.log(
      'didReplace ${oldRoute?.settings.name ?? oldRoute?.runtimeType} '
      '→ ${newRoute?.settings.name ?? newRoute?.runtimeType}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
