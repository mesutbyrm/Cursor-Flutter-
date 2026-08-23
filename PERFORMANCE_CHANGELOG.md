# Performans Değişiklik Günlüğü

**Sürüm:** `1.0.343+379`  
**Tarih:** 2026-08-22  
**Fazlar:** FAZ 3 (network/startup), FAZ 5 (social video), FAZ 6 (SSE)

---

## FAZ 3 — Startup + Network

### Token bellek önbelleği (`TokenStorage`)

| Önce | Sonra |
|------|--------|
| Her Dio isteğinde `flutter_secure_storage.read()` | İlk okuma sonrası `peekAccess()` — bellekten |
| 12+ secure read / saniye (yoğun scroll) | 1 read / oturum (refresh/logout hariç) |

**Dosyalar:** `mobile/lib/core/network/token_storage.dart`, `dio_provider.dart`  
**Test:** `mobile/test/token_storage_perf_test.dart`

### MobileCompoundRemoteDataSource tekilleştirme

| Önce | Sonra |
|------|--------|
| 3 ayrı instance (home, profile, fortune) | 1 shared `mobileCompoundRemoteProvider` |
| 3× `/api/mobile/home` bellek önbelleği | 1× paylaşımlı 45 sn TTL cache |

**Dosyalar:** `mobile_compound_remote_datasource.dart`, `home_providers.dart`, `profile_providers.dart`, `user_session_cleanup.dart`

---

## FAZ 5 — Social Video

### Sosyal feed video player

