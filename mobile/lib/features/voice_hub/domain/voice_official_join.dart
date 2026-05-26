/// Yetkili / VIP oda giriş mesajları — kayan şerit ve sohbet filtresi.
abstract final class VoiceOfficialJoin {
  static bool isOfficialEntrance(String content) {
    final raw = content.trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('[SYSTEM_VIP_JOIN:')) return true;
    final upper = raw.toUpperCase();
    if (!upper.contains('KATILDI') && !upper.contains('JOINED')) return false;
    return upper.contains('MODERATOR') ||
        upper.contains('ADMIN') ||
        upper.contains('STAFF') ||
        upper.contains('VIP') ||
        upper.contains('KURUCU') ||
        upper.contains('FOUNDER') ||
        upper.contains(' SOP ') ||
        raw.startsWith('~') ||
        raw.startsWith('&') ||
        raw.startsWith('@') ||
        raw.startsWith('%');
  }

  static String? latestEntranceBanner(Iterable<String> contents) {
    String? found;
    for (final c in contents) {
      if (isOfficialEntrance(c)) found = c.trim();
    }
    return found;
  }

  /// Komut satırı — sunucu `/` veya `!` ile işler.
  static String normalizeCommandInput(String text) {
    final t = text.trim();
    if (t.startsWith('!')) return '/${t.substring(1)}';
    return t;
  }

  static bool looksLikeRoomCommand(String text) {
    final t = normalizeCommandInput(text);
    return t.startsWith('/') && t.length > 1;
  }
}
