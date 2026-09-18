# Canlifal Mobile — Tam Uygulama Audit Raporu (Aşama 1)

**Tarih:** 2026-09-18  
**Repo:** `mesutbyrm/Cursor-Flutter-` · uygulama: `mobile/` (`canlifal_social`)  
**Sürüm (pubspec):** `1.0.559+601`  
**Talimat:** `5_TAM_UYGULAMA_AUDIT_TALIMATI` — **yalnızca analiz; kod değişikliği yok**

---

## PROJECT SUMMARY

| Alan | Değer |
|------|--------|
| Flutter (CI pin) | `mobile/.flutter-version` → **3.44.8** |
| Flutter (bu ortam) | **3.47.4** stable (pin ile uyumsuzluk riski) |
| Dart SDK | `>=3.8.0 <4.0.0` |
| Paket | `canlifal_social` |
| `lib/` Dart dosyası | **5818** |
| Feature modülü | **43** (`mobile/lib/features/*`) |
| Presentation sayfa | **~135** (`*/presentation/pages/*.dart`) |
| Router | `app_router.dart` **1512** satır, **~296** route tanımı |
| API sabitleri | `api_endpoints.dart` **1097** satır |
| State yönetimi | **Riverpod** (birincil) + sınırlı **flutter_bloc** (sesli oda müzik vb.) |
| HTTP | **Dio** + retry, cache, 401 refresh koordinatörü, `flutter_secure_storage` |
| RTC | **Tencent TRTC** (`tencent_rtc_sdk`, yerel path override) |
| Gerçek zamanlı | **SSE** (Socket.IO değil); merkezi `SseConnectionHub` |
| Auth | JWT `Bearer` — `/api/auth/mobile-login`, `/api/auth/mobile-refresh`, `/api/me` |
| Üretim API | `https://canlifal.com` (`core/config/env.dart`) |
| Entegrasyon kaynağı | `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9 |
| `dart analyze` | **660** issue — **0 error**, **0 warning** (tamamı `info` seviyesi) · *Flutter 3.47.4 ortamında* |
| `flutter analyze` (CI pin 3.44.8) | **657** issue — **0 error**, **261 warning**, **396 info** · `lib/` 592 · `test/` 65 · 48,6 sn *(2026-09-18 doğrulama koşusu)* |
| `flutter test` | **1404** geçti, **2** skipped (~2:21) |
| `flutter test` (yeniden koşu) | **1408** geçti, **2** skipped, **0 başarısız** (4:20) *(2026-09-18, sürüm 1.0.559+602)* |
| Integration test | **Yok** (`integration_test` paketi/klasörü bulunamadı) |
| Release gate (CI) | Dokümantasyonda **FINAL PASS** (eski run referansları) |
| **RELEASE READY** | **NO** — **Psychic P0** cihaz testi (TRTC T+5s) kapanmadı |

**Öne çıkan riskler:** Canlı falcı TRTC donması (P0 cihaz bloker); PK state’in geçici API/SSE tutarsızlığında düşmesi ihtimali; analyze/info birikimi (`use_build_context_synchronously`); dokümantasyon sürüm drift’i; monolitik yayın odası dosyası bakım riski.

---

## ARCHITECTURE

**Katmanlar (feature-first Clean Architecture eğilimi):**

```
mobile/lib/
├── app/                 # router, tema girişi
├── core/                # network, auth, design_system, motion, SSE, config
└── features/<feature>/
    ├── data/            # datasources, repositories impl, DTO
    ├── domain/          # entities, repository interfaces
    └── presentation/    # pages, widgets, providers
