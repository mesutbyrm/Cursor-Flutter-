import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';

/// Bağlantı durumu — [ConnectivityService.onlineStream] ile senkron.
class OnlineStatusNotifier extends Notifier<bool> {
  StreamSubscription<bool>? _sub;

  @override
  bool build() {
    final service = ref.watch(connectivityServiceProvider);
    _sub?.cancel();
    _sub = service.onlineStream.listen((online) {
      if (state != online) state = online;
    });
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      _sub = null;
    });
    return service.isOnline;
  }
}

final isOnlineProvider =
    NotifierProvider<OnlineStatusNotifier, bool>(OnlineStatusNotifier.new);
