/// Yetkili / VIP oda giriş mesajları — kayan şerit ve sohbet filtresi.
abstract final class VoiceOfficialJoin {
  /// Aynı giriş şeridini oturumda bir kez göstermek için anahtar.
  static String entranceDedupeKey(String raw, {String? roomName}) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('[SYSTEM_VIP_JOIN:')) {
      return 'vip:$trimmed:${roomName ?? ''}';
    }
    final formatted = formatEntranceBanner(trimmed, roomName: roomName);
    if (formatted.isNotEmpty) {
      return 'entrance:${formatted.toLowerCase()}';
    }
    final name = _parseEntranceName(trimmed) ?? _cleanDisplayName(trimmed);
    final room = roomName?.trim().toLowerCase() ?? '';
    return 'entrance:${name.toLowerCase()}:$room';
  }

  static bool isOfficialEntrance(String content) {
    final raw = content.trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('[SYSTEM_VIP_JOIN:')) return true;
    final upper = raw.toUpperCase();
    if (!upper.contains('KATILDI') &&
        !upper.contains('JOINED') &&
        !upper.contains('GİRİŞ YAPTI') &&
        !upper.contains('GIRIS YAPTI')) {
      return false;
    }
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

    if (_looksLikeFormattedEntrance(trimmed)) {
      return _stripDuplicateRoom(trimmed, roomName);
    }

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

  static bool _looksLikeFormattedEntrance(String raw) {
    final lower = raw.toLowerCase();
    return lower.contains('sesli odasına') ||
        lower.contains('odaya katıldı') ||
        lower.contains('giriş yaptı') ||
        lower.contains('giris yaptı');
  }

  static String _stripDuplicateRoom(String raw, String? roomName) {
    var line = raw.trim();
    if (!line.startsWith('📣')) line = '📣 $line';
    final room = roomName?.trim();
    if (room == null || room.isEmpty) return line;
    final escaped = RegExp.escape(room);
    line = line.replaceAll(
      RegExp('$escaped\\s+$escaped', caseSensitive: false),
      room,
    );
    return line;
  }

  static String _joinLine(String name, String? roomName) {
    final cleanName = _cleanDisplayName(name);
    final room = roomName?.trim();
    if (room != null && room.isNotEmpty) {
      final lower = cleanName.toLowerCase();
      final roomLower = room.toLowerCase();
      if (lower.contains(roomLower) &&
          (_looksLikeFormattedEntrance(cleanName) ||
              lower.contains('katıldı') ||
              lower.contains('giriş'))) {
        return _stripDuplicateRoom(cleanName, roomName);
      }
      return '📣 $cleanName $room sesli odasına katıldı';
    }
    return '📣 $cleanName odaya katıldı';
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

  /// `%Admin !temizle` gibi önekli satırlardan komutu ayıklar.
  static String extractCommandBody(String text) {
    final t = text.trim();
    final match = RegExp(r'[!/][\wğüşıöçĞÜŞİÖÇ-]+', caseSensitive: false)
        .firstMatch(t);
    if (match == null) return t;
    final start = match.start;
    if (start > 0) return t.substring(start).trim();
    return t;
  }

  static bool isClearChatCommand(String text) {
    final t = extractCommandBody(text).trim().toLowerCase();
    return t == '!temizle' || t == '/temizle';
  }

  /// Komut satırı — canlifal.com sohbet `!` ile çalışır.
  static String normalizeCommandInput(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('!') || trimmed.startsWith('/')) return trimmed;
    return extractCommandBody(trimmed);
  }

  static bool looksLikeRoomCommand(String text) {
    final t = text.trim();
    if (t.length < 2) return false;
    return (t.startsWith('!') || t.startsWith('/')) && t.length > 1;
  }
}
