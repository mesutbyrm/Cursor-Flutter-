import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_service.dart';
import 'sse_hub_provider.dart';

Timer? _connectivitySseReconnectDebounce;

/// Çevrimiçi olunca aktif oda SSE'lerini yeniden bağla (debounce — fırtına önleme).
final connectivitySseReconnectProvider = Provider<void>((ref) {
  ref.watch(sseConnectionHubProvider);
  ref.onDispose(() {
    _connectivitySseReconnectDebounce?.cancel();
    _connectivitySseReconnectDebounce = null;
  });
  ref.listen<bool>(isOnlineProvider, (prev, next) {
    if (prev == false && next) {
      _connectivitySseReconnectDebounce?.cancel();
      _connectivitySseReconnectDebounce = Timer(
        const Duration(seconds: 2),
        () {
          unawaited(ref.read(sseConnectionHubProvider).reconnectAllActive());
        },
      );
    }
  });
});
