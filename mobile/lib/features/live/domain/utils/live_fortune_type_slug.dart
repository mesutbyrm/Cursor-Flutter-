/// Canlı fal yayını — görünen kategori → API fal türü anahtarı.
String liveFortuneCategoryToSlug(String category) {
  final c = category.toLowerCase().trim();
  if (c.contains('kahve')) return 'coffee';
  if (c.contains('tarot')) return 'tarot';
  if (c.contains('burç') || c.contains('yıldız') || c.contains('astro')) {
    return 'astrology';
  }
  if (c.contains('el')) return 'palmistry';
  if (c.contains('rüya')) return 'general';
  if (c.contains('aşk')) return 'general';
  if (c.contains('katina')) return 'general';
  if (c.contains('numero')) return 'numerology';
  return 'general';
}

bool isLiveFortuneTypeKey(String value) {
  const keys = {
    'coffee',
    'tarot',
    'astrology',
    'palmistry',
    'numerology',
    'general',
  };
  return keys.contains(value.toLowerCase().trim());
}
