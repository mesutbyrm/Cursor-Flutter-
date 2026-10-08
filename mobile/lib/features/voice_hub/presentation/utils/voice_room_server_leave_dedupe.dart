import 'dart:async';

/// Aynı oda + kullanıcı için eşzamanlı sunucu leave isteklerini tekilleştirir (409 önleme).
final class VoiceRoomServerLeaveDedupe {
  VoiceRoomServerLeaveDedupe._();

  static final Map<String, Future<bool>> _inFlight = {};

  static String key(String roomKey, String? userId) {
    final r = roomKey.trim();
    final u = userId?.trim() ?? '';
    return '$r|$u';
  }

  static Future<bool> run({
    required String roomKey,
    String? userId,
    required Future<bool> Function() operation,
  }) async {
    final k = key(roomKey, userId);
    final existing = _inFlight[k];
    if (existing != null) {
      return existing;
    }
    late final Future<bool> tracked;
    tracked = operation().whenComplete(() {
      if (_inFlight[k] == tracked) {
        _inFlight.remove(k);
      }
    });
    _inFlight[k] = tracked;
    return tracked;
  }
}
