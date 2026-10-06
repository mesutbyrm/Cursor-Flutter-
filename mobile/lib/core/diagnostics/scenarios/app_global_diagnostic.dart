library;

import '../cf_diag.dart';
import '../cf_resource_tracker.dart';
import 'diagnostic_common.dart';

abstract final class AppGlobalDiagnosticRoutes {
  static const tour = <String>[
    'splash',
    'login',
    'home',
    'profile',
    'live_fortune',
    'live_stream',
    'voice_room',
    'chat',
    'pk',
    'settings',
  ];
}

abstract final class AppGlobalDiagnosticChecks {
  static void onScreenEnter(String route) {
    CfDiag.screen = route;
    CfDiag.record(
      CfCategory.ui,
      'DIAG enter $route',
      data: {'route': route, 'resources': CfResourceTracker.snapshot().activeByKind},
    );
  }

  static void onScreenExit(String route) {
    CfDiag.record(
      CfCategory.ui,
      'DIAG exit $route',
      data: {'route': route, 'resources': CfResourceTracker.snapshot().activeByKind},
    );
  }
}
