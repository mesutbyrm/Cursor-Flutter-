/// Fal türleri için gerçeğe yakın vitrin görselleri (Unsplash CDN).
abstract final class FortuneTypeImages {
  static const _base = 'https://images.unsplash.com';

  static String urlFor(String slug, {int width = 800}) {
    final id = _photoIds[slug] ?? _photoIds['tarot']!;
    return '$_base/photo-$id?auto=format&fit=crop&w=$width&q=85';
  }

  static const _photoIds = <String, String>{
    'tarot': '1509248961158-e54f6934749c',
    'ask-fali': '1518199266791-5375a83190b7',
    'kahve-fali': '1511920170033-f8396924c10b',
    'yildiz-haritasi': '1419242902214-272b3f66ee7a',
    'el-fali': '1600880292203-757bb62b4baf',
    'katina': '1596838132731-3301c3fd4317',
    'iskambil': '1571197119275-571a2ce9fccf',
    'melek-kartlari': '1518709268805-4e9042af2175',
    'numeroloji': '1635070041078-e363dbe005cb',
    'ruya-tabiri': '1495616811223-4d98c6e9c869',
    'cin-fali': '1528360983097-13cdb7de7656',
    'pendul': '1618172193622-ae2d025f4032',
    'runik': '1506905925346-21bda4d32df4',
    'evet-hayir': '1454165804606-c3d57bc86b40',
    'gunluk-fal': '1518546305927-5a555bb7020d',
  };
}
