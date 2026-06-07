import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../live/presentation/providers/live_providers.dart';
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

  void start() {
    if (!Env.useNextAuth) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    _ref.invalidate(homeLiveStreamsProvider);
    _ref.invalidate(homeVoiceRoomsProvider);
    _ref.invalidate(liveStreamsProvider);
    _ref.invalidate(voiceRoomsProvider);
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
