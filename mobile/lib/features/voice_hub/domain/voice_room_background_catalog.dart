import '../../../core/config/env.dart';

/// canlifal.com sesli oda arka planları — `/images/voice-bg-{n}.jpg` (web ile aynı).
abstract final class VoiceRoomBackgroundCatalog {
  static String get _origin {
    var base = Env.siteOrigin.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return base;
  }

  static const int count = 20;

  static List<String> siteDefaults() {
    return List.generate(
      count,
      (i) => '${_origin}/images/voice-bg-${i + 1}.jpg',
    );
  }

  static List<String> parseApiList(dynamic raw) {
    final out = <String>[];
    if (raw is! List) return out;
    for (final e in raw) {
      final url = _parseEntry(e);
      if (url != null && url.isNotEmpty) out.add(url);
    }
    return out;
  }

  static String? _parseEntry(dynamic e) {
    if (e is String) return _normalizeUrl(e);
    if (e is Map) {
      final m = Map<String, dynamic>.from(e);
      for (final key in ['url', 'image', 'backgroundImage', 'src', 'href']) {
        final v = m[key]?.toString();
        if (v != null && v.isNotEmpty) return _normalizeUrl(v);
      }
    }
    return null;
  }

  static String? _normalizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('/')) return '${_origin}$trimmed';
    return '$_origin/$trimmed';
  }
}
