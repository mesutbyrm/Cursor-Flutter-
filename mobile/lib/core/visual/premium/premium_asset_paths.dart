/// Premium 2026 görsel yolları.
///
/// Eskiden `assets/images/premium/` altında aynı görsellerin birebir
/// kopyaları vardı (~7 MB); uygulama boyutunu küçültmek için kopyalar
/// silindi ve tüm yollar tek kaynağa (`assets/tiles`, `assets/fortune`,
/// `assets/zodiac`, `assets/membership`) yönlendirildi.
abstract final class PremiumAssetPaths {
  static const premiumHome = 'assets/tiles';
  static const premiumFortune = 'assets/fortune';
  static const premiumZodiac = 'assets/zodiac';
  static const premiumMembership = 'assets/membership';

  static String homeQuickAccess(String legacyTileFile) =>
      'assets/tiles/$legacyTileFile';

  static String fortune(String fileName) => '$premiumFortune/$fileName';

  static String? fortuneFromSlug(String slug) {
    final file = _fortuneFileBySlug[slug];
    return file == null ? null : fortune(file);
  }

  static String zodiac(String asciiFile) => '$premiumZodiac/$asciiFile.webp';

  static String membership(String tierId) =>
      '$premiumMembership/${tierId.trim().toLowerCase()}.webp';

  static String legacyFortune(String fileName) => 'assets/fortune/$fileName';

  static String legacyZodiac(String asciiFile) => 'assets/zodiac/$asciiFile.webp';

  static String legacyMembership(String tierId) =>
      'assets/membership/${tierId.trim().toLowerCase()}.webp';

  static const _fortuneFileBySlug = <String, String>{
    'tarot': 'tarot.webp',
    'kahve-fali': 'kahve-fali.webp',
    'ask-fali': 'ask-fali.webp',
    'yildiz-haritasi': 'yildiz-haritasi.webp',
    'el-fali': 'el-fali.webp',
    'katina': 'katina.webp',
    'iskambil': 'iskambil.webp',
    'melek-kartlari': 'melek-kartlari.webp',
    'numeroloji': 'numeroloji.webp',
    'ruya-tabiri': 'ruya-tabiri.webp',
    'cin-fali': 'cin-fali.webp',
    'istihare': 'istihare.webp',
    'aura': 'aura-analizi.webp',
    'aura-analizi': 'aura-analizi.webp',
    'evet-hayir': 'evet-hayir.webp',
    'gunluk-fal': 'gunluk-fal.webp',
    'dogum-haritasi': 'dogum-haritasi.webp',
    'kursun-dokme': 'kursundokme.webp',
    'kursundokme': 'kursundokme.webp',
    'pendul': 'pendul.webp',
    'pendul-fali': 'pendul.webp',
    'runik': 'runik.webp',
    'runik-fali': 'runik.webp',
  };
}
