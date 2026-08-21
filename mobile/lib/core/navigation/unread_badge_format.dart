/// Rozet sayısı gösterimi — 999+ üst sınır.
abstract final class UnreadBadgeFormat {
  static String label(int count) {
    if (count <= 0) return '';
    if (count > 999) return '999+';
    if (count > 9) return '9+';
    return '$count';
  }
}
