/// Ana sayfa bölümleri — Unsplash görselleri (burç, keşfet, gold, trend yedek).
abstract final class SectionVisualCatalog {
  static const _base = 'https://images.unsplash.com';

  static String _url(String photoId, {int width = 480, String crop = 'entropy'}) =>
      '$_base/photo-$photoId?auto=format&fit=crop&w=$width&q=90&fm=webp&crop=$crop';

  /// Günlük burç — her burç için ayırt edici gökyüzü / element teması.
  static String horoscopeFor(String signName, {int width = 220}) {
    final key = signName.trim().toLowerCase();
    final id = _horoscopePhotos[key] ?? _horoscopePhotos['koç']!;
    return _url(id, width: width, crop: 'center');
  }

  static const _horoscopePhotos = <String, String>{
    'koç': '1518131353823-3909e8946c78', // ateş / kırmızı takımyıldızı
    'boğa': '1500382017468-903a271edb2f', // toprak / yeşil tarla
    'ikizler': '1419242902214-272b3f66ee7a', // çift yıldız / galaksi
    'yengeç': '1446776658536-cca283a060ae', // ay / su
    'aslan': '1502134249126-0f8591a7bad8', // güneş / altın
    'başak': '1475274049437-1ab392f1e2cd', // hasat / toprak
    'terazi': '1534796998700-91747707550b', // denge / mor kozmos
    'akrep': '1614732414444-7e4cd0c5d1b4', // derin karanlık / akrep gece
    'yay': '1464800860016-b2f083179a1f', // ok / ufuk çizgisi
    'oğlak': '1506317587-de9d8e6c4f3c', // dağ / oğlak zirvesi
    'kova': '1462335937197-5ed9bc70de55', // hava / mavi nebula
    'balık': '1506905925346-21bda4d32df4', // su / okyanus derinliği
  };

  /// Keşfet grid — her kutu temasına uygun görsel.
  static String discoverTile(String id, {int width = 360}) {
    final photo = switch (id) {
      'trends' => '1611162616475-24bffc06a659', // neon trend / sosyal
      'invite' => '1529156069898-49953e39b3ac', // arkadaş daveti
      'gifts' => '1549465220-1a8f923d54fa', // hediye kutusu
      _ => '1534528741775-53994a69daeb',
    };
    return _url(photo, width: width, crop: 'center');
  }

  /// Gold üyelik — paket adına uygun metal / lüks görsel.
  static String goldTier(String planId, {int width = 440}) {
    final key = planId.toLowerCase();
    final id = switch (key) {
      'basic' => '1519682337128-7fa9a06a3995', // bronz sıcak ton
      'gold' => '1610374471067-ba344bb6bc42', // altın parıltı
      'diamond' => '1518709268805-4e9042af2176', // elmas kristal
      'premium' => '1557683316-973673baf926', // mor lüks gece
      _ => '1528454864517-dd3fba88b7fa',
    };
    return _url(id, width: width, crop: 'center');
  }

  /// Trend video küçük resmi yoksa döngüsel yedek.
  static String trendFallback(int index, {int width = 360}) {
    const ids = [
      '1611162616475-24bffc06a659',
      '1524504388940-b1c1722653e1',
      '1493225457124-a3eb161ffa5f',
      '1508700929628-666bc8b84a9a',
      '1470225620782-d7838b44f5de',
      '1514525253161-7a46d19cd819',
    ];
    return _url(ids[index % ids.length], width: width);
  }
}
