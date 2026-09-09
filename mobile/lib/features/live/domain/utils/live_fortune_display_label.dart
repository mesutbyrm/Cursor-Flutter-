import '../../../fortune/presentation/data/fortune_catalog.dart';

/// Fal türü anahtarı → kullanıcıya gösterilen etiket (emoji + Türkçe ad).
({String emoji, String title}) liveFortuneTypePresentation(String raw) {
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) {
    return (emoji: '🔮', title: 'Fal');
  }

  final slug = _legacyKeyToSlug(key);
  final catalog = FortuneCatalog.bySlug(slug);
  if (catalog != null) {
    return (emoji: catalog.emoji, title: catalog.title);
  }

  return switch (key) {
    'coffee' || 'kahve' => (emoji: '☕', title: 'Kahve Falı'),
    'tarot' => (emoji: '🃏', title: 'Tarot'),
    'astrology' || 'astroloji' => (emoji: '✨', title: 'Astroloji'),
    'palmistry' || 'el' => (emoji: '🖐️', title: 'El Falı'),
    'numerology' => (emoji: '🔢', title: 'Numeroloji'),
    'katina' => (emoji: '🎴', title: 'Katina'),
    'iskambil' => (emoji: '🂡', title: 'İskambil'),
    'tek-soru' || 'general' => (emoji: '🔮', title: 'Fal'),
    _ => (emoji: '🔮', title: _humanize(key)),
  };
}

/// İzleyici CTA — örn. «☕ Kahve Falı İste».
String liveFortuneRequestCtaLabel(String fortuneTypeOrSlug) {
  final p = liveFortuneTypePresentation(fortuneTypeOrSlug);
  return '${p.emoji} ${p.title} İste';
}

/// Kısa etiket — üst bar / rozet.
String liveFortuneTypeBadge(String fortuneTypeOrSlug) {
  final p = liveFortuneTypePresentation(fortuneTypeOrSlug);
  return '${p.emoji} ${p.title}';
}

String _legacyKeyToSlug(String key) {
  return switch (key) {
    'coffee' => 'kahve-fali',
    'tarot' => 'tarot',
    'astrology' => 'yildiz-haritasi',
    'palmistry' => 'el-fali',
    'numerology' => 'numeroloji',
    'katina' => 'katina-fali',
    'iskambil' => 'iskambil-fali',
    _ => key.contains('-') ? key : '',
  };
}

String _humanize(String key) {
  final cleaned = key.replaceAll('-', ' ').replaceAll('_', ' ');
  if (cleaned.isEmpty) return 'Fal';
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}
