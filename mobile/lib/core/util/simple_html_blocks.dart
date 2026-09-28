/// AI yanıtlarındaki basit HTML'i (başlık / paragraf / liste) düz bloklara çevirir.
enum HtmlBlockKind { heading, paragraph, bullet }

class HtmlBlock {
  const HtmlBlock(this.kind, this.text);

  final HtmlBlockKind kind;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is HtmlBlock && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'HtmlBlock($kind, $text)';
}

final _fence = RegExp(r'^```[a-zA-Z]*\s*|\s*```$');
final _blockTag = RegExp(
  r'<(h[1-6]|p|li|div|tr)\b[^>]*>([\s\S]*?)</\1\s*>',
  caseSensitive: false,
);
final _br = RegExp(r'<br\s*/?>', caseSensitive: false);
final _anyTag = RegExp(r'<[^>]+>');
final _spaces = RegExp(r'[ \t]+');

String _decode(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");

String _clean(String s) =>
    _decode(s.replaceAll(_br, '\n').replaceAll(_anyTag, ''))
        .split('\n')
        .map((l) => l.replaceAll(_spaces, ' ').trim())
        .where((l) => l.isNotEmpty)
        .join('\n');

List<HtmlBlock> parseSimpleHtml(String raw) {
  final html = raw.trim().replaceAll(_fence, '').trim();
  if (html.isEmpty) return const [];
  final blocks = <HtmlBlock>[];
  var last = 0;
  void addLoose(String chunk) {
    final text = _clean(chunk);
    for (final line in text.split('\n')) {
      if (line.isNotEmpty) blocks.add(HtmlBlock(HtmlBlockKind.paragraph, line));
    }
  }

  for (final m in _blockTag.allMatches(html)) {
    if (m.start > last) addLoose(html.substring(last, m.start));
    last = m.end;
    final tag = m.group(1)!.toLowerCase();
    final inner = m.group(2)!;
    if (tag == 'div' && _blockTag.hasMatch(inner)) {
      blocks.addAll(parseSimpleHtml(inner));
      continue;
    }
    final text = _clean(inner);
    if (text.isEmpty) continue;
    final kind = tag.startsWith('h')
        ? HtmlBlockKind.heading
        : tag == 'li'
            ? HtmlBlockKind.bullet
            : HtmlBlockKind.paragraph;
    blocks.add(HtmlBlock(kind, text));
  }
  if (last < html.length) addLoose(html.substring(last));
  return blocks;
}
