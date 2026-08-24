import '../providers/chat_room_providers.dart';

/// Sesli oda hata şeridi — geçici/sunucu uyumsuzluk mesajlarını gizler.
abstract final class VoiceRoomErrorDisplay {
  static String? bannerMessage(
    String? raw, {
    required VoiceRoomLiveState live,
  }) {
    if (raw == null || raw.trim().isEmpty) return null;
    final msg = _normalize(raw);
    if (_shouldSuppress(msg, live)) return null;
    return msg;
  }

  static String _normalize(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid type') || lower.contains('geçersiz alan')) {
      return 'Sunucu isteği reddetti (geçersiz alan). Tekrar deneyin.';
    }
    return raw;
  }

  static bool _shouldSuppress(String msg, VoiceRoomLiveState live) {
    final lower = msg.toLowerCase();
    final transientNetwork = lower.contains('zaman aşımı') ||
        lower.contains('timeout') ||
        lower.contains('sunucu yanıt vermedi') ||
        lower.contains('bağlantı kurulamadı');
    if (transientNetwork &&
        (live.selfInRoom || live.presence.isNotEmpty || live.sseConnected)) {
      return true;
    }
    if (!live.selfInRoom && live.presence.isEmpty && !live.sseConnected) {
      return false;
    }
    return lower.contains('invalid type') ||
        lower.contains('geçersiz alan') ||
        lower.contains('no voice permission');
  }
}
