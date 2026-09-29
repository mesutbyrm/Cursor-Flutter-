import 'dart:convert';

/// SSE bayt parçalarını metne çevirir; parça sınırında bölünen çok baytlı
/// UTF-8 karakterleri (ş, ğ, ı, emoji…) bir sonraki parçaya kadar bekletir.
///
/// Her parçayı ayrı `utf8.decode` etmek bölünen karakteri `�` yapar, JSON
/// bozulur ve o SSE olayı sessizce kaybolur.
class SseChunkDecoder {
  List<int> _pending = const [];

  String convert(List<int> chunk) {
    final bytes = _pending.isEmpty ? chunk : [..._pending, ...chunk];
    final cut = completePrefixLength(bytes);
    _pending = cut == bytes.length ? const [] : bytes.sublist(cut);
    if (cut == 0) return '';
    return utf8.decode(
      cut == bytes.length ? bytes : bytes.sublist(0, cut),
      allowMalformed: true,
    );
  }

  void reset() => _pending = const [];

  /// Sondaki eksik UTF-8 dizisi hariç tam çözülebilir önek uzunluğu.
  static int completePrefixLength(List<int> b) {
    for (var i = 1; i <= 3 && i <= b.length; i++) {
      final byte = b[b.length - i];
      if (byte & 0xC0 == 0x80) continue; // devam baytı
      final need = byte >= 0xF0
          ? 4
          : byte >= 0xE0
          ? 3
          : byte >= 0xC0
          ? 2
          : 1;
      return need > i ? b.length - i : b.length;
    }
    return b.length;
  }
}
