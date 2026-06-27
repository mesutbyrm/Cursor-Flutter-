/// Soğuk açılış performans sabitleri — Görev 1+ ile uyumlu.
abstract final class StartupPerf {
  /// Splash / auth bootstrap üst sınırı.
  static const bootstrapCap = Duration(seconds: 1);

  /// Auth oturum kontrolü zaman aşımı.
  static const authBootTimeout = Duration(seconds: 1);

  /// runApp sonrası ağır SDK init gecikmesi (AdMob, analytics).
  static const deferredSdkDelay = Duration(milliseconds: 800);

  /// Kabuk prefetch — bildirim, cüzdan, mesajlar.
  static const shellPrefetchDelay = Duration(seconds: 2);

  /// SSE presence + psikolog/ajans yenileme.
  static const shellRealtimeDelay = Duration(seconds: 3);

  /// Ana sayfa üst bar rozetleri (bildirim, mesaj, jeton).
  static const homeHeaderBadgesDelay = Duration(milliseconds: 1200);

  /// Banner carousel API.
  static const homeBannerDelay = Duration(milliseconds: 400);

  /// Canlı yayın bölümü ilk istek.
  static const homeLiveSectionDelay = Duration(milliseconds: 500);

  /// Ana sayfa periyodik poll köprüsü.
  static const homeRealtimeBridgeDelay = Duration(seconds: 4);
}
