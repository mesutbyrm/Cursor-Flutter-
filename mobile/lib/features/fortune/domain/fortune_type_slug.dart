/// İngilizce / kısa fal tipi → üretim slug eşlemesi.
abstract final class FortuneTypeSlug {
  static const fortuneTypeSlugs = <String, String>{
    'coffee': 'kahve-fali',
    'tarot': 'tarot-fali',
    'dream': 'ruya-yorumu',
    'horoscope': 'burc-yorumu',
    'love': 'ask-uyumu',
    'palm': 'el-fali',
    'angel': 'melek-kartlari',
    'numerology': 'numeroloji',
    'aura': 'aura-analizi',
    'yesno': 'evet-hayir',
    'birthchart': 'dogum-haritasi',
    'istihare': 'istihare',
    'katina': 'katina',
    'kursundokme': 'kursundokme',
  };

  static String resolve(String type) {
    final key = type.trim().toLowerCase();
    return fortuneTypeSlugs[key] ?? key;
  }
}
