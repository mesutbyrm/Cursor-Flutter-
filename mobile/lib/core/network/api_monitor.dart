import 'package:flutter/foundation.dart';

import 'api_backend_kind.dart';

/// Debug modunda HTTP istek günlüğü — API Monitor ekranı.
class ApiMonitorEntry {
  ApiMonitorEntry({
    required this.id,
    required this.url,
    required this.method,
    required this.backend,
    required this.statusCode,
    required this.responseTimeMs,
    required this.retryCount,
    required this.timestamp,
    this.error,
    this.usedGatewayFallback = false,
  });

  final int id;
  final String url;
  final String method;
  final String backend;
  final int? statusCode;
  final int responseTimeMs;
  final int retryCount;
  final DateTime timestamp;
  final String? error;
  final bool usedGatewayFallback;

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 400;
}

/// Global API monitor — yalnızca debug modda kayıt tutar.
abstract final class ApiMonitor {
  static const maxEntries = 500;
  static int _seq = 0;

  static final List<ApiMonitorEntry> _entries = [];
  static final List<VoidCallback> _listeners = [];

  static List<ApiMonitorEntry> get entries =>
      List.unmodifiable(_entries.reversed);

  static void addListener(VoidCallback listener) => _listeners.add(listener);

  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  static void record({
    required String url,
    required String method,
    required ApiBackendKind backend,
    int? statusCode,
    required int responseTimeMs,
    int retryCount = 0,
    String? error,
    bool usedGatewayFallback = false,
  }) {
    if (!kDebugMode) return;
    final entry = ApiMonitorEntry(
      id: ++_seq,
      url: url,
      method: method.toUpperCase(),
      backend: backend.label,
      statusCode: statusCode,
      responseTimeMs: responseTimeMs,
      retryCount: retryCount,
      timestamp: DateTime.now(),
      error: error,
      usedGatewayFallback: usedGatewayFallback,
    );
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    for (final l in List<VoidCallback>.from(_listeners)) {
      l();
    }
  }

  static void clear() {
    if (!kDebugMode) return;
    _entries.clear();
    for (final l in List<VoidCallback>.from(_listeners)) {
      l();
    }
  }
}
