/// Yetkili / VIP oda giriş mesajları — kayan şerit ve sohbet filtresi.
abstract final class VoiceOfficialJoin {
  static bool isOfficialEntrance(String content) {
    final raw = content.trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('[SYSTEM_VIP_JOIN:')) return true;
    final upper = raw.toUpperCase();
    if (!upper.contains('KATILDI') && !upper.contains('JOINED')) return false;
    return upper.contains('MODERATOR') ||
        upper.contains('MODERAT') ||
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

  /// Giriş şeridi — yalnızca kullanıcı adı, «MODERATÖR» etiketi yok.
  static String formatEntranceBanner(String raw, {String? roomName}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('[SYSTEM_VIP_JOIN:')) {
      final inner = trimmed
          .replaceFirst('[SYSTEM_VIP_JOIN:', '')
          .replaceAll(']', '');
      final parts = inner.split(':');
      final name = parts.length > 1
          ? parts.sublist(1).join(':').trim()
          : (parts.isNotEmpty ? parts.first : 'Kullanıcı');
      return _joinLine(_cleanDisplayName(name), roomName);
    }

    final parsed = _parseEntranceName(trimmed);
    if (parsed != null) return _joinLine(parsed, roomName);

    if (isOfficialEntrance(trimmed)) {
      return _joinLine(_cleanDisplayName(trimmed), roomName);
    }

    return trimmed.contains('📣') ? trimmed : '📣 $trimmed';
  }

  static String _joinLine(String name, String? roomName) {
    final room = roomName?.trim();
    if (room != null && room.isNotEmpty) {
      return '📣 $name $room sesli odasına katıldı';
    }
    return '📣 $name odaya katıldı';
  }

  /// «MODERATÖR İlham Perisi … katıldı» → «İlham Perisi»
  static String? _parseEntranceName(String raw) {
    var s = raw.replaceAll(RegExp(r'^[📣\s]+'), '').trim();
    s = s.replaceAll(
      RegExp(
        r'^(MODERATÖR|MODERATOR|MODERAT|ADMIN|YETKİLİ|YETKILI|STAFF|VIP|KURUCU|FOUNDER|SOP)\s+',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(
      RegExp(
        r'\s+(sesli\s+)?od(a|ası)na\s+katıldı.*$',
        caseSensitive: false,
      ),
      '',
    );
    s = s.replaceAll(RegExp(r'\s+joined.*$', caseSensitive: false), '');
    s = _cleanDisplayName(s);
    return s.isEmpty ? null : s;
  }

  static String _cleanDisplayName(String name) {
    return name
        .replaceFirst(RegExp(r'^[~&@%]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool isClearChatCommand(String text) {
    final t = text.trim().toLowerCase();
    return t == '!temizle' || t == '/temizle';
  }

  /// Komut satırı — canlifal.com sohbet `!` ile çalışır; `/` dönüşümü yapılmaz.
  static String normalizeCommandInput(String text) => text.trim();

  static bool looksLikeRoomCommand(String text) {
    final t = text.trim();
    if (t.length < 2) return false;
    return (t.startsWith('!') || t.startsWith('/')) && t.length > 1;
  }
}
