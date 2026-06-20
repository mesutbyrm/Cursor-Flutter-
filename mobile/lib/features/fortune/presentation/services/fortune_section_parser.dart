import '../../domain/entities/fortune_reading_section.dart';

/// API / markdown metninden yapılandırılmış fal bölümlerini çıkarır.
class FortuneSectionParser {
  const FortuneSectionParser();

  static final _headerPatterns = <RegExp>[
    RegExp(
      r'^(?:#{1,3}\s*)?(Genel\s*Enerji|Aşk\s*Hayatı|İş\s*(?:ve\s*)?Kariyer|Para\s*Durumu|Yakın\s*Gelecek|Tavsiye)\s*:?\s*$',
      caseSensitive: false,
      multiLine: true,
    ),
    RegExp(
      r'^\*\*(Genel\s*Enerji|Aşk\s*Hayatı|İş\s*(?:ve\s*)?Kariyer|Para\s*Durumu|Yakın\s*Gelecek|Tavsiye)\*\*\s*:?\s*$',
      caseSensitive: false,
      multiLine: true,
    ),
  ];

  static const _titleToKey = <String, String>{
    'genel enerji': FortuneSectionKeys.general,
    'aşk hayatı': FortuneSectionKeys.love,
    'iş ve kariyer': FortuneSectionKeys.career,
    'iş kariyer': FortuneSectionKeys.career,
    'para durumu': FortuneSectionKeys.money,
    'yakın gelecek': FortuneSectionKeys.future,
    'tavsiye': FortuneSectionKeys.advice,
  };

  List<FortuneReadingSection> parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    for (final pattern in _headerPatterns) {
      final matches = pattern.allMatches(text).toList();
      if (matches.length >= 2) {
        return _extractFromMatches(text, matches);
      }
    }

    // Tek satırlık başlık: "Genel Enerji:" ile başlayan paragraflar
    final alt = RegExp(
      r'(Genel\s*Enerji|Aşk\s*Hayatı|İş\s*(?:ve\s*)?Kariyer|Para\s*Durumu|Yakın\s*Gelecek|Tavsiye)\s*:\s*',
      caseSensitive: false,
    );
    final altMatches = alt.allMatches(text).toList();
    if (altMatches.length >= 2) {
      return _extractInline(text, altMatches);
    }

    return const [];
  }

  List<FortuneReadingSection> ensureSections({
    required List<FortuneReadingSection> parsed,
    required String fallbackDetail,
  }) {
    if (parsed.length >= 4) {
      return _withDelays(parsed);
    }
    return _withDelays(_splitEvenly(fallbackDetail));
  }

  List<FortuneReadingSection> _extractFromMatches(
    String text,
    List<RegExpMatch> matches,
  ) {
    final sections = <FortuneReadingSection>[];
    for (var i = 0; i < matches.length; i++) {
      final titleRaw = matches[i].group(1)!.trim();
      final key = _keyForTitle(titleRaw);
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final body = text.substring(start, end).trim();
      if (body.isEmpty) continue;
      sections.add(
        FortuneReadingSection(
          key: key,
          title: FortuneSectionKeys.titles[key] ?? titleRaw,
          body: body,
        ),
      );
    }
    return sections;
  }

  List<FortuneReadingSection> _extractInline(
    String text,
    List<RegExpMatch> matches,
  ) {
    final sections = <FortuneReadingSection>[];
    for (var i = 0; i < matches.length; i++) {
      final titleRaw = matches[i].group(1)!.trim();
      final key = _keyForTitle(titleRaw);
      final start = matches[i].end;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final body = text.substring(start, end).trim();
      if (body.isEmpty) continue;
      sections.add(
        FortuneReadingSection(
          key: key,
          title: FortuneSectionKeys.titles[key] ?? titleRaw,
          body: body,
        ),
      );
    }
    return sections;
  }

  String _keyForTitle(String title) {
    final norm = title.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return _titleToKey[norm] ?? FortuneSectionKeys.general;
  }

  List<FortuneReadingSection> _splitEvenly(String detail) {
    final sentences = detail
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.isEmpty) {
      return [
        FortuneReadingSection(
          key: FortuneSectionKeys.general,
          title: FortuneSectionKeys.titles[FortuneSectionKeys.general]!,
          body: detail,
        ),
      ];
    }

    final keys = FortuneSectionKeys.ordered;
    final perSection = (sentences.length / keys.length).ceil().clamp(1, 8);
    final sections = <FortuneReadingSection>[];
    var idx = 0;
    for (final key in keys) {
      if (idx >= sentences.length) break;
      final chunk = sentences.skip(idx).take(perSection).join(' ');
      idx += perSection;
      if (chunk.trim().isEmpty) continue;
      sections.add(
        FortuneReadingSection(
          key: key,
          title: FortuneSectionKeys.titles[key]!,
          body: chunk.trim(),
        ),
      );
    }
    return sections;
  }

  List<FortuneReadingSection> _withDelays(List<FortuneReadingSection> sections) {
    return [
      for (var i = 0; i < sections.length; i++)
        FortuneReadingSection(
          key: sections[i].key,
          title: sections[i].title,
          body: sections[i].body,
          delaySeconds: i + 1,
        ),
    ];
  }
}
