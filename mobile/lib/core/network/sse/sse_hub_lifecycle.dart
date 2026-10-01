import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../bootstrap/app_startup_log.dart';
import 'sse_connection_hub.dart';

/// Hub SSE — arka planda kapat, ön planda aynı lease ile yeniden bağla.
class SseHubLifecycleBinding with WidgetsBindingObserver {
  SseHubLifecycleBinding(this.hub);

  final SseConnectionHub hub;
  var _attached = false;
  Timer? _resumeDebounce;
  var _backgrounded = false;

  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  void dispose() {
    _resumeDebounce?.cancel();
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
  }

  void _scheduleResume() {
    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!_backgrounded) return;
      _backgrounded = false;
      AppStartupLog.appResume();
      unawaited(hub.resumeAllFromBackground());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (!_backgrounded) {
          _backgrounded = true;
          AppStartupLog.appPause();
          unawaited(hub.pauseAllForBackground());
        }
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        _scheduleResume();
    }
  }
}
