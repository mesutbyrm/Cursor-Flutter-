# Canlifal Flutter — Performans Denetimi (FAZ 1)

**Tarih:** 2026-08-22  
**Sürüm:** `1.0.336+372` (`mobile/pubspec.yaml`)  
**Commit referansı:** `main` @ audit anı  
**Kapsam:** `mobile/` Flutter istemcisi — **yalnızca analiz; kod değişikliği yok**  
**Backend:** `https://canlifal.com` — mevcut API sözleşmesi korunacak (endpoint uydurma yok)

---

## 1. Özet

Canlifal mobil istemcisi zaten önemli performans altyapısına sahip (HTTP cache + dedupe, SSE hub, deferred bootstrap, shorts video pool, image cache limitleri, isolate JSON decode). Ancak **sosyal feed video**, **çoklu SSE keşif bağlantıları**, **her istekte secure storage okuma**, **geniş `ref.watch` yüzeyi** ve **nested scroll (`shrinkWrap`)** kombinasyonu düşük/orta segment Android cihazlarda hedeflenen Instagram/TikTok seviyesinin altında kalma riski taşıyor.

Bu belge, optimizasyon öncesi tam envanter + anti-pattern taraması + **önem sırasına göre 20 darboğaz** listesidir. Ölçülebilir baseline için bkz. [`PERFORMANCE_BASELINE.md`](PERFORMANCE_BASELINE.md).

---

## 2. Teknoloji envanteri

| Alan | Değer | Kaynak |
|------|--------|--------|
| Flutter (proje pin) | **3.44.8** | `mobile/.flutter-version` |
| Flutter (audit ortamı) | **3.47.1** | `flutter --version` (cloud agent) |
| Dart | **>=3.8.0 <4.0.0** (ortam: 3.13.1) | `pubspec.yaml` |
| State management | **Riverpod 2.6.1** + **flutter_bloc 9.1.1** | `pubspec.yaml` |
| HTTP | **Dio 5.8** — 12 interceptor, keep-alive, gzip | `core/network/dio_provider.dart` |
| HTTP cache | Bellek + disk TTL, inflight dedupe, 256 entry | `api_cache_interceptor.dart`, `api_http_cache.dart` |
| JSON parse | >50 KB → isolate (`FusedTransformer` + `JsonIsolatePerf`) | `json_isolate_perf.dart`, `dio_provider.dart` |
| Realtime (birincil) | **SSE** — `BaseSseService`, `SseConnectionHub` | `core/network/sse/*`, `chat_room_sse_service.dart` |
| Realtime (legacy) | `sse_client.dart` (hâlâ import ediliyor) | `core/sse_client.dart` |
| WebSocket / Socket.IO | **Var** — canlı namespace, bazı oyun/yardımcı akışlar | `socket_io_client`, `live_namespace_socket_service.dart` |
| RTC | **Tencent TRTC** (`tencent_rtc_sdk` path override) | `features/trtc/*`, `voice_trtc_engine.dart` |
| Navigation | **go_router 15.1.2**, `StatefulShellRoute` — **yalnızca aktif tab mount** | `app/router/app_router.dart` |
| Image | `CachedNetworkImage` + `CanlifalNetworkImage` (thumbnail varsayılan) | `core/images/*` |
| Image bellek limiti | 200 entry / **100 MB** | `canlifal_image_cache.dart` |
| Image disk limiti | 600 dosya / 30 gün | `canlifal_image_cache_manager.dart` |
| Video | `video_player` + shorts pool (max **5** controller) | `shorts_video_controller_pool.dart` |
| Local storage | `flutter_secure_storage`, `shared_preferences`, **Hive** | çeşitli feature modülleri |
| Isolate kullanımı | JSON decode (>50 KB); geniş feed mapping yok | `json_isolate_perf.dart` |
| Startup | Deferred Firebase/OneSignal/AdMob; shell prefetch kademeli | `main.dart`, `app_deferred_bootstrap.dart`, `shell_prefetch.dart` |
| Ölçüm altyapısı | `AppPerfMetrics`, `StartupPerf`, 11 perf unit test | `core/performance/*`, `test/*_perf_test.dart` |
| Dart dosya sayısı | **1595** | `find mobile/lib -name '*.dart'` |
| `pubspec` bağımlılık satırı | **~75** | `pubspec.yaml` |
| APK (release, CI) | **252 276 640 bayt (~240,6 MiB)** | GitHub `apk-latest` release asset |

---

## 3. Mimari hot path haritası

### 3.1 Cold start

