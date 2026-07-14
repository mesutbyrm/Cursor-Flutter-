import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'online_status_notifier.dart' show isOnlineProvider;

/// İnternet bağlantı durumu — offline mod ve istek duraklatma.
class ConnectivityService {
  ConnectivityService() {
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
    unawaited(refresh());
  }

  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  var _online = true;

  bool get isOnline => _online;

  Stream<bool> get onlineStream => _controller.stream;

  Future<void> refresh() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _apply(results);
    } catch (_) {
      _apply([ConnectivityResult.none]);
    }
  }

  void _onChanged(List<ConnectivityResult> results) => _apply(results);

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _online) return;
    _online = online;
    if (kDebugMode) {
      debugPrint('[Connectivity] online=$online results=$results');
    }
    if (!_controller.isClosed) {
      _controller.add(online);
    }
  }

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
    unawaited(_controller.close());
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});
