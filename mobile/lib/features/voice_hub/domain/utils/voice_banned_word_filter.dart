/// Oda yasaklı kelime eşleştirmesi — tam kelime, regex, büyük/küçük harf duyarsız.
class VoiceBannedWordFilter {
  VoiceBannedWordFilter._();

  /// Mesajda listedeki yasak kelimelerden biri **tam kelime** olarak geçiyor mu?
  static bool containsBannedWord(String text, Iterable<String> bannedWords) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    for (final raw in bannedWords) {
      final word = raw.trim();
      if (word.length < 2) continue;
      if (_wholeWordPattern(word).hasMatch(normalized)) return true;
    }
    return false;
  }

  /// Tek kelime için `(?i)` + kelime sınırı regex'i.
  static RegExp _wholeWordPattern(String word) {
    final escaped = RegExp.escape(word.trim());
    return RegExp(
      '(?<![\\p{L}\\p{N}])$escaped(?![\\p{L}\\p{N}])',
      caseSensitive: false,
      unicode: true,
    );
  }
}
