/// Performans serisi (Görev 1–18) — canlifal.com backend değişmeden mobil optimizasyon.
///
/// Tüm API çağrıları `https://canlifal.com` üzerinden; yeni backend yok.
abstract final class PerfResult {
  static const backend = 'https://canlifal.com';

  /// Görev 1 — açılış: splash ≤1s, SDK defer, auth timeout 1s
  static const moduleStartup = 'StartupPerf / app_deferred_bootstrap';

  /// Görev 2 — lazy ekran bölümleri
  static const moduleLazyLoad = 'LazyLoadPerf / LazyScreenSection';

  /// Görev 3 — HTTP cache memory+disk+TTL
  static const moduleApiCache = 'ApiHttpCache / ApiCachePolicy';

  /// Görev 4 — görsel cache + thumbnail
  static const moduleImages = 'CanlifalNetworkImage / ImageCache';

  /// Görev 5 — lazy ListView/GridView
  static const moduleLists = 'LazyListView / ListPerf';

  /// Görev 6 — hedefli Riverpod rebuild
  static const moduleState = 'StatePerf / SelectiveConsumer';

  /// Görev 7 — animasyon UI thread dışı
  static const moduleAnimation = 'AnimationPerf';

  /// Görev 8 — paralel API Future.wait
  static const moduleNetwork = 'NetworkPerf';

  /// Görev 9 — büyük JSON parse isolate (≥50 KB; Dio + disk cache)
  static const moduleJsonIsolate = 'JsonIsolatePerf / FusedTransformer';

  /// Görev 10 — blur/glass önbellek
  static const moduleEffects = 'EffectsPerf';

  /// Görev 11 — scroll cache + repaint izolasyon
  static const moduleScroll = 'ScrollPerf';

  /// Görev 12 — merkezi SSE hub
  static const moduleSse = 'SseConnectionHub';

  /// Görev 13 — sesli oda hızlı giriş
  static const moduleVoiceEntry = 'VoiceRoomEntryPerf';

  /// Görev 14 — canlı yayın ilk kare + arka plan bağlantı
  static const moduleLiveEntry = 'LiveEntryPerf';

  /// Görev 15 — profil dilimleri bağımsız yükleme
  static const moduleProfileLoad = 'ProfileLoadPerf';

  /// Görev 16 — mesajlar cache-first + arka plan güncelleme
  static const moduleMessagesLoad = 'MessagesLoadPerf / CacheFirstLoader';

  /// Sesli oda Premium 2026 UI — mevcut API/SSE, yalnızca Flutter arayüz
  static const moduleVoiceUi2026 = 'VoiceDiscoverHub2026 / VoiceLiveHeader2026';
  /// Sesli sohbet API dokümanı — voice/typing/25s heartbeat/gifts LB
  static const moduleVoiceApiDoc = 'ChatRoomRemoteDataSource voice+typing §6';

  /// Görev 17 — gereksiz rebuild/setState/timer sızıntı temizliği
  static const moduleWidgetPerf = 'WidgetPerf / CancellableDelay';

  /// Görev 19 — HTTP retry, timing, connectivity, request scope
  static const moduleNetworkV2 =
      'ApiRetryInterceptor / ConnectivityService / AppPerfMetrics';

  /// Görev 18 — jeton/cüzdan anında, geçişler akıcı
  static const moduleWalletUi = 'WalletBalancesNotifier + shell prefetch';
}
