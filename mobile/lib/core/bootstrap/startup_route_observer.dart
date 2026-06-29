import 'package:flutter/material.dart';

import '../performance/app_perf_metrics.dart';
import 'app_startup_log.dart';
import 'root_overlay_purge.dart';

/// Navigator yığını — overlay teşhisi + ekran geçiş süresi ölçümü.
class StartupRouteObserver extends NavigatorObserver {
  DateTime? _lastNavAt;

  void _recordTransition(String? from, String? to) {
    if (from == null || to == null) {
      _lastNavAt = DateTime.now();
      return;
    }
    final started = _lastNavAt;
    if (started != null) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      AppPerfMetrics.recordRoute(from, to, ms);
    }
    _lastNavAt = DateTime.now();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _recordTransition(
      previousRoute?.settings.name ?? previousRoute?.runtimeType.toString(),
      route.settings.name ?? route.runtimeType.toString(),
    );
    final modal = route is ModalRoute<dynamic> ? route : null;
    final barrier = modal?.barrierColor;
    AppStartupLog.log(
      'didPush ${route.settings.name ?? route.runtimeType} '
      'barrier=$barrier opaque=${modal?.opaque ?? true}',
    );
    if (route is PopupRoute || (barrier != null && barrier.a > 0)) {
      BarrierRouteJournal.recordPush(route);
      AppStartupLog.overlayShow(
        source: route.runtimeType.toString(),
        detail: 'barrier=$barrier',
      );
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _recordTransition(
      route.settings.name ?? route.runtimeType.toString(),
      previousRoute?.settings.name ?? previousRoute?.runtimeType.toString(),
    );
    AppStartupLog.log(
      'didPop ${route.settings.name ?? route.runtimeType}',
    );
    BarrierRouteJournal.recordPop(route);
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
    BarrierRouteJournal.recordPop(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _recordTransition(
      oldRoute?.settings.name ?? oldRoute?.runtimeType.toString(),
      newRoute?.settings.name ?? newRoute?.runtimeType.toString(),
    );
    AppStartupLog.log(
      'didReplace ${oldRoute?.settings.name ?? oldRoute?.runtimeType} '
      '→ ${newRoute?.settings.name ?? newRoute?.runtimeType}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