```
main() → WidgetsFlutterBinding → DevicePerfTuning → runApp(ProviderScope)
       → LazyCookieJar.prewarm (async)
       → scheduleDeferredAppBootstrap (T+1 frame, T+400ms SDK)
       → CanlifalApp → auth gate → ilk route
```

**Kritik:** `GoogleFonts` runtime fetch kapalı; ağır SDK'lar `runApp` sonrası.  
**Risk:** Auth bootstrap + mobile config + shell prefetch (T+200ms…3500ms) aynı pencerede çok sayıda paralel GET üretebilir.

### 3.2 Ağ katmanı

- Merkezi `dioProvider` — her private istekte `tokenStorage.readAccess()` (async secure storage I/O).
- `ApiCacheInterceptor`: GET cache, TTL `ApiCachePolicy`, inflight dedupe.
- 12 interceptor zinciri: version, backend routing, cookie, payment, voice log, monitor, timing, JSON guard, retry, cache, gateway fallback, auth refresh.

### 3.3 Realtime

- `SseConnectionHub`: oda başına tek `ChatRoomSseService`, ref-count ile release.
- Keşif presence: `VoiceRoomsPresenceNotifier` — **max 12** eşzamanlı oda SSE (home: 6).
- `ChatRoomSseService.connect()`: `isLiveForRoom()` true ise **erken çıkış** — callback'ler güncellenir ama yeniden bağlanmaz (darboğaz #1).

### 3.4 Sesli oda / TRTC

