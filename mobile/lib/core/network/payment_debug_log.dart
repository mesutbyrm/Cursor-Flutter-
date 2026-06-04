import 'package:flutter/foundation.dart';

/// Jeton / CFC ödeme talebi — yalnızca debug modda ayrıntılı log.
abstract final class PaymentDebugLog {
  static void log(String phase, [Map<String, Object?>? data]) {
    if (!kDebugMode) return;
    final extra = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[Payment] $phase$extra');
  }
}
