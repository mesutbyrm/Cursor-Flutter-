/// Canlı yayın sohbet — spam ve küfür koruması (istemci tarafı).
class LiveChatGuard {
  LiveChatGuard._();

  static const _minIntervalMs = 1200;
  static const _maxRepeat = 2;
  static const _maxLength = 280;

  static int? _lastSendMs;
  static String? _lastMessage;
  static var _repeatCount = 0;

  static final _profanity = <String>{
    'amk', 'aq', 'orospu', 'piç', 'siktir', 'sikeyim', 'göt', 'yarrak',
    'fuck', 'shit', 'bitch', 'asshole',
  };

  /// `null` = gönderilebilir; aksi halde kullanıcıya gösterilecek mesaj.
  static String? validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Mesaj boş olamaz';
    if (text.length > _maxLength) {
      return 'Mesaj en fazla $_maxLength karakter olabilir';
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastSendMs != null && now - _lastSendMs! < _minIntervalMs) {
      return 'Çok hızlı yazıyorsunuz — biraz bekleyin';
    }

    if (text.toLowerCase() == _lastMessage?.toLowerCase()) {
      _repeatCount++;
      if (_repeatCount >= _maxRepeat) {
        return 'Aynı mesajı tekrar gönderemezsiniz';
      }
    } else {
      _repeatCount = 0;
      _lastMessage = text;
    }

    if (_containsProfanity(text)) {
      return 'Mesajınız topluluk kurallarına aykırı ifadeler içeriyor';
    }

    return null;
  }

  static void markSent(String text) {
    _lastSendMs = DateTime.now().millisecondsSinceEpoch;
    _lastMessage = text.trim();
  }

  static String sanitizeForDisplay(String text) {
    var out = text;
    for (final word in _profanity) {
      if (word.length < 3) continue;
      final pattern = RegExp(word, caseSensitive: false);
      out = out.replaceAll(pattern, '*' * word.length);
    }
    return out;
  }

  static bool _containsProfanity(String text) {
    final lower = text.toLowerCase();
    for (final word in _profanity) {
      if (lower.contains(word)) return true;
    }
    return false;
  }

  /// Testler için sıfırla.
  static void resetForTest() {
    _lastSendMs = null;
    _lastMessage = null;
    _repeatCount = 0;
  }
}