- `VoiceTrtcEngine` → kendi `TrtcRoomManager()` instance'ı.
- Canlı yayın / psikolog akışları → ayrı `TrtcRoomManager` kullanımları.
- Static `_activeSession` — çift oda riski için koruma var; yine de çoklu manager instance (#5).

### 3.5 Feed / video

- **Shorts:** `ShortsVideoControllerPool` — max 5, warm offset [0,1,-1,2,-2].
- **Social feed:** `SocialPostVideoPlayer` — **her kart kendi `VideoPlayerController`**, görünürlük kapısı yok, otomatik `play()` (#2).

---

## 4. Statik anti-pattern taraması

| Anti-pattern | Sayım | Not |
|--------------|------:|-----|
| `ref.watch(` (toplam) | **963** | 200+ dosya; granüler `select` sınırlı (~40 dosya) |
| `shrinkWrap: true` | **51** | 43 dosya; nested scroll maliyeti |
| `ListView(` (non-builder dosya) | **76** | Tüm liste eager build riski |
| `ListView.builder` (dosya) | **37** | Lazy liste — iyi örnekler mevcut |
| `setState(` | **200+** | Yoğun UI state; voice/live sayfalarında yüksek |
| `AnimationController(` | **83** | 60 dosya; dispose pattern genelde var |
| `Timer(` | **65** | 48 dosya; voice room poll + ticker |
| `BackdropFilter` | **53** | 46 dosya; GPU maliyeti |
| `VideoPlayerController` referansı | **54** | 21 dosya |
| `FutureBuilder` | **6** | Düşük; build içi API yok |
| `fromJson` / JSON parse in `build()` | **0** | İyi |
| `compute(` / isolate | **2** | Yalnızca `json_isolate_perf.dart` |
| `cacheWidth` / `cacheHeight` (widget param) | **0** | `CanlifalNetworkImage` kendi `memCacheWidth` hesaplıyor |
| `CachedNetworkImage` doğrudan | **8** | Çoğu `CanlifalNetworkImage` üzerinden |
| `readAccess(` çağrısı | **12** | Dio interceptor her istekte tetiklenir |
| `/api/me` referansı | **14+** | Çoklu feature path |
| `MobileCompoundRemoteDataSource` instance | **3** | home / profile / fortune — duplicate `/api/mobile/home` riski |
| Socket.IO kullanan dosya | **2** (+ live namespace) | SSE ile paralel realtime |
| SSE servis dosyası | **12** | Hub ile tekilleştirme kısmen var |

### 4.1 Doğrulanan riskli kod noktaları

**SSE connect erken çıkış (callback güncellenmez bağlantıda):**

```106:117:mobile/lib/features/voice_hub/data/services/chat_room_sse_service.dart
    if (isLiveForRoom(id)) {
      VoiceRoomDebugLog.log('sse.connect.skip', {
        'roomId': id,
        'reason': 'already_connected',
      });
      return;
    }
```

Keşif presence önce bağlanırsa, oda sayfası tam callback set'i ile `connect()` çağırdığında sessizce atlanabilir.

**Sosyal feed — sınırsız video player:**

```46:66:mobile/lib/features/social/presentation/widgets/instagram/social_post_video_player.dart
  Future<void> _init() async {
    ...
      await c.setVolume(0);
      await c.play();
```

Görünürlük / pool / tek-aktif-video kuralı yok.

**Her HTTP isteğinde token okuma:**

```88:104:mobile/lib/core/network/dio_provider.dart
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        ...
          final token = await tokenStorage.readAccess();
```

**Tab state preservation bilinçli kapalı:**

```298:302:mobile/lib/app/router/app_router.dart
      // indexedStack tüm sekmeleri önceden yükler; Android BackdropFilter gri ekran yapar.
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) {
          return children[navigationShell.currentIndex];
```

Sekme değişiminde widget ağacı dispose → tekrar API/controller init.

---

## 5. Mevcut güçlü yönler (korunmalı)

1. **Deferred bootstrap** — Firebase, OneSignal, AdMob, crash reporting `runApp` sonrası (`app_deferred_bootstrap.dart`).
2. **HTTP cache + inflight dedupe** — duplicate GET azaltma (`api_cache_interceptor.dart`).
3. **Isolate JSON** — >50 KB yanıtlar UI thread dışında (`json_isolate_perf.dart`).
4. **SSE hub ref-count** — aynı oda için tek servis instance (`sse_connection_hub.dart`).
5. **Shorts video pool** — bellek sınırlı preload (`shorts_video_controller_pool.dart`).
6. **Image cache limitleri** — 100 MB / 200 entry + disk 600 dosya.
7. **StartupPerf / LazyLoadPerf** — kademeli home section ve shell prefetch sabitleri.
8. **Perf test altyapısı** — scroll, state select, network parallel, animation unit testleri.
9. **Voice room entry TRTC credential cache** — `VoiceRoomEntryPerf` (test ile doğrulanmış).
10. **RepaintBoundary** — 70+ kullanım; feed/shorts/voice'ta mevcut.

---

## 6. En büyük 20 darboğaz (önem sırasına göre)

| # | Öncelik | Darboğaz | Etki | Kanıt / dosya | Önerilen faz |
|---|---------|----------|------|---------------|--------------|
| 1 | **P0** | SSE `connect()` erken çıkış — keşif bağlantısı varken oda callback'leri kayıp | Hediye/chat/presence kaçırma, gereksiz reconnect | `chat_room_sse_service.dart:106`, `voice_rooms_presence_provider.dart` | FAZ 6 |
| 2 | **P0** | Sosyal feed'de kart başına bağımsız `VideoPlayerController` + auto-play | RAM, CPU, jank, battery | `social_post_video_player.dart` | FAZ 5 |
| 3 | **P0** | Her Dio isteğinde `readAccess()` (secure storage I/O) | Startup + scroll sırasında latency spike | `dio_provider.dart:93` | FAZ 3 |
| 4 | **P1** | Keşif/home'da **6–12 eşzamanlı** oda SSE | Ağ, battery, ANR riski | `voice_rooms_presence_provider.dart:40-43` | FAZ 6 |
| 5 | **P1** | Birden fazla `TrtcRoomManager` instance / paralel init yolları | Duplicate SDK yükü, bellek | `voice_trtc_engine.dart`, `trtc_room_manager.dart`, live/psychic | FAZ 6 |
| 6 | **P1** | **51×** `shrinkWrap: true` nested scroll | Layout O(n), jank | profile tabs, voice sheets, shorts | FAZ 7/9 |
| 7 | **P1** | **3×** `MobileCompoundRemoteDataSource` → `/api/mobile/home` duplicate | Gereksiz payload, startup rekabeti | `home_remote_datasource.dart`, `profile_remote_datasource.dart`, `fortune_menu_providers.dart` | FAZ 3/4 |
| 8 | **P1** | `/api/me` ve wallet cascade — 15+ çağrı yolu | Duplicate profil verisi | `auth_service.dart`, `profile_*`, `home_*` | FAZ 3/4 |
| 9 | **P1** | Profil: nested ListView/GridView + shrinkWrap | Scroll jank, overdraw | `profile_content_tabs.dart`, `user_posts_timeline.dart` | FAZ 7 |
| 10 | **P2** | `voice_room_rtc_page.dart` — **20×** `ref.watch` | Her küçük state'te geniş rebuild | `voice_room_rtc_page.dart` | FAZ 7 |
| 11 | **P2** | Hediye flaşı / koltuk widget'ları — receiver dışı rebuild | FPS düşüşü (10 ardışık hediye) | `voice_seat_gift_flash_stack.dart`, `voice_mic_seat.dart` | FAZ 7 |
| 12 | **P2** | 12 interceptor × her istek | Sabit overhead (~1–3 ms/istek tahmini) | `dio_provider.dart` | FAZ 3 |
| 13 | **P2** | Shell prefetch + auth + home sections aynı 0–3,5 sn penceresi | İlk anlamlı UI gecikmesi | `shell_prefetch.dart`, `startup_perf.dart` | FAZ 3 |
| 14 | **P2** | Tab geçişinde state yok — her seferinde cold init | Tekrar API, video dispose | `app_router.dart:298-302` | FAZ 3/7 |
| 15 | **P2** | Voice room JSON mapping — büyük yanıtlar main isolate | UI thread blok (oda sync) | `chat_room_remote_datasource.dart` (~2950 satır), `chat_room_providers.dart` (~3650 satır) | FAZ 3/8 |
| 16 | **P2** | **76** dosyada non-builder `ListView` | Büyük listelerde bellek/FPS | admin, voice sheets, live pages | FAZ 7 |
| 17 | **P2** | SSE varken REST poll (60–120 sn) — DJ/queue | Gereksiz battery/network | `chat_room_providers.dart` `_schedulePoll` | FAZ 6 |
| 18 | **P3** | Ağır bağımlılık yığını (3 audio stack, ffmpeg, Firebase suite, socket_io+SSE) | APK **~241 MB**, startup native init | `pubspec.yaml` | FAZ 10 |
| 19 | **P3** | **53×** `BackdropFilter` / glassmorphism | GPU overdraw | `premium_glass_surface.dart`, voice/live UI | FAZ 9 |
| 20 | **P3** | `TrtcRoomManager` ValueNotifier dispose eksikliği | Uzun oturum memory creep | `trtc_room_manager.dart` | FAZ 8 |

---

## 7. Alan bazlı detay

### 7.1 Startup

| Bileşen | Durum | Risk |
|---------|--------|------|
| `runApp` öncesi | Hafif (font, perf mark) | Düşük |
| Auth restore | 12 sn timeout, cache fallback | Orta — ağ beklemesi |
| Mobile config | T+600 ms | Orta |
| Shell prefetch T1–T4 | 200–3500 ms | **Yüksek** — 8+ endpoint |
| Deferred SDK | T+400 ms Firebase/OneSignal/AdMob | Orta |

**Hedef:** cold <2 s, warm <1 s, ilk anlamlı UI <1,5 s — **cihaz ölçümü gerekli** (bkz. baseline).

### 7.2 Network

- Cache TTL örnekleri: default 45 sn; shorts 25 sn; profile kuralları `api_cache_policy.dart`.
- Inflight dedupe: var.
- Pagination: shorts/social/messages kısmen cursor; bazı admin/liste ekranları tam liste.
- **Eksik:** merkezi request dedupe `/api/me` ve compound home için provider seviyesinde.

### 7.3 Cache stratejisi

| Katman | Durum |
|--------|--------|
| Memory HTTP | Var (256 entry) |
| Disk HTTP | Var (TTL + stale max 1 saat) |
| Image memory | 100 MB / 200 |
| Image disk | 600 dosya |
| Feed/profile memory | Riverpod AsyncValue — logout temizliği `AppSessionReset` ile kısmen |
| Video disk | `video_cache_service.dart` |

**Eksik:** kullanıcı bazlı cache partition audit; presence için cache yok (doğru).

### 7.4 Social feed

- Cursor pagination: `social_providers.dart` — mevcut.
- Like rebuild: kısmen ayrılmış; video player (#2) ana risk.
- Preload: shorts'ta var; social feed video'da yok.

### 7.5 Short video

- Pool max 5 (yorum: 3 hedeflenmişti — hâlâ 5).
- Tek aktif video: shorts feed'de kısmen; social'da yok.
- Thumbnail → video: shorts'ta var.

### 7.6 Image

- Merkezi `CanlifalNetworkImage` — thumbnail + `memCacheWidth` hesabı.
- Ham `cacheWidth`/`cacheHeight` widget parametresi yok — merkezi helper yeterli sayılabilir.
- `trimIfNeeded()` oda çıkışında çağrılıyor (iyi).

### 7.7 State management

- Riverpod dominant; bloc sınırlı.
- `ref.watch` 963 — selective rebuild yetersiz.
- `SelectiveConsumer` / `auth_selectors` — iyi örnek, yaygın değil.

### 7.8 Voice / TRTC / SSE

- Tencent RTC korunacak (Agora'ya dönüş yok).
- SSE reconnect: exponential backoff `sse_reconnect_policy.dart`.
- Heartbeat watchdog: 45 sn (`base_sse_service.dart`).
- Background lifecycle: `push_lifecycle_listener.dart`, kısmi SSE pause — tam audit FAZ 6.

### 7.9 Gift animations

- `global_gift_queue.dart`, max visible flash 3, TTL 3 sn — iyi.
- Risk: overlay + BackdropFilter + tüm koltuk rebuild (#11).

### 7.10 Chat / DM

- `chat_messages_list_pane.dart` — lazy list.
- Incremental update: SSE + local merge; tam immutable bubble audit yapılmadı.

### 7.11 Local storage

- Token: secure storage — **her istekte okuma** (#3).
- Hive: feature bazlı; büyük JSON disk yazımı audit edilmeli.

### 7.12 Navigation

- `StatefulShellRoute` — yalnızca aktif tab (bellek tasarrufu, tekrar init maliyeti).
- Deep link / oda girişi: `VoiceRoomEntryPerf` optimizasyonu mevcut.

### 7.13 Memory leak adayları

| Kaynak | Durum |
|--------|--------|
| `AnimationController` | Genelde `dispose` var |
| `ScrollController` | 22 dosya — dispose eşleşmesi yüksek |
| `StreamSubscription` | 24 dosya — SSE/voice dikkat |
| `Timer` | Poll/ticker — `chat_room_providers` cancel var |
| `VideoPlayerController` | Social feed risk (#2) |
| `TrtcRoomManager` notifiers | Dispose eksik (#20) |

### 7.14 APK boyutu

- Release APK: **252 276 640 B (~240,6 MiB)**.
- Büyük paketler: `tencent_rtc_sdk`, `ffmpeg_kit_flutter_new_min_gpl`, Firebase, `google_mobile_ads`, çoklu audio (`audioplayers`, `just_audio`, `audio_service`).
- Assets: **9,4 MiB** (`mobile/assets`).

### 7.15 Backend uyumluluk

Bu audit **backend değişikliği gerektirmiyor**. Optimizasyonlar Flutter tarafında cache/dedupe/lifecycle ile yapılabilir. Backend ihtiyacı çıkarsa ayrı `BACKEND_REQUIRED_CHANGES.md` (FAZ sonrası).

---

## 8. Ölçüm boşlukları

Cloud agent ortamında **gerçek cihaz yok**, emülatör yok. Aşağıdakiler **ölçülemedi**:

- Cold / warm start süresi  
- FPS / jank %  
- 30 dk memory drift  
- Gerçek ağ latency profili  
- Battery / CPU sıcaklık  

Statik analiz + unit test (994 pass) tamamlandı. Cihaz benchmark prosedürü `PERFORMANCE_BASELINE.md` §4'te.

---

## 9. Önerilen optimizasyon fazları (onay sonrası)

| Faz | Odak | Bu audit'teki # |
|-----|------|-----------------|
| FAZ 3 | Startup + network | 3, 7, 8, 12, 13, 14 |
| FAZ 4 | Cache + feed | 7, 8, 14 |
| FAZ 5 | Image + video | 2 |
| FAZ 6 | Voice/TRTC/SSE | 1, 4, 5, 17 |
| FAZ 7 | State/rebuild | 6, 9, 10, 11, 16 |
| FAZ 8 | Memory/leak | 15, 20 |
| FAZ 9 | UI/GPU | 6, 19 |
| FAZ 10 | APK + gerçek cihaz | 18 + baseline tekrar |

**Kural:** Her faz sonrası `flutter analyze`, `flutter test`, acceptance gate. Optimizasyon **kullanıcı onayı olmadan başlamamalı**.

---

## 10. İlgili mevcut belgeler

| Dosya | Not |
|-------|-----|
| `PERFORMANCE_BASELINE.md` | Bu audit ile birlikte oluşturuldu |
| `mobile/docs/PERFORMANCE_REPORT.md` | Eski oturum raporu |
| `docs/PERFORMANCE_OPTIMIZATION_REPORT.md` | Tarihsel |
| `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` | API tek kaynak — optimizasyonda bozulmamalı |

---

*Bu dosya FAZ 1 çıktısıdır. Optimizasyon sonrası `PERFORMANCE_AFTER.md` ve `PERFORMANCE_CHANGELOG.md` ayrı oluşturulacaktır.*
