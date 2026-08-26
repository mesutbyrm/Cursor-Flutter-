/// HTML/API gövdesini ekranda gösterecek düz metne çevirir.
String htmlToPlainText(String input) {
  var s = input;
  s = s.replaceAll(
    RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
    '',
  );
  s = s.replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
  s = s.replaceAll(
    RegExp(r'<(br|p|div|li|tr|h[1-6])\b[^>]*>', caseSensitive: false),
    '\n',
  );
  s = s.replaceAll(
    RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false),
    '\n',
  );
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
  s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  s = s.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return s.trim();
}
