/// `GET /api/homepage-ticker` gövdesinden kayan yazı satırları.
abstract final class HomepageTickerParser {
  static List<String> linesFromBody(dynamic body) {
    final lines = <String>[];
    void add(String? raw) {
      final t = raw?.trim() ?? '';
      if (t.isEmpty) return;
      if (!lines.contains(t)) lines.add(t);
    }

    if (body is String) {
      add(body);
      return lines;
    }
    if (body is List) {
      for (final item in body) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          add(_lineFromMap(Map<String, dynamic>.from(item)));
        }
      }
      return lines;
    }
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      for (final key in const [
        'customMessages',
        'items',
        'tickers',
        'messages',
        'recentGifts',
        'gifts',
        'data',
        'lines',
      ]) {
        final nested = m[key];
        if (nested != null) {
          for (final line in linesFromBody(nested)) {
            add(line);
          }
        }
      }
      add(
        (m['message'] ?? m['text'] ?? m['title'] ?? m['content'])?.toString(),
      );
    }
    return lines;
  }

  static String? _lineFromMap(Map<String, dynamic> m) {
    final text = (m['message'] ??
            m['text'] ??
            m['title'] ??
            m['content'] ??
            m['line'] ??
            m['ticker'])
        ?.toString()
        .trim();
    final icon = (m['icon'] ?? m['emoji'] ?? m['iconEmoji'])?.toString().trim();
    if (text == null || text.isEmpty) return null;
    if (icon != null && icon.isNotEmpty && !text.startsWith(icon)) {
      return '$icon $text';
    }
    return text;
  }
}
