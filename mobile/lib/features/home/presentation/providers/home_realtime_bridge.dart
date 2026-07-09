import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_providers.dart';

/// Socket.IO olaylarında ana sayfa listelerini yeniler.
final homeRealtimeBridgeProvider = Provider<HomeRealtimeBridge>((ref) {
  final bridge = HomeRealtimeBridge(ref);
  ref.onDispose(bridge.dispose);
  return bridge;
});

class HomeRealtimeBridge {
  HomeRealtimeBridge(this._ref);

  final Ref _ref;
  Timer? _pollTimer;
  var _disposed = false;

  void start() {
    if (!Env.useNextAuth) return;
    _disposed = false;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 180), (_) => _tick());
  }

  void _tick() {
    if (_disposed || _pollTimer == null) return;
    // invalidate yerine refresh — önceki veri korunur, iskelet flash olmaz.
    unawaited(_ref.refresh(homeLiveStreamsProvider.future));
    unawaited(_ref.refresh(homeVoiceRoomsProvider.future));
    // voiceRoomsProvider: SSE presence (voiceRoomsPresenceProvider) ile güncellenir.
  }

  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
