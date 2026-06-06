import 'package:flutter/foundation.dart';

/// Sesli oda akışı — yalnızca debug modda yapılandırılmış log.
abstract final class VoiceRoomDebugLog {
  static void log(String phase, [Map<String, Object?>? data]) {
    if (!kDebugMode) return;
    final extra = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint('[VoiceRoom] $phase$extra');
  }
}
