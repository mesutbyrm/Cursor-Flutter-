/// Premium 2026 görsel yolları — önce `assets/images/premium/`, yoksa legacy.
abstract final class PremiumAssetPaths {
  static const premiumRoot = 'assets/images/premium';
  static const premiumHome = '$premiumRoot/home';
  static const premiumFortune = '$premiumRoot/fortune';
  static const premiumZodiac = '$premiumRoot/zodiac';
  static const premiumMembership = '$premiumRoot/membership';

  static String homeQuickAccess(String legacyTileFile) {
    final premium = _homePremiumByLegacy[legacyTileFile];
    if (premium != null) {
      return '$premiumHome/$premium';
    }
    return 'assets/tiles/$legacyTileFile';
  }

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

  static const _homePremiumByLegacy = <String, String>{
    'home-kesfet.webp': 'discover_icon.webp',
    'home-tanis-kaynas.webp': 'meet_mingle_icon.webp',
    'home-gold-uyelik.webp': 'gold_membership_icon.webp',
    'home-canli-falcilar.webp': 'live_psychics_icon.webp',
    'home-tum-ozellikler.webp': 'all_features_icon.webp',
    'home-falci.webp': 'psychic_panel_icon.webp',
    'home-ajans.webp': 'agency_icon.webp',
    'home-yayinci.webp': 'publisher_icon.webp',
    'home-jeton-al.webp': 'buy_tokens_icon.webp',
    'home-hediye-yolla.webp': 'send_gift_icon.webp',
  };

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
