import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_service.dart';
import 'sse_hub_provider.dart';

/// Çevrimiçi olunca aktif oda SSE'lerini yeniden bağla.
final connectivitySseReconnectProvider = Provider<void>((ref) {
  ref.watch(sseConnectionHubProvider);
  ref.listen<bool>(isOnlineProvider, (prev, next) {
    if (prev == false && next) {
      unawaited(ref.read(sseConnectionHubProvider).reconnectAllActive());
    }
  });
});
