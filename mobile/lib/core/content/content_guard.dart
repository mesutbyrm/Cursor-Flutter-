/// Kısa video yorum / açıklama — spam ve küfür koruması (istemci).
class ContentGuard {
  ContentGuard._();

  static const minIntervalMs = 1200;
  static const maxRepeat = 2;
  static const maxLength = 500;

  static int? _lastSendMs;
  static String? _lastMessage;
  static var _repeatCount = 0;

  static final _profanity = <String>{
    'amk', 'aq', 'orospu', 'piç', 'siktir', 'sikeyim', 'göt', 'yarrak',
    'fuck', 'shit', 'bitch', 'asshole',
  };

  static final _spamPatterns = <RegExp>[
    RegExp(r'https?://[^\s]+', caseSensitive: false),
    RegExp(r'(t\.me|telegram\.me|wa\.me|bit\.ly)', caseSensitive: false),
    RegExp(r'(\+90|0)?5\d{9}'),
  ];

  /// `null` = gönderilebilir; aksi halde kullanıcı mesajı.
  static String? validate(String raw, {int maxLen = maxLength}) {
    final text = raw.trim();
    if (text.isEmpty) return 'Metin boş olamaz';
    if (text.length > maxLen) {
      return 'En fazla $maxLen karakter yazabilirsiniz';
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastSendMs != null && now - _lastSendMs! < minIntervalMs) {
      return 'Çok hızlı gönderiyorsunuz — biraz bekleyin';
    }

    if (text.toLowerCase() == _lastMessage?.toLowerCase()) {
      _repeatCount++;
      if (_repeatCount >= maxRepeat) {
        return 'Aynı metni tekrar gönderemezsiniz';
      }
    } else {
      _repeatCount = 0;
      _lastMessage = text;
    }

    if (_containsProfanity(text)) {
      return 'Metniniz topluluk kurallarına aykırı ifadeler içeriyor';
    }

    if (_looksLikeSpam(text)) {
      return 'Spam veya reklam içeriği tespit edildi';
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

  static bool _looksLikeSpam(String text) {
    var linkCount = 0;
    for (final p in _spamPatterns) {
      linkCount += p.allMatches(text).length;
    }
    return linkCount >= 2;
  }

  static void resetForTest() {
    _lastSendMs = null;
    _lastMessage = null;
    _repeatCount = 0;
  }
}
