# Performans Değişiklik Günlüğü

**Sürüm:** `1.0.348+384`  
**Tarih:** 2026-08-23  
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

## FAZ 14 — 1.0.344+380

### Voice hub sheet scroll

| Önce | Sonra |
|------|--------|
| 9× `shrinkWrap` (menü, komut, picker, yönetim) | `nestedGridHeight` / `Flexible` / sabit liste |
| DM composer eylem grid `shrinkWrap` | `LayoutBuilder` + sabit grid |

**Dosyalar:** `voice_room_menu_sheet.dart`, `voice_room_commands_panel.dart`, `voice_room_management_panel.dart`, `voice_moderation_user_picker_sheet.dart`, `voice_room_voice_users_sheet.dart`, `voice_room_muted_users_sheet.dart`, `chat_composer.dart`

---

## FAZ 15 — 1.0.345+381

### Hub settings + moderasyon + profil grid

| Önce | Sonra |
|------|--------|
| Hub settings tile grid `shrinkWrap` | `LayoutBuilder` + `nestedGridHeight` |
| Arka plan preset grid `shrinkWrap` | Sabit yükseklik grid |
| Moderasyon eylem grid `Flexible` + `shrinkWrap` | Sabit yükseklik grid |
| Koltuk seçici `GridView.count` `shrinkWrap` | `nestedGridHeight` (11 koltuk) |
| Profil izlenen / skeleton grid `shrinkWrap` | Sabit yükseklik grid |
| `ShortsProfileGrid` nested scroll `shrinkWrap` | Sabit yükseklik grid |

**Dosyalar:** `voice_room_hub_settings.dart`, `voice_room_moderation_sheet.dart`, `profile_content_section.dart`, `shorts_profile_content.dart`

---

## FAZ 16 — 1.0.346+382

### Profil + hediye + LazyNestedGridView

| Önce | Sonra |
|------|--------|
| `LazyNestedGridView` her zaman `shrinkWrap` | `nestedGridHeight` + sabit `SizedBox` |
| Profil cüzdan / yayıncı panel grid `shrinkWrap` | Sabit yükseklik / `Wrap` |
| `profile_content_tabs` fal + izlenen `shrinkWrap` | `nestedListHeight` / `nestedGridHeight` |
| TikTok paylaşım grid `shrinkWrap` | Sabit yükseklik grid |
| Top gifters `shrinkWrap` liste | `nestedListHeight` (max 10) |
| Hediye sheet listeleri `shrinkWrap` / `Flexible` | `ConstrainedBox` scroll |

**Dosyalar:** `lazy_list_views.dart`, `profile_content_tabs.dart`, `profile_wallet_section.dart`, `profile_broadcaster_panel.dart`, `user_posts_tiktok_grid.dart`, `user_shorts_videos_section.dart`, `top_gifters_leaderboard.dart`, `session_gift_summary_sheet.dart`, `seat_gift_breakdown_sheet.dart`

---

## FAZ 17 — 1.0.347+383

### Kalan grid/sheet shrinkWrap temizliği

| Önce | Sonra |
|------|--------|
| VIP ayrıcalık grid `shrinkWrap` | `nestedGridHeight` |
| Profil hediyeler + koleksiyon albüm grid | Sabit yükseklik |
| Fal türleri ultra grid | Sabit yükseklik |
| Falcı bahşiş / süre uzatma grid | Sabit yükseklik |
| Üyelik özellik grid | Sabit yükseklik |
| Shorts keşfet video grid | Sabit yükseklik |
| Admin / ajans panel grid | Sabit yükseklik |
| Studio emoji / taslak / müzik listeleri | Sabit yükseklik veya `ConstrainedBox` |
| Skeleton grid/list iskelet | Sabit yükseklik |

**Dosyalar:** `vip_privilege_grid.dart`, `profile_gifts_page.dart`, `gift_collection_page.dart`, `ultra_fortune_types_section.dart`, `psychic_tip_sheet.dart`, `psychic_extend_sheet.dart`, `premium_membership_widgets.dart`, `live_star_tournament_sheet.dart`, `shorts_explore_page.dart`, `admin_panel_page.dart`, `agency_dashboard_screen.dart`, `premium_skeleton.dart`, `psychic_video_session_screen.dart`, `studio_compose_page.dart`, `shorts_studio_page.dart`, `studio_publish_page.dart`

---

## FAZ 18 — 1.0.348+384 (final)

### shrinkWrap sıfırlama + profil tek scroll

| Önce | Sonra |
|------|--------|
| Kullanıcı profili `ListView` + nested `shrinkWrap` timeline | `CustomScrollView` + `UserPostsTimelineSliver` |
| Jeton ödeme formu `ListView` shrinkWrap | `SingleChildScrollView` |
| `LazyNestedGridView` fallback shrinkWrap | `nestedGridHeightForDelegate` (tüm delegate türleri) |
| `shrinkWrap: true` (`mobile/lib`) | **0** |

**Dosyalar:** `user_profile_page.dart`, `user_posts_timeline.dart`, `jeton_payment_notify_sheet.dart`, `list_perf.dart`, `lazy_list_views.dart`

---

## Program tamamlandı

- FAZ 3–18: `1.0.336+372` → `1.0.348+384`
- `shrinkWrap: true`: **51 → 0**
- `flutter test`: **1011 pass**
- Kalan: fiziksel cihaz benchmark (`PERFORMANCE_AFTER.md`), hediye animasyon CDN


---

## Regression

- `flutter test`: 1011 pass
- `shrinkWrap: true` (`mobile/lib`): **0**
- Backend API: değişiklik yok
