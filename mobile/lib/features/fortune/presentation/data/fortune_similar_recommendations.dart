/// Fal türüne göre benzer fal önerileri.
abstract final class FortuneSimilarRecommendations {
  static const _map = <String, List<String>>{
    'tarot': ['katina', 'ask-fali', 'melek-kartlari'],
    'kahve-fali': ['tarot', 'yildiz-haritasi', 'numeroloji'],
    'el-fali': ['numeroloji', 'yildiz-haritasi', 'aura'],
    'yildiz-haritasi': ['numeroloji', 'tarot', 'ask-fali'],
    'numeroloji': ['yildiz-haritasi', 'el-fali', 'tarot'],
    'ask-fali': ['katina', 'melek-kartlari', 'tarot'],
    'katina': ['ask-fali', 'tarot', 'melek-kartlari'],
    'melek-kartlari': ['tarot', 'katina', 'istihare'],
    'ruya-tabiri': ['tarot', 'istihare', 'numeroloji'],
    'evet-hayir': ['tarot', 'pendul', 'istihare'],
    'pendul': ['istihare', 'evet-hayir', 'ruya-tabiri'],
    'runik': ['aura', 'numeroloji', 'tarot'],
    'cin-fali': ['kahve-fali', 'tarot', 'numeroloji'],
    'iskambil': ['tarot', 'katina', 'evet-hayir'],
    'gunluk-fal': ['tarot', 'kahve-fali', 'yildiz-haritasi'],
  };

  static List<String> slugsFor(String slug) {
    final key = slug.trim().toLowerCase();
    return _map[key] ?? const ['tarot', 'kahve-fali', 'yildiz-haritasi'];
  }

  /// Hub vitrininde gösterilecek diğer fallar.
  static const browseSlugs = [
    'tarot',
    'kahve-fali',
    'el-fali',
    'yildiz-haritasi',
    'numeroloji',
    'ask-fali',
    'katina',
    'melek-kartlari',
    'ruya-tabiri',
    'evet-hayir',
  ];
}