| Önce | Sonra |
|------|--------|
| Her video kartı `initState`'te controller + `play()` | Dokunana kadar poster; 0 aktif player scroll sırasında |
| N eşzamanlı `VideoPlayerController` (feed'de N video post) | Max 1 (kullanıcı oynattığı) |

**Dosya:** `social_post_video_player.dart`

---

## FAZ 6 — SSE

### Oda SSE `connect()` — keşif → oda geçişi

| Önce | Sonra |
|------|--------|
| `isLiveForRoom` → erken çıkış, `onConnected` bir daha çağrılmaz | Bağlı + connected fazında `onConnected` yeniden çağrılır |
| Presence join / seat refresh kaçabilir | Oda sayfası keşif SSE'sini yeniden kullanır |

**Dosya:** `chat_room_sse_service.dart`

---

## Henüz yapılmadı (sonraki fazlar)

- `shrinkWrap` nested scroll refactor
- `voice_room_rtc_page` üst gövde granular select (kısmen footer yapıldı)
- Gerçek cihaz benchmark (`PERFORMANCE_AFTER.md`)

---

## FAZ 6/7 — 1.0.338+374

### Discover presence SSE

| Önce | Sonra |
|------|--------|
| max 12 eşzamanlı oda SSE | **6** |
| home şeridi 6 SSE | **4** |
| stagger 180 ms | **250 ms** |

### Shorts video pool

| Önce | Sonra |
|------|--------|
| max 5 controller | **3** |
| warm offset ±2 | yalnızca ±1 |

### Voice room footer rebuild

| Önce | Sonra |
|------|--------|
| `(messages, events, presence)` tuple → tüm footer rebuild | Mention + toast ayrı `Consumer` slice |

### Voice room REST poll (SSE açık)

| Önce | Sonra |
|------|--------|
| 60/120 sn, her 2. tick | **90/180 sn**, her 3. tick (DJ yokken) |

---

## FAZ 7/8 — 1.0.339+375

### Koltuk hediye flaşı rebuild

| Önce | Sonra |
|------|--------|
| `ref.watch(full flash list)` → tüm koltuklar rebuild | `select(flashSignature)` per receiver |
| Boş koltuk `[]` referansı rebuild | signature `''` stabil |

### Gift event subscription leak

| Önce | Sonra |
|------|--------|
| `ref.watch` + yeni `listen` provider rebuild'de | `ref.read` + `_sub?.cancel()` |

### TRTC memory

| Önce | Sonra |
|------|--------|
| 6× `ValueNotifier` dispose yok | `disposeAsync` içinde dispose (tek sefer) |

---

## FAZ 9 — 1.0.340+376

### Voice sahne koltuk grid rebuild

| Önce | Sonra |
|------|--------|
| `VoiceWebOwnerStage` tüm `presence` listesi prop → 11 koltuk rebuild | Koltuk başına `VoiceWebOwnerStageSeat` + `select(VoiceSeatSnapshot)` |
| Mesaj/DJ değişimi tüm koltukları yeniden çizer | Yalnızca değişen koltuk snapshot'ı rebuild |

**Dosyalar:** `voice_seat_snapshot.dart`, `voice_web_owner_stage_seat.dart`, `voice_web_owner_stage.dart`  
**Test:** `mobile/test/voice_seat_snapshot_test.dart`

### Canlı sohbet feed scroll

| Önce | Sonra |
|------|--------|
| `ListView.builder(shrinkWrap: true)` nested scroll | Sabit `SizedBox(height)` + normal `ListView` |

**Dosya:** `voice_live_chat_dock.dart`

---

## FAZ 10 — 1.0.341+377

### Discover kategori grid (shrinkWrap)

| Önce | Sonra |
|------|--------|
| `GridView.builder(shrinkWrap: true)` nested scroll | `SizedBox` + sabit yükseklik `ListPerf.nestedGridHeight` |
| Hub + kategori sheet layout ölçüm maliyeti | Önceden hesaplanmış grid yüksekliği |

**Dosyalar:** `voice_discover_hub_2026.dart`, `voice_discover_2026.dart`, `list_perf.dart`  
**Test:** `mobile/test/list_perf_nested_grid_test.dart`

### Shell prefetch kademeleme

| Önce | Sonra |
|------|--------|
| T+200ms: cüzdan + bildirim + profil + **3× hediye katalog** | T+200ms: cüzdan + bildirim + profil |
| | T+**600ms**: hediye katalogları (tier 1b) |

**Dosya:** `shell_prefetch.dart`

### APK boyutu denetimi

- Belge: `PERFORMANCE_APK_AUDIT.md`
- Bundle assets: **~9,4 MB** (asıl boyut native SDK: TRTC, FFmpeg, Firebase)

### CI arm64 APK (FAZ 11)

| Varlık | Açıklama |
|--------|----------|
| `canlifal-mobile-release.apk` | Universal (arm + arm64 + x64) — `apk-latest` |
| `canlifal-mobile-arm64-release.apk` | Yalnızca arm64 — daha küçük indirme |

**Betik:** `scripts/build-apk-arm64.sh`

---

## FAZ 11/12 — 1.0.342+378

### arm64-only APK (CI)

| Önce | Sonra |
|------|--------|
| Yalnızca universal ~241 MB | + **arm64-only** asset (`apk-latest` release) |
| | `scripts/build-apk-arm64.sh` yerel derleme |

### Temel oda realtime feed

| Önce | Sonra |
|------|--------|
| `ListView.separated(shrinkWrap: true)` | `ListPerf.nestedListHeight` + sabit `SizedBox` |

**Dosya:** `voice_room_basic_realtime_feed.dart`

### Cihaz benchmark şablonu

- `PERFORMANCE_AFTER.md` — cold start, FPS, bellek, SSE doğrulama protokolü

---

## FAZ 13 — 1.0.343+379

### `/api/me` refresh dedupe

| Önce | Sonra |
|------|--------|
| `refreshMe()` her çağrıda `GET /api/me` | 8 sn throttle + in-flight paylaşım |
| Profil hub yenileme + pull-to-refresh üst üste | Tek ağ isteği |

**Dosyalar:** `refresh_me_gate.dart`, `auth_providers.dart`  
**Test:** `mobile/test/refresh_me_gate_test.dart`  
Profil düzenleme / OTP / avatar: `refreshMe(force: true)`

### Voice hub shrinkWrap

| Önce | Sonra |
|------|--------|
| Mention önerileri `shrinkWrap: true` | `nestedListHeight` (max 220) |
| Yakındaki odalar listesi `shrinkWrap: true` | Sabit yükseklik `ListView` |

---

## Henüz yapılmadı (sonraki fazlar)

- Gerçek cihaz benchmark değerlerinin doldurulması
- Hediye animasyonları CDN offload


---

## Regression

- `flutter test`: 1010 pass (3 yeni refresh gate test)
- `flutter analyze`: mevcut info seviyesi korunmalı
- Backend API: değişiklik yok
