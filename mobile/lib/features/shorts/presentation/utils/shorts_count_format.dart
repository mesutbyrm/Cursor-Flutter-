/// Null-safe sayaç formatı — NaN/Infinity üretmez.
String formatShortCount(num? value) {
  if (value == null || !value.isFinite) return '0';
  final n = value is int ? value : value.round();
  if (n <= 0) return '0';
  if (n >= 1000000) {
    final m = n / 1000000;
    return '${m >= 10 ? m.round() : m.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    final k = n / 1000;
    return '${k >= 10 ? k.round() : k.toStringAsFixed(1)}K';
  }
  return '$n';
}

int safeCount(num? value) {
  if (value == null || !value.isFinite) return 0;
  if (value is int) return value < 0 ? 0 : value;
  final r = value.round();
  return r < 0 ? 0 : r;
}
