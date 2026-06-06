import 'package:flutter/foundation.dart';

/// Canlı yayın akışı — yalnızca debug modda log.
abstract final class LiveDebugLog {
  static void log(String phase, [Map<String, Object?>? data]) {
    if (!kDebugMode) return;
    final extra = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[Live] $phase$extra');
  }
}
