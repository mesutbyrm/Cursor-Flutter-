/// Ana sayfa bölümleri — yerel mistik kapaklar + isteğe bağlı Unsplash katmanı.
abstract final class SectionVisualCatalog {
  static const _base = 'https://images.unsplash.com';

  static String _url(String photoId, {int width = 480, String crop = 'entropy'}) =>
      '$_base/photo-$photoId?auto=format&fit=crop&w=$width&q=90&fm=webp&crop=$crop';

  static String horoscopeFor(String signName, {int width = 220}) {
    final key = signName.trim().toLowerCase();
    final id = _horoscopePhotos[key] ?? _horoscopePhotos['koç']!;
    return _url(id, width: width, crop: 'center');
  }

  static const _horoscopePhotos = <String, String>{
    'koç': '1518131353823-3909e8946c78',
    'boğa': '1500382017468-903a271edb2f',
    'ikizler': '1419242902214-272b3f66ee7a',
    'yengeç': '1446776658536-cca283a060ae',
    'aslan': '1502134249126-0f8591a7bad8',
    'başak': '1475274049437-1ab392f1e2cd',
    'terazi': '1534796998700-91747707550b',
    'akrep': '1614732414444-7e4cd0c5d1b4',
    'yay': '1464800860016-b2f083179a1f',
    'oğlak': '1506317587-de9d8e6c4f3c',
    'kova': '1462335937197-5ed9bc70de55',
    'balık': '1506905925346-21bda4d32df4',
  };

  /// Keşfet kartı — yerel mistik kapak slug'ı.
  static String discoverSlug(String id) => switch (id) {
        'trends' => 'tarot',
        'invite' => 'ask-fali',
        'gifts' => 'melek-kartlari',
        _ => 'tarot',
      };

  /// Gold tier — yerel mistik kapak slug'ı.
  static String goldSlug(String planId) {
    return switch (planId.toLowerCase()) {
      'basic' => 'evet-hayir',
      'premium' => 'yildiz-haritasi',
      'gold' => 'katina',
      'diamond' => 'cin-fali',
      _ => 'tarot',
    };
  }

  /// Trend video yedek — slug döngüsü.
  static String trendFallbackSlug(int index) {
    const slugs = [
      'tarot',
      'cin-fali',
      'melek-kartlari',
      'yildiz-haritasi',
      'katina',
      'numeroloji',
    ];
    return slugs[index % slugs.length];
  }

  /// Keşfet — neon fantezi temalar (ağ katmanı, isteğe bağlı).
  static String discoverTile(String id, {int width = 480}) {
    final photo = switch (id) {
      'trends' => '1635070041078-e363dbe005cb', // neon cyber city
      'invite' => '1534447677768-be436bb09401', // cosmic friends
      'gifts' => '1579546929518-9fa396ef48de', // magic gift sparkle
      _ => '1518709268805-4e9042af2176',
    };
    return _url(photo, width: width, crop: 'center');
  }

  /// Gold üyelik — metal / kristal fantezi.
  static String goldTier(String planId, {int width = 480}) {
    final key = planId.toLowerCase();
    final id = switch (key) {
      'basic' => '1519682337128-7fa9a06a3995', // bronze glow
      'gold' => '1610374471067-ba344bb6bc42', // gold particles
      'diamond' => '1518709268805-4e9042af2176', // crystal purple
      'premium' => '1557683316-973673baf926', // sapphire nebula
      _ => '1528454864517-dd3fba88b7fa',
    };
    return _url(id, width: width, crop: 'center');
  }

  /// Fal & Tarot — mistik fantezi kapaklar.
  static String fortuneCard(String slug, {int width = 400}) {
    final key = slug.trim().toLowerCase();
    final id = switch (key) {
      'tarot' => '1615739412122-529d88f59347',
      'kahve-fali' => '1511927619508-f553815789c7',
      'katina' => '1578662996442-48f60103fc96',
      'el-fali' => '1600880292203-757bb62b4baf',
      'yildiz-haritasi' => '1462335937197-5ed9bc70de55',
      'ask-fali' => '1522673609750-1b0e6a71928a',
      'melek-kartlari' => '1502134249126-0f8591a7bad8',
      _ => '1615739412122-529d88f59347',
    };
    return _url(id, width: width, crop: 'center');
  }

  /// Trend video küçük resmi yoksa döngüsel yedek.
  static String trendFallback(int index, {int width = 360}) {
    const ids = [
      '1635070041078-e363dbe005cb',
      '1518709268805-4e9042af2176',
      '1579546929518-9fa396ef48de',
      '1462335937197-5ed9bc70de55',
      '1615739412122-529d88f59347',
      '1557683316-973673baf926',
    ];
    return _url(ids[index % ids.length], width: width);
  }
}
