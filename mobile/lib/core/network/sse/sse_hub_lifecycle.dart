import 'package:flutter/widgets.dart';

import 'sse_connection_hub.dart';

/// Hub SSE — arka planda kapat, ön planda aynı lease ile yeniden bağla.
class SseHubLifecycleBinding with WidgetsBindingObserver {
  SseHubLifecycleBinding(this.hub);

  final SseConnectionHub hub;
  var _attached = false;

  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
  }

  void dispose() {
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        hub.pauseAllForBackground();
      case AppLifecycleState.resumed:
        hub.resumeAllFromBackground();
    }
  }
}
