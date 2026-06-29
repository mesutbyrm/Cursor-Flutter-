/// Soğuk açılış performans sabitleri — Görev 1+ ile uyumlu.
abstract final class StartupPerf {
  /// Splash / auth bootstrap üst sınırı.
  static const bootstrapCap = Duration(seconds: 1);

  /// Auth oturum kontrolü — ağ yavaş olsa bile token varsa cache kullanılır.
  static const authBootTimeout = Duration(seconds: 12);

  /// runApp sonrası ağır SDK init gecikmesi (AdMob, analytics).
  static const deferredSdkDelay = Duration(milliseconds: 800);

  /// Kabuk prefetch — bildirim, cüzdan, mesajlar (jeton gecikmesiz).
  static const shellPrefetchDelay = Duration.zero;

  /// SSE presence + psikolog/ajans yenileme.
  static const shellRealtimeDelay = Duration(seconds: 3);

  /// Ana sayfa üst bar rozetleri — anında (API shell prefetch ile).
  static const homeHeaderBadgesDelay = Duration.zero;

  /// Banner carousel API.
  static const homeBannerDelay = Duration.zero;

  /// Canlı yayın bölümü ilk istek.
  static const homeLiveSectionDelay = Duration.zero;

  /// Ana sayfa periyodik poll köprüsü.
  static const homeRealtimeBridgeDelay = Duration(seconds: 4);
}

/// Ekran içi lazy load gecikmeleri — Görev 2.
abstract final class LazyLoadPerf {
  static const step = Duration(milliseconds: 80);

  // Profil — Jeton/CFC/takipçi/gönderiler anında başlar (Görev 15)
  static const profileStats = Duration.zero;
  static const profileWallet = Duration.zero;
  static const profilePremium = Duration(milliseconds: 240);
  static const profilePublisher = Duration(milliseconds: 320);
  static const profileTeller = Duration(milliseconds: 400);
  static const profileAdmin = Duration(milliseconds: 480);
  static const profileContent = Duration.zero;
  static const profileSettings = Duration(milliseconds: 640);

  // Canlı yayın listesi
  static const liveList = Duration(milliseconds: 120);
  static const liveCategories = Duration(milliseconds: 200);

  // Canlı oda — RTC sonrası ek yükler
  static const liveRoomGifts = Duration(milliseconds: 400);
  static const liveRoomExtras = Duration(milliseconds: 700);

  // Sesli oda listesi
  static const voiceRoomList = Duration.zero;
  static const voiceRoomPresence = Duration(milliseconds: 450);
  static const voiceRoomLiveStreams = Duration(milliseconds: 900);

  // Fal hub
  static const fortuneHero = Duration.zero;
  static const fortuneProphecy = Duration(milliseconds: 120);
  static const fortuneTypes = Duration(milliseconds: 240);
  static const fortuneDaily = Duration(milliseconds: 360);
  static const fortuneBadges = Duration(milliseconds: 1000);

  // Mesajlar / bildirimler
  static const messagesList = Duration(milliseconds: 100);
  static const chatMessages = Duration(milliseconds: 80);
  static const notificationsList = Duration(milliseconds: 100);
}