```

**Navigasyon:** `go_router` — `app/router/app_router.dart` (auth redirect, derin link, admin, fal, live, sosyal, inbox, vb.).

**Ağ:** Tek ana `Dio` (`dio_provider.dart`) — `ApiVersionInterceptor`, `BackendRoutingInterceptor`, `ApiRetryInterceptor`, Bearer enjeksiyonu, `AuthTokenRefreshCoordinator` ile 401 → refresh.

**SSE:** `core/network/sse/base_sse_service.dart` — exponential backoff, Last-Event-ID, heartbeat; `sse_connection_hub.dart` oda/yayın başına lease/refcount.

**RTC:** Live video (`live/`), sesli oda (`voice_hub/`), canlı falcı (`live_psychics/` + `trtc/`) — TRTC token uçları kılavuz ile hizalı olmalı.

**Çift state riski (bilinçli köprüler):** PK için `liveVideoPkProvider` + `pk_battle_remote_provider` (voice_hub) + `livePkHomeTransitionProvider` (sunum); feed/social için deprecated `feed_providers` → `socialNotifierProvider` birleşimi devam ediyor.

---

## FEATURE MAP

| Modül | Rol | Ana giriş |
|-------|-----|-----------|
| `auth` | Giriş, OTP, oturum | `auth_flow_app`, `auth_repository_impl` |
| `shell` | Alt sekmeler | `main_shell_page.dart` |
| `home` | Ana hub | `home/` |
| `fortune` | Fal/tarot/günlük fal | `fortune_*_page.dart` |
| `live_psychics` | Canlı falcı TRTC | `live_psychics/` |
| `live` | Video yayın, PK UI, izleyici | `live_broadcast_room_page.dart` (3209 satır) |
| `voice_hub` | Sesli sohbet odaları, PK remote | `voice_hub/` |
| `pk` | PK yardımcı domain (ayrı feature klasörü) | test + modeller |
| `social` + `feed` | Sosyal akış + Tanış & Kaynaş | `social_page`, `tanis_kaynas_page` |
| `messages` + `inbox` | DM, gelen kutusu | `chat_page`, `inbox_page` |
| `profile` | Profil, ayarlar | `profile/` |
| `wallet` + `membership` + `vip_gold` | Jeton/CFC/Gold | `wallet/`, `membership_page` |
| `gifts` + `gift_box` | Hediye gönderimi, koleksiyon | `gift_hub_page` |
| `notifications` | Push + in-app | FCM + OneSignal |
| `games`, `shorts`, `cfc_arena`, … | Oyun, kısa video, arena | ilgili hub sayfaları |
| `admin` + `admin_web` | Mobil admin panelleri | yetki `/api/me/admin-capabilities` |

---

## API MAP

**Kaynak:** `mobile/lib/core/network/api_endpoints.dart` (canlifal.com hizalı sabitler).

| Grup | Örnek uçlar |
|------|-------------|
| Auth | `/api/auth/mobile-login`, `mobile-refresh`, `mobile-register`, OTP, sessions |
| User / Me | `/api/me`, `/api/me/membership`, `/api/mobile/user-profile/{id}` |
| Sosyal / Discovery | `/api/social/posts`, `/api/social/discovery`, `/api/social/actions` |
| Mesajlar | `/api/messages`, `/api/messages/{userId}`, `messages/request` |
| Chat odası (sesli) | `/api/chat/rooms/*`, presence, voice, music |
| Video yayın | `/api/video-streams/*`, SSE `.../stream` |
| PK | `/api/pk/*`, `pkMatchStream(matchId)` |
| Fal / Falcı | `/api/fortune-tellers/*`, `/api/room/{sessionId}`, SSE stream |
| Hediye | `/api/gifts/*`, battles, missions, insights |
| Cüzdan / ödeme | payment interceptor + profile deprecated payment paths |
| Bildirim | `/api/notifications/stream` |
| TRTC / Agora | token uçları (kılavuz §9 — live vs psychic ayrımı) |
| Admin | `/api/admin/*` (mobilde yetkili kullanıcı) |

**Uyumluluk notu:** `@Deprecated` işaretli uçlar hâlâ kodda (ör. `meGiftsReceived`, eski chat music pause/resume, `messagesConversations`).

---

## REALTIME MAP

| Kanal | Transport | Dosya / servis |
|-------|-----------|----------------|
| Sesli oda olayları | SSE | `chat_room_sse_service.dart`, hub lease |
| Video yayın (chat, hediye, izleyici) | SSE | `video_stream_sse_service.dart` |
| PK maçı | SSE | `ApiEndpoints.pkMatchStream` |
| Fal falcı bekleyen | SSE | `fortune-tellers/sessions/stream` |
| Fal oda | SSE | `liveFortuneRoom(sessionId)/stream` |
| Bildirimler | SSE | `notificationsStream` |
| DM (hazırlık) | SSE | `messages/conversations/{id}/stream` |
| Kısa video | SSE | `short-videos/{id}/stream` |
| Ses/görüntü | TRTC | `tencent_rtc_sdk`, `TrtcRoomManager` (psychic) |
| Yeniden bağlanma | Politika | `sse_reconnect_policy.dart`, max deneme kılavuz §5–6 |
| Connectivity | Trigger | `connectivity_sse_reconnect_provider.dart` |

**Lifecycle:** `sse_hub_lifecycle.dart` — arka plan/ön plan SSE yönetimi.

---

## AUTH AUDIT

**Durum:** JWT + secure storage + refresh koordinatörü mevcut; çoklu sosyal giriş (Google/Apple/TikTok) endpoint sabitleri tanımlı.

### Bulgular

#### [P2] Auth verify-device dokümantasyon çelişkisi
- **Dosya:** `mobile/lib/core/network/api_endpoints.dart`
- **Satır:** 39–40
- **Problem:** `authVerifyDevice` için GET vs POST çelişkisi yorumda belirtilmiş; mobil çağrı yanlış metot kullanıyorsa sessiz hata.
- **Neden:** Üretim dokümanları arası tutarsızlık.
- **Etkilenen özellik:** Cihaz doğrulama / reclaim akışı.
- **Çözüm:** Kılavuz §9 ile tek metot doğrula; integration test veya contract test.
- **Risk:** Orta — edge cihaz senaryoları.
- **Test:** Staging’de verify-device happy path.

#### [P3] Deprecated auth gateway sınıfı
- **Dosya:** `mobile/lib/features/auth/presentation/auth_flow_app.dart`
- **Satır:** 113
- **Problem:** `@Deprecated('AuthGatewayHost kullanın')` — eski giriş noktası hâlâ referans alınabilir.
- **Neden:** Migrasyon tamamlanmamış.
- **Etkilenen özellik:** Auth bootstrap.
- **Çözüm:** Referans taraması; kaldır veya tek host’a yönlendir.
- **Risk:** Düşük.
- **Test:** `flutter test test/features/auth/` (mevcut suite).

#### [P4] Session cookie + Bearer bir arada
- **Dosya:** `mobile/lib/core/network/dio_provider.dart`
- **Satır:** 69, 86–94
- **Problem:** Cookie jar + Bearer — web parity; mobilde gereksiz karmaşıklık.
- **Neden:** Tarihsel web API uyumu.
- **Etkilenen özellik:** Auth (nadiren çift kimlik).
- **Çözüm:** Mobil-only build’de cookie opsiyonel (değişiklik planlı).
- **Risk:** Düşük.
- **Test:** Login → `/api/me` yalnız Bearer.

---

## LIVE AUDIT

**Kapsam:** Yayın başlatma, oda, SSE, TRTC (yayın), izleyici etkileşim, co-host, fal entegrasyonu.

### Bulgular

#### [P0] Canlı falcı TRTC — T+5s A/V donması (cihaz bloker)
- **Dosya:** `docs/LIVE_PSYCHICS_REMAINING.md`, `docs/PSYCHIC_P0_START.md`
- **Satır:** 57–76 (LIVE_PSYCHICS), 6–7 (P0_START)
- **Problem:** **Psychic P0 PASS** alınmadı; RELEASE READY NO.
- **Neden:** Geçmiş bug T+5s’de donma; kodda Faz 2 TRTC düzeltmeleri var ama cihaz doğrulaması eksik.
- **Etkilenen özellik:** Canlı falcı görüntülü görüşme.
- **Çözüm:** İki cihaz checklist; gerekirse `live_psychics/` TRTC rejoin/gate hotfix.
- **Risk:** Kritik — release engeli.
- **Test:** `bash scripts/psychic-p0-checklist.sh`, logcat T+5s.

#### [P1] Monolitik yayın odası bakım ve regresyon riski
- **Dosya:** `mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart`
- **Satır:** 1–3209 (tüm dosya)
- **Problem:** Tek dosyada RTC, PK, co-guest, SSE, hediye, fal bildirimi — değişiklik yan etkisi yüksek.
- **Neden:** Organik büyüme.
- **Etkilenen özellik:** Tüm canlı yayın.
- **Çözüm:** Parçalı widget/provider extract (fix planında kontrollü).
- **Risk:** Yüksek regresyon PK/RTC.
- **Test:** Mevcut `live_*` unit/widget testleri + cihaz smoke.

#### [P2] SSE kopması sonrası kullanıcı geri bildirimi
- **Dosya:** `mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart`
- **Satır:** 2727–2728 (`sseConnected` dinleyicisi)
- **Problem:** Bağlantı değişimi işleniyor; tüm edge case’lerde sonsuz loading önlenmiş mi tam cihaz kanıtı yok.
- **Neden:** Ağ/SSE race.
- **Etkilenen özellik:** Canlı yorum/hediye senkronu.
- **Çözüm:** Banner + retry pattern’i psychic modülü ile hizala.
- **Risk:** Orta.
- **Test:** Uçak modu 30s manuel (PSYCHIC doc §5 benzeri).

#### [P3] Debug event logları (release’te kDebugMode guard’lı)
- **Dosya:** `mobile/lib/core/network/live_event_log.dart`, `live_debug_log.dart`
- **Satır:** ~10–22
- **Problem:** `[LIVE]` debugPrint — production’da kapalı ama payment/psychic logları benzer.
- **Neden:** Teşhis.
- **Etkilenen özellik:** Gizlilik (düşük).
- **Çözüm:** Merkezi log seviyesi; hassas alan maskeleme audit’i.
- **Risk:** Düşük.
- **Test:** Release build logcat taraması.

---

## PK AUDIT

**State:** `liveVideoPkProvider(streamId)` birincil battle map; `pk_battle_remote_provider`; sunum: `livePkHomeTransitionProvider`; dedup: `LivePkEventDedup`.

### Bulgular

#### [P1] `refresh()` battle temizleme — geçici API hatası + eksik dual-stream alanları
- **Dosya:** `mobile/lib/features/live/presentation/providers/live_video_pk_provider.dart`
- **Satır:** 152–166
- **Problem:** `fetchStreamBattle` null/bitti ve `isLivePkBroadcastStage` false ise `clearBattle: true` — eksik `opponentStreamId` ile stage false olup PK UI single-live’a düşebilir.
- **Neden:** `isLivePkBroadcastStage` dual-stream alanlarına bağlı (`live_pk_broadcast_stage.dart` 4–19).
- **Etkilenen özellik:** PK split ekran; audit talimatındaki “like sonrası PK kaybolması” sınıfı.
- **Çözüm:** Aktif PK latch (status + battleId TTL); refresh hata durumunda stale battle koru; SSE otoritesi.
- **Risk:** Yüksek — canlı yayında görünür glitch.
- **Test:** `live_video_pk_provider_test`, senaryo: partial JSON refresh.

#### [P2] PK like/heart — ayrı kod yolu (iyi) ama sessiz hata yutma
- **Dosya:** `mobile/lib/features/live/presentation/pages/live_broadcast_room_page.dart`
- **Satır:** 1992–2031
- **Problem:** PK aktifken double-tap `_postPkHeartScore`; catch `(_) {}` hata göstermiyor.
- **Neden:** UX gürültüsü engelleme.
- **Etkilenen özellik:** PK skor / like.
- **Çözüm:** Sınırlı retry veya snackbar (rate limited).
- **Risk:** Orta — skor senkron kaybı.
- **Test:** Mock API fail → UI feedback.

#### [P2] 15s polling yedek — SSE birincil değilse gecikme
- **Dosya:** `mobile/lib/features/live/presentation/providers/live_video_pk_provider.dart`
- **Satır:** 86–96
- **Problem:** Timer.periodic 15s — SSE kaçırılırsa skor gecikmesi.
- **Neden:** Yedek mekanizma.
- **Etkilenen özellik:** PK skor güncelliği.
- **Çözüm:** Unified PK SSE aboneliği doğrula; polling yalnızca SSE down iken.
- **Risk:** Orta.
- **Test:** SSE kapalı simülasyon.

#### [P4] Çok sayıda PK unit test (güçlü yan)
- **Dosya:** `mobile/test/features/live/live_video_pk_provider_test.dart` (+ ~20 PK test dosyası)
- **Satır:** —
- **Problem:** Yok — olumlu bulgu.
- **Neden:** —
- **Etkilenen özellik:** PK regresyon koruması.
- **Çözüm:** E2E cihaz PK smoke ekle (fix planı).
- **Risk:** —
- **Test:** Mevcut suite yeşil.

---

## VOICE ROOM AUDIT

**Kapsam:** Keşif, join/leave, roller, müzik, PK (sesli), TRTC/Agora geçiş artefaktları.

### Bulgular

#### [P2] Deprecated yönetim panelleri — çift UI yolu
- **Dosya:** `mobile/lib/features/voice_hub/presentation/sheets/voice_room_hub_settings.dart`, `voice_room_sheets.dart`
- **Satır:** 41–42, 67–68
- **Problem:** `@Deprecated('Use showVoiceRoomManagementPanel')` — admin/normal oda karışıklığı riski.
- **Neden:** UI konsolidasyonu yarım.
- **Etkilenen özellik:** Oda admin/moderator deneyimi.
- **Çözüm:** Tek panel; eski sheet referanslarını kaldır.
- **Risk:** Orta — yanlış rol UI.
- **Test:** Admin hesap manuel oda ayarları.

#### [P2] VoiceTrtcException rename geçişi
- **Dosya:** `mobile/lib/features/voice_hub/presentation/audio/voice_trtc_exception.dart`
- **Satır:** 19
- **Problem:** `VoiceAgoraException` deprecated alias.
- **Neden:** Agora → TRTC migrasyonu.
- **Etkilenen özellik:** Sesli oda hata mesajları.
- **Çözüm:** Tüm catch bloklarını yeni tipe güncelle.
- **Risk:** Düşük-orta.
- **Test:** `voice_hub` test klasörü.

#### [P3] Oda müziği deprecated stream URL
- **Dosya:** `mobile/lib/features/voice_hub/music/data/datasources/room_music_remote_datasource.dart`
- **Satır:** 53–54
- **Problem:** Eski IFrame/stream URL yolu işaretli deprecated.
- **Neden:** Oynatma mimarisi değişti.
- **Etkilenen özellik:** Oda müziği.
- **Çözüm:** Ölü kodu kaldır veya feature flag.
- **Risk:** Düşük.
- **Test:** Music bloc testleri.

---

## GIFT AUDIT

### Bulgular

#### [P2] Canlı + PK + voice hediye yolları — merkezi repo tek ama çok giriş noktası
- **Dosya:** `mobile/lib/features/gifts/data/gift_repository.dart`, live broadcast gift picker
- **Satır:** —
- **Problem:** Aynı işlem farklı UI’lardan; duplicate transaction guard sunucuya bağlı — client idempotency anahtarı audit edilmeli.
- **Neden:** Feature dağılımı.
- **Etkilenen özellik:** Hediye, jeton düşümü.
- **Çözüm:** Gönderim API body kılavuz §9 ile tekrar doğrula; client requestId.
- **Risk:** Orta — çift harcama (sunucu reddederse OK).
- **Test:** `live_pk_gift_stabilize_test.dart`.

#### [P3] Self-gift — kod taramasında açık bypass bulunamadı
- **Dosya:** `mobile/lib/features/gifts/` (grep selfGift)
- **Satır:** —
- **Problem:** Audit talimatı self-gift gereksinimini doğrulamak istiyor; mobilde açık `selfGift` handler yok — ürün kuralı backend’de doğrulanmalı.
- **Neden:** —
- **Etkilenen özellik:** Hediye kuralları.
- **Çözüm:** UI’da alıcı seçimi + API hata mesajı testi.
- **Risk:** Bilinmiyor.
- **Test:** Manuel self-send denemesi.

---

## WALLET / COIN AUDIT

### Bulgular

#### [P2] Deprecated payment API yolları profil datasource’da
- **Dosya:** `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart`
- **Satır:** 28, 497, 687, 878
- **Problem:** `_deprecatedPaymentApiPath` hâlâ kullanılıyor.
- **Neden:** Eski `/api/payment/*` mirror.
- **Etkilenen özellik:** Jeton satın alma / talep.
- **Çözüm:** Kılavuzdaki güncel cüzdan uçlarına migrate.
- **Risk:** Orta — prod 404/uyumsuz response.
- **Test:** Wallet repository integration mock.

#### [P3] Client-side balance manipülasyonu grep’i negatif
- **Dosya:** `mobile/lib/features/wallet/`
- **Satır:** —
- **Problem:** Bulunamadı — olumlu (balance set eden local hack yok).
- **Neden:** —
- **Etkilenen özellik:** Güvenlik.
- **Çözüm:** Sunucu otoritesi korunmalı (devam).
- **Risk:** Düşük.
- **Test:** Mevcut wallet testleri.

---

## GOLD AUDIT

### Bulgular

#### [P2] Premium yalnızca UI kilidi değil — membership API
- **Dosya:** `mobile/lib/features/membership/presentation/pages/membership_page.dart`, `ApiEndpoints.meMembership`
- **Satır:** 45–59 (page), endpoints 54–56
- **Problem:** Gold rozet/limit UI var; discovery Gold limitleri backend doğrulaması ile eşleşmeli (Tam audit cihaz gerektirir).
- **Neden:** Client/server parity.
- **Etkilenen özellik:** Tanış & Kaynaş limit, Gold badge.
- **Çözüm:** Discovery action 403 handling + upgrade CTA testi.
- **Risk:** Orta — premium bypass algısı.
- **Test:** Gold’suz hesapla super-like limit.

#### [P3] CDS skeleton membership catalog (olumlu)
- **Dosya:** `mobile/lib/features/membership/presentation/pages/membership_page.dart`
- **Satır:** 59
- **Problem:** Yok — loading state iyileştirilmiş.
- **Neden:** —
- **Etkilenen özellik:** Gold satın alma UX.
- **Çözüm:** —
- **Risk:** —
- **Test:** Widget test (varsa genişlet).

---

## CHAT AUDIT

### Bulgular

#### [P2] REST + SSE + eski conversations API bir arada
- **Dosya:** `mobile/lib/core/network/api_endpoints.dart`
- **Satır:** 74–81, 1011–1013
- **Problem:** `messages` vs `messagesConversations` + DM SSE “üretim hazır olduğunda” yorumu.
- **Neden:** Migrasyon.
- **Etkilenen özellik:** DM gerçek zamanlı, unread.
- **Çözüm:** Tek liste kaynağı; SSE lease inbox’ta doğrula.
- **Risk:** Orta — duplicate message/list stale.
- **Test:** `messages` provider testleri.

#### [P3] Match chat entegrasyonu Tanış modülüne bağlı
- **Dosya:** `mobile/lib/features/social/presentation/pages/tanis_kaynas_page.dart`
- **Satır:** 61 (`conversationsProvider` invalidate)
- **Problem:** Keşif yenileme sohbet listesini invalid ediyor — doğru ama race yoğun refresh’te flicker olabilir.
- **Neden:** Pull-to-refresh kapsamı geniş.
- **Etkilenen özellik:** Match → chat geçişi.
- **Çözüm:** Hedefli invalidate.
- **Risk:** Düşük.
- **Test:** Manuel match sonrası inbox.

---

## SOCIAL AUDIT

### Bulgular

#### [P3] Feed/Social notifier birleşimi — deprecated katman
- **Dosya:** `mobile/lib/features/feed/presentation/providers/feed_providers.dart`
- **Satır:** 19–20, 120, 124
- **Problem:** `@Deprecated('Use socialNotifierProvider')` — çift provider tüketimi riski.
- **Neden:** Feed → social merge.
- **Etkilenen özellik:** Sosyal akış, pagination.
- **Çözüm:** Tüm `feed*` referanslarını social’a taşı.
- **Risk:** Orta UI tutarsızlık.
- **Test:** Social widget testleri.

#### [P3] Fake local post yolu kapalı (olumlu)
- **Dosya:** `mobile/lib/features/social/presentation/providers/social_providers.dart`
- **Satır:** 157–159
- **Problem:** Deprecated fake post — implementasyon enjekte etmiyor.
- **Neden:** Audit kuralı mock yasağı.
- **Etkilenen özellik:** Gönderi oluşturma.
- **Çözüm:** Deprecated metodu kaldır.
- **Risk:** Düşük.
- **Test:** POST `/api/social/posts` mock test.

#### [P3] Sosyal layout — CDS responsive kullanımı
- **Dosya:** `mobile/lib/features/social/presentation/pages/social_page.dart`
- **Satır:** 6 (`cds_responsive.dart`)
- **Problem:** Talimattaki “gereksiz kenar boşluğu” için statik kanıt yok; padding 16–32 tab’larda standart — küçük ekran cihaz testi önerilir.
- **Neden:** —
- **Etkilenen özellik:** Feed genişliği.
- **Çözüm:** `CdsResponsive` max width audit cihazda.
- **Risk:** Düşük görsel.
- **Test:** 360dp emulator screenshot.

---

## TANIS & KAYNAS AUDIT

**API:** `/api/social/discovery`, actions, konum `Geolocator`.

### Bulgular

#### [P2] Konum izni / servis kapalı edge case
- **Dosya:** `mobile/lib/features/social/presentation/pages/tanis_kaynas_page.dart`
- **Satır:** 79–80
- **Problem:** `Geolocator.isLocationServiceEnabled()` — reddedilmiş izinde kullanıcı akışı snackbar/error ile tam mı (dosya devamında).
- **Neden:** Platform permission.
- **Etkilenen özellik:** Mesafe filtresi, keşif.
- **Çözüm:** Empty/error state standardize.
- **Risk:** Orta.
- **Test:** İzin reddi manuel.

#### [P2] Duplicate like engeli — sunucu otoritesi
- **Dosya:** `mobile/lib/features/social/presentation/providers/social_discovery_providers.dart` (actions)
- **Satır:** —
- **Problem:** Client-side optimistic UI varsa çift tık race — kod incelemesi fix planda derinleşmeli.
- **Neden:** Network latency.
- **Etkilenen özellik:** Like/super-like.
- **Çözüm:** Action lock + 409 handling.
- **Risk:** Orta.
- **Test:** Hızlı çift swipe simülasyonu.

#### [P4] Mock/dummy keşif verisi yok (olumlu)
- **Dosya:** `tanis_discover_tab.dart` + discovery providers
- **Satır:** —
- **Problem:** API tabanlı — talimatla uyumlu.
- **Neden:** —
- **Etkilenen özellik:** —
- **Çözüm:** —
- **Risk:** —
- **Test:** —

---

## FORTUNE / TAROT AUDIT

### Bulgular

#### [P2] Geniş route yüzeyi — fal animasyon shell
- **Dosya:** `mobile/lib/app/router/app_router.dart`, `fortune_animation_route_shell.dart`
- **Satır:** router import 17–25, 50–52
- **Problem:** Çok sayfa (intro, session, result, tarot hub) — loading/empty/error her birinde ayrı audit gerekir.
- **Neden:** Ürün zenginliği.
- **Etkilenen özellik:** Fal satın alma, jeton.
- **Çözüm:** Ekran envanteri checklist (fix planı).
- **Risk:** Orta — jeton düşümü hatası P1 olabilir.
- **Test:** `fortune` test klasörü.

#### [P3] Mobil fortune menu endpoint
- **Dosya:** `api_endpoints.dart`
- **Satır:** 47
- **Problem:** `mobileFortuneMenu` — offline cache policy doğrulanmalı.
- **Neden:** Ana sayfa menü.
- **Etkilenen özellik:** Fal kategorileri.
- **Çözüm:** ApiCachePolicy inceleme.
- **Risk:** Düşük.
- **Test:** Offline açılış.

---

## PROFILE AUDIT

### Bulgular

#### [P3] Deprecated timeline widget
- **Dosya:** `mobile/lib/features/profile/presentation/widgets/user_posts_timeline.dart`
- **Satır:** 28
- **Problem:** `@Deprecated('Use UserPostsTimelineSliver')`.
- **Neden:** Scroll performansı.
- **Etkilenen özellik:** Profil gönderileri.
- **Çözüm:** Eski widget referanslarını kaldır.
- **Risk:** Düşük.
- **Test:** Profil scroll test.

#### [P2] Kendi vs başka profil ayrımı
- **Dosya:** `profile_repository`, `mobileUserProfile` endpoint
- **Satır:** —
- **Problem:** Çoklu route (`/profile`, `/user/:id`) — yetkisiz alan gizleme backend’e bağlı; tam manuel doğrulama pending.
- **Neden:** —
- **Etkilenen özellik:** Privacy, block.
- **Çözüm:** Block/report entegrasyon testi.
- **Risk:** Orta.
- **Test:** Block sonrası profil görünürlüğü.

---

## NOTIFICATION AUDIT

### Bulgular

#### [P2] OneSignal + FCM çift stack
- **Dosya:** `pubspec.yaml` (firebase_messaging, onesignal_flutter)
- **Satır:** 55, 63
- **Problem:** İki push kanalı — deep link routing tutarlılığı karmaşık.
- **Neden:** Migrasyon/geçmiş.
- **Etkilenen özellik:** Push → ekran (PK, match, psychic).
- **Çözüm:** Tekincil kaynak deprecate planı; push payload testleri genişlet (`psychic_flow_push_test` iyi örnek).
- **Risk:** Orta — çift bildirim veya kaçan deep link.
- **Test:** Push action bridge testleri.

#### [P3] SSE notifications stream
- **Dosya:** `api_endpoints.dart`
- **Satır:** 1019
- **Problem:** In-app unread SSE — app lifecycle ile hub sync.
- **Neden:** Realtime badge.
- **Etkilenen özellik:** Bildirim rozeti.
- **Çözüm:** Background hub lifecycle test.
- **Risk:** Düşük.
- **Test:** SSE reconnect test (`sse_20_cycle_test.dart`).

---

## UI/UX AUDIT

### Bulgular

#### [P3] Design system mevcut ama ekranlar arası homojenlik tam değil
- **Dosya:** `mobile/lib/core/design_system/`, `core/theme/`, `platform_social_ui_kit.dart`
- **Satır:** —
- **Problem:** CDS + CanlifalMotion + legacy `app_theme_extensions` bir arada — bazı hub’lar farklı spacing/radius.
- **Neden:** Kademeli premium redesign.
- **Etkilenen özellik:** Görsel bütünlük.
- **Çözüm:** Ekran envanteri → CDS token zorunluluğu (talimat §16).
- **Risk:** Düşük işlevsel.
- **Test:** Görsel regresyon (manuel).

#### [P3] Dark mode
- **Dosya:** `core/theme/app_theme*.dart`
- **Satır:** —
- **Problem:** Tema dosyaları var; tüm 135 sayfada kontrast/gradient okunabilirlik cihaz audit’i yapılmadı.
- **Neden:** Kapsam.
- **Etkilenen özellik:** Erişilebilirlik.
- **Çözüm:** Kritik ekranlar önce (live, PK, chat).
- **Risk:** Düşük.
- **Test:** Dark theme screenshot set.

---

## ANIMATION AUDIT

### Bulgular

#### [P3] flutter_animate + lottie + custom motion tokens
- **Dosya:** `core/motion/canlifal_motion*.dart`, `pubspec.yaml` 37–39
- **Satır:** —
- **Problem:** Aşırı animasyon → rebuild maliyeti; live/PK’da ayrı profil gerekir.
- **Neden:** Premium hedef.
- **Etkilenen özellik:** FPS canlı yayın.
- **Çözüm:** RepaintBoundary audit; PK sırasında ağır animasyon kısıtı.
- **Risk:** Orta performans.
- **Test:** DevTools timeline (cihaz).

#### [P4] PK home transition bridge — sunum only (olumlu ayrım)
- **Dosya:** `live_pk_home_transition_bridge.dart`
- **Satır:** 6–9
- **Problem:** Yok — RTC’ye dokunmuyor.
- **Neden:** —
- **Etkilenen özellik:** Ana sayfa → PK geçişi.
- **Çözüm:** —
- **Risk:** —
- **Test:** `live_pk_home_transition_bridge_test.dart`.

---

## PERFORMANCE AUDIT

### Bulgular

#### [P2] `live_broadcast_room_page` rebuild yüzeyi
- **Dosya:** `live_broadcast_room_page.dart`
- **Satır:** 2622 (`ref.watch(liveVideoPkProvider)`)
- **Problem:** Çoklu `ref.listen/watch` — yanlış select kullanımı jank yapabilir.
- **Neden:** Tek stateful mega-widget.
- **Etkilenen özellik:** Canlı/PK FPS.
- **Çözüm:** Provider select granularization; split widgets.
- **Risk:** Orta.
- **Test:** Profile mode frame timing.

#### [P3] Json isolate transformer
- **Dosya:** `dio_provider.dart`
- **Satır:** 61–63
- **Problem:** Büyük JSON isolate — olumlu; threshold yanlışsa overhead.
- **Neden:** Performans optimizasyonu.
- **Etkilenen özellik:** Feed/live listeleri.
- **Çözüm:** Metrik toplama.
- **Risk:** Düşük.
- **Test:** `list_perf_nested_grid_test.dart` (mevcut).

#### [P4] Image caching
- **Dosya:** `cached_network_image`, `flutter_cache_manager`
- **Satır:** pubspec 28, 36
- **Problem:** Standart stack — video/shorts bellek ayrı audit.
- **Neden:** —
- **Etkilenen özellik:** Feed, profil.
- **Çözüm:** Shorts player dispose audit.
- **Risk:** Düşük.
- **Test:** Memory profiler.

---

## SECURITY AUDIT

### Bulgular

#### [P2] Token storage — secure storage (olumlu temel)
- **Dosya:** `core/network/token_storage.dart`, `dio_provider.dart`
- **Satır:** 86–91
- **Problem:** Bearer peek/read — standart; log interceptors hassas header loglamamalı.
- **Neden:** —
- **Etkilenen özellik:** Oturum güvenliği.
- **Çözüm:** ApiMonitor redaction review.
- **Risk:** Orta if logs leak.
- **Test:** Release log audit.

#### [P2] Admin mobil paneller
- **Dosya:** `features/admin/`, `ApiEndpoints.meAdminCapabilities`
- **Satır:** —
- **Problem:** Client-side admin UI — sunucu yetkisi olmadan işlem yapılamamalı (doğrulanmalı).
- **Neden:** Admin feature set.
- **Etkilenen özellik:** Moderasyon.
- **Çözüm:** 403 handling standardı.
- **Risk:** Yüksek if API güvenli değilse (backend sorumluluğu).
- **Test:** Non-admin hesap admin route deep link.

#### [P3] Bot account guard PK
- **Dosya:** `live_video_pk_provider.dart`
- **Satır:** 305–309
- **Problem:** Bot hesap PK başlatamaz — olumlu.
- **Neden:** Abuse önleme.
- **Etkilenen özellik:** PK.
- **Çözüm:** —
- **Risk:** —
- **Test:** Bot flag unit test.

---

## RESPONSIVE AUDIT

### Bulgular

#### [P3] `use_build_context_synchronously` — 30 info
- **Dosya:** çoklu (analyze)
- **Satır:** —
- **Problem:** Async gap sonrası context — nadiren crash veya yanlış navigator.
- **Neden:** Async UI pattern.
- **Etkilenen özellik:** Çeşitli sayfalar.
- **Çözüm:** `mounted` / `ref.context` guard refactor (P4 batch).
- **Risk:** Orta tail crash.
- **Test:** Analyze rule sıfırlama hedefi.

#### [P3] Safe area / bottom nav
- **Dosya:** `main_shell_page.dart`, shell feature
- **Satır:** —
- **Problem:** Gesture nav cihazlarda tab overlap manuel test edilmedi (Cloud emülatör yok).
- **Neden:** Ortam kısıtı.
- **Etkilenen özellik:** Alt navigasyon.
- **Çözüm:** Cihaz matrisi P1 checklist.
- **Risk:** Düşük-orta.
- **Test:** P1 device script.

---

## TEST AUDIT

| Metrik | Sonuç |
|--------|--------|
| Unit/widget | **1404** pass, **2** skip |
| PK coverage | **36+** dosya |
| Psychic | parser, TRTC freeze unit, widget sheets |
| Integration | **Eksik** |
| CI acceptance | `scripts/run-acceptance-tests.sh` (API gate; cihaz yok) |

### Bulgular

#### [P1] Cihaz E2E boşluğu — kritik akışlar
- **Dosya:** `docs/LIVE_PSYCHICS_REMAINING.md`
- **Satır:** 87–91
- **Problem:** Flutter integration/driver test yok; Psychic/Live/PK yalnızca manuel.
- **Neden:** CI emülatör politikası.
- **Etkilenen özellik:** Release güveni.
- **Çözüm:** Smoke script genişletme veya Firebase Test Lab (fix plan).
- **Risk:** Yüksek.
- **Test:** P0/P1 checklist zorunlu.

#### [P4] Analyze info gürültüsü — 660 issue
- **Dosya:** tüm proje
- **Satır:** —
- **Problem:** 146 unused_import, 134 unnecessary_underscores — CI’da fail etmiyor.
- **Neden:** Lint seviyesi info.
- **Etkilenen özellik:** Geliştirici hızı.
- **Çözüm:** Aşamalı cleanup sprint.
- **Risk:** Düşük.
- **Test:** `dart analyze` trend.

---

## P0 ISSUES

| ID | Özet |
|----|------|
| P0-1 | **Psychic P0 TRTC T+5s A/V donması** — cihaz PASS alınmadı, RELEASE READY NO (`docs/LIVE_PSYCHICS_REMAINING.md` 57–76, `docs/PSYCHIC_P0_START.md` 6–7) |
| P0-2 | **Hediye gönderiminde atomik olmayan jeton düşümü** — bakiye negatife inebilir, hata durumunda jeton kaybolur, retry'da çift ücret (`api/src/routes/gifts.ts` 199–242) |

**Detay (§29 format):**

**[P0] Psychic TRTC donması — release bloker**  
- **Dosya:** `docs/LIVE_PSYCHICS_REMAINING.md`  
- **Satır:** 57–76  
- **Problem:** Canlı falcı görüşmesinde T+5s kritik noktada A/V donması geçmişte repro edildi; P0 kapanmadı.  
- **Neden:** TRTC oda yaşam döngüsü / token / rejoin race (kod düzeltmeleri var, cihaz kanıtı yok).  
- **Etkilenen özellik:** Canlı falcı modülü, release.  
- **Çözüm:** İki cihaz checklist PASS veya FAIL logcat ile hotfix.  
- **Risk:** Uygulama store/release engeli.  
- **Test:** `bash scripts/psychic-p0-checklist.sh`

**[P0] Hediye gönderiminde atomik olmayan jeton düşümü — release bloker**  
*(Bu bulgu, raporun GIFT AUDIT §312 ve §791'de "audit edilmeli" diye açık bırakılan idempotency sorusunun cevabıdır — backend kodu okunarak doğrulandı.)*
- **Dosya:** `api/src/routes/gifts.ts`  
- **Satır:** 199–242  
- **Problem:** Üç kusur tek blokta: **(1) check-then-act yarışı** — bakiye okuma (200) ile düşme (205) ayrı sorgular, aralarında koşul yok; eşzamanlı iki istek aynı bakiyeyi okuyup ikisi de kontrolü geçer → **bakiye negatife iner**. **(2) Transaction yok** — jeton 205'te düşüyor, `giftEvent` 228'de oluşuyor; arada `resolveCombo` (212) ve alıcı sorgusu (216) var, burada hata olursa **jeton gitti, hediye yok**. **(3) Idempotency yok** — retry/çift dokunuşta ikinci kez tam ücret.  
- **Neden:** Prisma `decrement` atomikliğinin koşullu güncelleme yerine geçtiği varsayılmış.  
- **Etkilenen özellik:** Hediye gönderimi (canlı, PK, sesli oda), jeton bakiyesi, `applyPkGift` üzerinden PK skoru.  
- **Kanıt:** Proje `$transaction`'ı 10 yerde doğru kullanıyor (`lib/pkBattleService.ts:601`, `lib/referralCommissionService.ts:410,478,538`, `lib/voiceRoomRevenue.ts:120,196`, `routes/video_streams.ts:703`, `routes/short_videos.ts:300,313,415`) — **gelir tarafı korunmuş, harcama tarafı korunmamış.**  
- **Çözüm:** (a) `updateMany({ where: { id, coins: { gte: totalCost } }, … })` + `count === 0` → 402; (b) düşme + `giftEvent.create` + `applyPkGift` tek `$transaction` içinde; (c) `Idempotency-Key` + `giftEvent` unique index. **`emitGiftEvent` / `giftQueueEnqueue` transaction dışında kalmalı** — aksi halde rollback'te hayalet event yayılır.  
- **Risk:** Düşük–orta; tek endpoint, mevcut sözleşme korunur.  
- **Test:** Eşzamanlı 2 istekle negatif bakiye üretilemediği; `giftEvent.create` fail ettirilip jetonun iade edildiği; aynı idempotency key ile tek ücret alındığı.

**[P0 yan bulgu] Hediye alıcısı benzersiz olmayan `displayName` ile çözülüyor**  
- **Dosya:** `api/src/routes/gifts.ts` · **Satır:** 214–226  
- **Problem:** `findFirst({ OR: [{ username }, { displayName }] })` — `username` benzersiz ama `displayName` değil (`routes/users.ts:36` yalnızca `min(1).max(120)`). Aynı görünen adı taşıyan iki hesapta hediye ve gelir **rastgele/yanlış kullanıcıya** yazılır.  
- **Çözüm:** Alıcı yalnızca `receiverId` ile çözülmeli; isim gerekiyorsa sadece benzersiz `username`, çoklu eşleşmede 409.  
- **Test:** Aynı `displayName`'li iki kullanıcı seed'lenip belirsiz alıcıya yazılmadığı doğrulanmalı.

---

## P1 ISSUES

| ID | Özet |
|----|------|
| P1-1 | PK `refresh()` battle clear — dual-stream kaybında single-live UI (`live_video_pk_provider.dart` 152–166) |
| P1-2 | Monolitik `live_broadcast_room_page.dart` regresyon riski (3209 satır) |
| P1-3 | Cihaz E2E/integration test eksikliği — kritik akışlar (`LIVE_PSYCHICS_REMAINING.md` 87–91) |
| P1-4 | **PK stale guard `paused` statüsünü kapsamıyor + 90 sn TTL < 180 sn maç süresi** — P1-1'in kök nedeni (`live_pk_refresh_stale_guard.dart` 12–22) |
| P1-5 | **Geçici ağ hatası PK battle'ını siliyor** — catch bloğu silme yoluna düşüyor (`live_video_pk_provider.dart` 170–181) |
| P1-6 | **`pkSessionProvider` `autoDispose`** — izleyici düştüğünde PK state sıfırlanıyor (`pk_session_notifier.dart` 356–359) |

**Detay (§29 format) — P1-4/5/6, P1-1'in kök neden analizidir:**

**[P1-4] PK stale guard kapsam açığı — maç sürerken single-live'a düşüş**  
- **Dosya:** `mobile/lib/features/live/domain/pk/live_pk_refresh_stale_guard.dart` · **Satır:** 12–22  
- **Problem:** Guard'ın koruduğu statüler (`pk_status_helper.dart` + `live_pk_broadcast_stage.dart` üzerinden doğrulandı): `pending, invited, created, waiting, active, started, in_progress, running, starting, countdown, preparing, ended, completed, finished, tie, draw, cancelled, canceled`. **`paused` hiçbirinde yok.** Oysa `pk_session_notifier.dart:102-104,245-247` `PkStatus.paused`'ı aktif maç gibi ele alıyor → maç `paused` iken boş refresh gelirse `clearBattle: true` çalışır ve PK ekranı düşer.  
- **İkinci açık:** `staleTtl` **90 sn**, ancak varsayılan maç süresi `pk_session_notifier.dart:261`'de **180 sn**. 90 sn'yi aşan ağ sorununda maç canlıyken UI düşer.  
- **Üçüncü açık:** `isLivePkBroadcastStage` koşulsuz korumayı ancak `livePkHasDualStreams` doğruysa verir; SSE'den eksik payload gelip `opponentLiveStreamId` boşalırsa 90 sn TTL yoluna düşülür (P1-1'de gözlenen dual-stream senaryosu budur).  
- **Neden:** Sorun daha önce fark edilip zaman pencereli yamayla kapatılmış (docstring birebir: *"single-live düşüşünü önler"*); statü listesi genişleyince yama güncellenmemiş.  
- **Çözüm:** `paused`'ı kapsayan `isLivePkRetainableStatus` tanımlanmalı; TTL `battleEndsAt` üzerinden türetilmeli. Kalıcı çözüm: görünürlük istemci refresh'ine değil **sunucudan gelen açık `ended` olayına** bağlanmalı — yokluk asla "bitti" demek olmamalı.  
- **Risk:** Orta — guard genişletilirken gerçekten biten maçların takılı kalmaması için `_scheduleEndedCleanup` birlikte doğrulanmalı.  
- **Test:** Saf fonksiyon, birim testi kolay: `paused` + boş refresh → korunmalı; `active` + 120 sn önce authority + 180 sn maç → korunmalı; gerçek `ended` → silinmeli.

**[P1-5] Geçici ağ hatası PK battle'ını siliyor**  
- **Dosya:** `mobile/lib/features/live/presentation/providers/live_video_pk_provider.dart` · **Satır:** 170–181  
- **Problem:** `catch` bloğu hatayı state'e yazıp akışı 177–181'e bırakıyor; guard tutmazsa `clearBattle: true`. Tek bir timeout/500 PK ekranını düşürebiliyor. Hata yolu ile "sunucu battle yok dedi" yolu aynı sonuca bağlanmış — oysa *hata* bilgi yokluğudur, *boş yanıt* bilgidir.  
- **Çözüm:** `catch` battle'ı asla silmemeli; yalnızca `error` set edip state korunmalı. Silme yalnızca sunucu açıkça "yok/ended" dediğinde.  
- **Risk:** Düşük (daraltıcı değişiklik).  
- **Test:** `fetchStreamBattle` throw ederken `state.battle` korunmalı.

**[P1-6] `pkSessionProvider` `autoDispose` — state kaybı**  
- **Dosya:** `mobile/lib/features/pk/presentation/providers/pk_session_notifier.dart` · **Satır:** 356–359  
- **Problem:** `NotifierProvider.autoDispose.family` — izleyici kalmadığında state imha olur, sonraki okuma `const PkSessionState()` (battle **yok**) döner. Navigasyon/sheet açılışı izleyicileri anlık düşürürse PK state sıfırlanır. Ayrıca `loadState()` (116–130) ve `_action()` (338–353) `await` sonrası `state` yazıyor, `ref.mounted` kontrolü yok → disposed notifier'a yazma riski.  
- **Çözüm:** Battle non-null iken `ref.keepAlive()`, `ended`'de bırak; `await` sonrası yazımları `ref.mounted` ile koru.  
- **Risk:** Düşük–orta (`ended` sonrası serbest bırakma şart, aksi halde sızıntı).  
- **Test:** İzleyici widget'ı ağaçtan çıkarıp geri ekleyen widget testi.

---

## P2 ISSUES

- Auth verify-device metot belirsizliği (`api_endpoints.dart` 39–40)  
- Live SSE edge / loading (`live_broadcast_room_page.dart` 2727+)  
- PK heart score silent catch (`live_broadcast_room_page.dart` 2031)  
- PK 15s polling gecikmesi (`live_video_pk_provider.dart` 86–96)  
- Voice deprecated admin sheets (`voice_room_hub_settings.dart` 41–42)  
- Wallet deprecated payment paths (`profile_remote_datasource.dart` 28, 497+)  
- Gold/discovery server parity (membership + discovery actions)  
- Chat REST/SSE/conversations migrasyonu (`api_endpoints.dart` 74–81, 1011–1013)  
- Tanış konum/duplicate like race (`tanis_kaynas_page.dart` 79+)  
- Fortune geniş route/jeton akışları  
- Profile block/privacy manuel gap  
- Push OneSignal+FCM dual stack (`pubspec.yaml` 55, 63)  
- Performance live room rebuild (`live_broadcast_room_page.dart` 2622+)  
- Security admin UI vs server auth  
- Gift idempotency client audit → **CEVAPLANDI: bkz. P0-2** (backend'de transaction ve idempotency yok)  

**2026-09-18 doğrulama koşusunda eklenen P2 bulguları:**

- **Sayfalama yok — `page: 1` beş yerde sabit:** `social_discovery_providers.dart:23`, `social_providers.dart:44,59`, `user_social_posts_notifier.dart:18,30`. Keşif akışı, sosyal akış ve kullanıcı gönderileri yalnızca 1. sayfayı çekiyor; sonsuz kaydırma fiilen yok. *Çözüm:* mevcut `core/pagination/` altyapısına bağlanmalı, yeni sistem kurulmamalı. *Test:* sayfa 2 isteğini doğrulayan datasource testi.
- **Feed'de sahte kullanıcılar empty-state yerine geçiyor:** `feed_story_strip.dart:23-30` — gerçek gönderi yokken `'Özge'`, `'Ela'`, `'Arda'` adlı var olmayan kullanıcılar `i.pravatar.cc` avatarlarıyla gösteriliyor. Hem sahte veri hem eksik empty-state. *Çözüm:* fallback kaldırılıp gerçek empty-state konmalı. *Test:* `posts: []` ile widget testi.
- ~~**Hata durumu kapsamı çok düşük:** `ErrorState`/`ErrorView` yalnızca **6 dosyada**…~~ → **BU BULGU YANLIŞTI, 2026-09-18'de düzeltildi.**

  > ### ⚠ Düzeltme: bulgu hatalıydı
  >
  > Ölçüm yalnızca `ErrorState`/`ErrorView` **adlandırmasını** aradı; kod tabanı hata durumlarını başka bileşenlerle ele alıyor: `AppErrorView` (`core/widgets/app_error_view.dart`), `CdsError` (tasarım sistemi), `DiscoverEmptyInline`, `PremiumEmptyHint`, `psychic_async_views`, `platform_social_ui_kit`, `game_center_widgets`.
  >
  > **Gerçek ölçüm:** `error:` dalı olan **210** yer · bunlardan gizleyen (`SizedBox.shrink`) **46** (%22) · anlamlı hata gösterimi kullanan **53 dosya**. Kapsam iddia edildiği gibi kritik değil.
  >
  > Gizleyen 46 dalın çoğu **bilinçli**: rozet, "top hediye", üyelik etiketi gibi ikincil bölümlerde hata anında koca bir hata bloğu göstermek yanlış olurdu. Örnek: `economy_wallet_transactions_section.dart` docstring'i birebir *"yalnızca `/api/user/wallet` başarılıysa görünür"* diyor — tasarım kararı.
  >
  > **Yerine geçen gerçek bulgu (aşağıda P0/P2'ye eklendi):** tasarım sisteminin `CdsError.view`'i kullanıcıya **ham `error.toString()`** gösteriyordu.
- **PK sayacı saniyede bir tüm izleyicileri rebuild ediyor:** `pk_session_notifier.dart:93-114` — `Timer.periodic(1 sn)` her tetiklenmede `state = state.copyWith(...)` yazıyor; `pkSessionProvider`'ı izleyen her widget saniyede bir rebuild oluyor. PK ekranı zaten video + skor + chat + hediye animasyonu taşıyor. *Çözüm:* kalan süre dar kapsamlı ayrı provider'a taşınmalı veya `select` ile daraltılmalı.
- **Admin rozeti taklit edilebilir (görsel — yetki değil):** `voice_moderation_target_color.dart:22` ve `voice_seat_avatar_frame.dart:31` rütbeyi kısıtsız `nickname`/`name` alanından türetiyor (`voice_staff_rank.dart:15-22`: `%`→admin). `displayName` backend'de karakter kısıtı taşımıyor (`users.ts:36`). **Ölçülü değerlendirme — yetki yükseltmesi DEĞİL:** gerçek yetki kararı `voice_room_permissions.dart:146` üzerinden `user.username` ile veriliyor ve `username` backend'de `^[a-zA-Z0-9_]+$` ile korunuyor (`users.ts:43`). Etki yalnızca rozet rengi ve koltuk çerçevesi → sosyal mühendislik riski. *Çözüm:* bu iki call-site de `user.username` kullanmalı.

---

## P3 ISSUES

- Deprecated auth gateway, feed/social duplicate providers  
- Social padding/responsive cihaz doğrulama  
- UI/UX CDS homojenlik, dark mode tam tarama  
- Animation FPS live/PK  
- Responsive `use_build_context_synchronously` (30)  
- Notification SSE lifecycle  
- Analyze deprecated_member_use (52)  

**2026-09-18 doğrulama koşusunda eklenen P3 bulguları:**

- **`yacht` hediyesi yanlış animasyon gösteriyor — varlık eksik:** `gift_catalog_maps.dart` satır 13/19/24 (`'lottie:yacht'`, `'yacht'`, `'yat'`) üçü de `assets/gifts/lottie/star.json`'a işaret ediyor. `mobile/assets/gifts/lottie/` içeriği doğrulandı: **`car, crown, heart, rose, star`** — `yacht.json` **yok**. Katalogdaki en pahalı hediyelerden biri yıldız animasyonu oynatıyor. *Çözüm:* `yacht.json` eklenmeli; eklenene kadar ayırt edilebilir başka bir varlığa yönlendirilmeli. *Test:* katalogdaki her anahtarın var olan bir asset'e çözüldüğünü doğrulayan birim testi — bu tür sessiz eksikleri kalıcı olarak önler.
- **Üretim kodunda üçüncü parti placeholder görselleri:** `images.unsplash.com` (27 kullanım) ve `i.pravatar.cc` sabit URL olarak gömülü — `fortune_type_images.dart:5`, `section_visual_catalog.dart:3`, `discover_live_carousel.dart:124,132,140,412`, `live_background_picker_sheet.dart:25,29,33`. SLA'sız üçüncü parti CDN; erişim kesilirse fal kategorileri, ana sayfa görselleri ve canlı arka planları boş kalır. *Çözüm:* kendi CDN/asset'lerine taşınmalı veya backend'den yönetilmeli.

---

## P4 ISSUES

- 660 analyze info (unused_import, unnecessary_underscores, …)  
- Deprecated API sabitleri ve voice/music dead paths  
- Cookie jar + Bearer birlikteliği  
- Json cache/image standard cleanup  
- PK zengin unit testleri (olumlu — bakım)  

---

## DUPLICATE CODE

| Alan | Açıklama |
|------|----------|
| Feed vs Social | `feed_providers.dart` ve `social_providers.dart` — aynı akış notifier’ına merge ediliyor, deprecated katman sürüyor |
| PK remote | `voice_hub/pk_battle_remote_*` + `live/live_video_pk_provider` — bilinçli köprü, duplicate fetch riski polling+SSE ile |
| Payment paths | Profile `_deprecatedPaymentApiPath` vs wallet modülü |
| Theme/UI | `app_theme_extensions` vs `core/design_system/cds.dart` |
| RTC exception | `VoiceAgoraException` vs `VoiceTrtcException` |

---

## UNUSED CODE

| Tür | Kanıt |
|-----|--------|
| Analyze `unused_import` | **146** info |
| Analyze `unused_element` | **23** info |
| Analyze `unused_field` | **7** info |
| Deprecated API/constants | `api_endpoints.dart` pause/resume music, eski gifts path |
| Dead social fake post | Deprecated metod, boş gövde (`social_providers.dart` 157–159) |

*Not: Dosya silme audit aşamasında yapılmadı — kullanım taraması fix planda.*

---

## MISSING FEATURES

| Beklenti (talimat) | Durum |
|--------------------|--------|
| Integration test suite | **Eksik** |
| Tek premium design system tüm ekranlarda | **Kısmen** (CDS var, full rollout yok) |
| Psychic P0 cihaz sign-off | **Eksik** |
| Play Store AAB/keystore (release) | Dokümantasyonda kullanıcı adımı — **agent prep tamam, yükleme yok** |
| DM SSE tam prod parity | Endpoint yorumu “hazır olduğunda” — **doğrulama gerek** |
| iOS hedef | Proje Android odaklı CI |

---

## BROKEN FLOWS

| Akış | Durum | Kanıt |
|------|--------|--------|
| Canlı falcı TRTC T+5s | **Şüpheli / FAIL bekleniyor** | P0 docs, kullanıcı PASS yazmadı |
| PK → single-live glitch | **Potansiyel** | `refresh()` clear battle mantığı |
| APK apk-latest metadata | **CI geçmişte FAIL** | SHA256/skip upload — script düzeltmeleri main’de; yeni run doğrulama önerilir |
| Release READY | **Kapalı** | `AGENTS.md`, `DOCS_RELEASE_INDEX.md` |

*Mock/dummy keşif akışı tespit edilmedi — sosyal keşif API tabanlı.*

---

## RELEASE BLOCKERS

1. **Psychic P0 PASS** (TRTC T+5s) — zorunlu manuel  
2. **RELEASE READY: NO** resmi bayrak  
3. **Play Console** yükleme / keystore — kullanıcı adımları (`docs/KALAN_ISLER.md`)  
4. **CI cihaz E2E yok** — regresyonlar geç fark edilir  
5. **Dokümantasyon sürüm drift** — docs `1.0.391+429` vs pubspec `1.0.559+601` (karar karmaşası)  
6. **Flutter pin drift** — `.flutter-version` 3.44.8 vs ortam 3.47.4  
7. **P0-2 — hediye jeton düşümü atomik değil** (`gifts.ts` 199–242): gerçek para kaybı ve negatif bakiye üretebilir; finansal doğruluk sürüm öncesi zorunlu  
8. **P1-4/P1-5 — PK single-live düşüşü**: kullanıcının bildirdiği asıl şikâyet; ana özellik zayıf ağda kullanılamaz hale geliyor  
9. **P0 yan bulgu — hediye yanlış alıcıya** (`gifts.ts` 214–226): yayıncı gelirini yanlış hesaba yazabilir  

---

## RECOMMENDED FIX ORDER

1. **P0** — Psychic TRTC: cihaz repro → hotfix (yalnızca `live_psychics`/`trtc` scope) → P0 PASS kaydı  
1b. **P0-2** — `gifts.ts` koşullu atomik düşme + `$transaction` + idempotency *(izole, tek endpoint, en yüksek kazanç)*  
1c. **P0 yan** — hediye alıcı çözümünü `receiverId`/`username` ile sınırla *(aynı dosya, aynı test turu)*  
1d. **P1-5** — `refresh()` catch bloğu battle'ı silmesin *(tek blok, daraltıcı)*  
1e. **P1-4** — stale guard `paused` kapsamı + TTL'i maç süresinden türet *(saf fonksiyon, test kolay)*  
1f. **P1-6** — PK oturumu aktifken `keepAlive` + `ref.mounted` koruması  
2. **P1** — PK state latch: `live_video_pk_provider.refresh` stale battle koruması + test  
3. **P1** — `live_broadcast_room_page` kontrollü parçalama (PK/RTC dokunmadan widget extract)  
4. **P1** — Release metadata: apk-latest CI run doğrula (`scripts/verify-apk-latest-release.sh`)  
5. **P2** — Wallet/payment path migration kılavuz §9  
6. **P2** — Chat/DM SSE tek kaynak  
7. **P2** — Tanış action lock + Gold limit API hata UX  
8. **P2** — Push/deep link birleştirme test matrisi  
9. **P3** — CDS UI homojenlik ekran sprint (fonksiyon değiştirmeden)  
10. **P4** — Analyze cleanup batch + deprecated silme (kanıtlı)  
11. **Docs** — `DOCS_RELEASE_INDEX.md` sürüm senkronu  

---

---

# EK: 2026-09-18 DOĞRULAMA KOŞUSU

Bu bölüm, raporun ilk sürümünden sonra yapılan bağımsız bir doğrulama koşusunun sonuçlarıdır. Amaç, açık bırakılmış soruları kapatmak ve bulguları kanıta bağlamak. **Bu koşuda da hiçbir kaynak dosya değiştirilmedi.**

## Yöntem ve kapsam

**Gerçekten çalıştırıldı:**
- Flutter **3.44.8** SDK (CI pin'i) kuruldu → `flutter pub get` + `flutter analyze` → **657 bulgu, 0 error**
- `flutter test` → **1.408 geçti, 2 atlandı, 0 başarısız** (4 dk 20 sn, exit 0)
- 324.911 satırın tamamında grep taraması (TODO/mock/hardcoded/placeholder/dispose desenleri)
- Derin kod okuması: PK state zinciri, hediye/para yolu (**backend dahil**), sesli oda rol sistemi, keşif veri akışı

**Yapılmadı — bu raporda iddia edilmiyor:**
- **Görsel/UI denetimi yapılmadı.** Uygulama çalıştırılmadı, ekran görüntüsü alınmadı, cihazda test edilmedi (ortamda emülatör/cihaz yok). UI/UX, animasyon ve responsive maddeleri **kod seviyesinde** değerlendirildi, görsel olarak değil. Bu bölümler cihaz testi gerektirir.
- Release/debug build alınmadı, APK üretilmedi.
- 43 modülün **8'i** derinlemesine okundu; kalanlar yalnızca otomatik tarama kapsamındadır. **Bulgu listesi tüketici değildir.**
- Backend'in 21.761 satırının tamamı okunmadı — yalnızca para yolu (`gifts.ts`), kullanıcı doğrulama (`users.ts`) ve transaction kullanımı incelendi.

## Doğrulanmış pozitifler — bu alanlarda müdahale gerekmiyor

| Alan | Bulgu |
|---|---|
| Teknik borç işaretleri | **0 TODO / FIXME / HACK** (324.911 satırda) — olağandışı temiz |
| Mock/dummy veri | Kod genelinde **0** — tek istisna `feed_story_strip.dart` (P2'de raporlandı) |
| Debug çıktısı | **0 ham `print(`** — yalnızca 129 `debugPrint` |
| Hassas veri loglama | FCM token'ları `substring(0, 12)` ile **maskelenmiş** (`firebase_bootstrap.dart:53,76`); auth loglarında şifre/token yok |
| İstemci tarafı bakiye | Cüzdan/hediye modüllerinde **yerel bakiye mutasyonu yok**; bakiye sunucuda doğrulanıyor (`gifts.ts:202`) |
| Dispose hijyeni | 301 `dispose()` / 218 `AnimationController`; 393 `cancel()` / 27 `StreamSubscription` — sistemik sızıntı işareti yok |
| Bağımlılık temizliği | `socket_io_client` ve `livekit_client` pubspec'ten kaldırılmış, kodda kalıntı yok |
| Endpoint yönetimi | 212 endpoint tek dosyada merkezî |
| Tanış & Kaynaş | **Gerçek backend'e bağlı** (`SocialDiscoveryRemoteDataSource`); filtreler sunucuya iletiliyor — mock sistem **değil** |
| Transaction bilinci | `$transaction` 10 yerde doğru kullanılıyor — eksik olan yalnızca `gifts.ts` (P0-2) |
| Test süiti sağlığı | **1.408 testin tamamı geçiyor** — güvenilir regresyon ağı |
| Derleme sağlığı | `flutter analyze` **0 error** |

## PK çoklu source-of-truth — yapısal kök neden (refactor, EN SONA)

`pk_session_notifier.dart:229-259` (`_applyBattle`) state'i ikinci bir provider'a aynalıyor:

```dart
if (arg.kind == PkContextKind.live) {
  ref.read(liveVideoPkProvider(arg.contextId).notifier).applyRemoteBattle(…);
} else {
  ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(remote);
}
```

PK durumu **üç yerde** yaşıyor: `pkSessionProvider.state`, `liveVideoPkProvider.state`, `pkBattleRemoteProvider.state`. Üstelik `liveVideoPkProvider`'ın **kendi bağımsız `refresh()` ve 15 sn polling'i** var (`live_video_pk_provider.dart:100-111`) — yani ayna kaynağından bağımsız güncellenip **sapabiliyor**. P1-4/P1-5'in etkisini büyüten yapısal neden budur.

**Neden en sona bırakıldı:** PK'nın tüm görünürlük mantığı bu iki provider'a bağlı; risk **yüksek**. Önce P1-4/P1-5/P1-6 (düşük riskli, semptomu durdurur) uygulanmalı, refactor ancak karakterizasyon testleri yazıldıktan sonra, izole bir adımda yapılmalı. Kullanıcının 19. ve 20. kuralları (önce mevcut mimariyi çıkar, tek seferde rastgele değiştirme) doğrudan bu maddeye işaret ediyor.

---

*Sonraki aşama (kullanıcı onayı sonrası): `FIX_PLAN.md` — bu raporda kod değişikliği yapılmamıştır.*
