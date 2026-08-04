# Canlifal Flutter ↔ Backend Tam Senkronizasyon Raporu

**Tarih:** 2026-08-04  
**Sürüm:** `1.0.128+162`  
**Kaynaklar:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (tek sözleşme), `api/` (yerel ayna), `mobile/lib/core/network/api_endpoints.dart`, üretim envanteri

> Yerel `api/` aynası üretimin tam kopyası değildir (~251 handler vs ~384 üretim). Flutter hedefi: **canlifal.com** gerçek API'leri. Bu raporda “Backend” = kılavuz + üretim envanteri; “Ayna” = yerel `api/`.

---

## Özet

| Modül | Backend (üretim/kılavuz) | Flutter | Eksik | Bu oturumda düzeltme | Durum |
|-------|--------------------------|---------|-------|----------------------|-------|
| 1. Sesli sohbet odaları | ✅ Tam | 🟡 ~95% | PK path varyantı, lock/kick koltuk UI | `lockSeat`/`kickFromSeat` API | 🟡 Çalışıyor |
| 2. Canlı yayın | ✅ Tam | 🟡 ~92% | TRTC reconnect, unban/unmute UI | TRTC coordinator, moderasyon | 🟡 Çalışıyor |
| 3. Canlı falcılar | ✅ Tam | 🟡 ~90% | incoming path sırası | Üretim `sessions` öncelik | 🟡 Çalışıyor |
| 4. Sosyal | 🟡 Kısmi | 🟡 ~85% | Stories stub, hashtag, tek post UI | `fetchPost` + provider | 🟡 Kısmi |
| 5. CDN | ✅ R2/CDN | 🟡 ~80% | Tüm asset tipleri | CDN prefix genişletme | 🟡 Çalışıyor |
| 6. Hediye sistemi | ✅ Tam | ✅ ~95% | — | Süre backend'den (mevcut) | ✅ Çalışıyor |
| 7. Tencent RTC | ✅ TRTC | ✅ TRTC-only | Agora/WebRTC kalıntı | `flutter_webrtc` kaldırıldı | ✅ Çalışıyor |
| 8. Performans | — | 🟡 Devam | Monolith provider, rebuild | Kısmi (önceki oturum) | 🟡 Devam |
| 9. API senkronizasyonu | — | 🟡 ~97% | Sosyal stories, shorts extras | Kritik path düzeltmeleri | 🟡 Çalışıyor |
| 10. Test | — | ✅ 366 test | Acceptance CI | Otomatik doğrulama | ✅ Geçti |

**APK:** Kullanıcı talimatı gereği %100 tamamlanana kadar **APK üretilmeyecek**.

---

## 1. Sesli Sohbet Odaları

| Özellik | Backend | Flutter | Eksik | Düzeltme | CDN | RTC | API uyumu | Durum |
|---------|---------|---------|-------|----------|-----|-----|-----------|-------|
| Oda oluşturma | `POST /create` | `live_remote_datasource` | — | — | — | TRTC | ✅ | ✅ |
| Giriş/çıkış | `presence` join/leave | `joinRoom`/`leaveRoom` | — | — | — | TRTC | ✅ | ✅ |
| Reconnect | SSE + presence heartbeat | SSE backoff 20 deneme | — | Mevcut | — | TRTC auto | ✅ | ✅ |
| Koltuklar | `GET/POST /seats` | `fetchSeats`/`assignSeat` | lock/kick UI | `lockSeat`/`kickFromSeat` eklendi | — | — | ✅ | 🟡 |
| Moderasyon | `/moderation` | `_postModeration` + fallback | — | Mevcut | — | — | ✅ | ✅ |
| DJ / müzik kuyruğu | `/music-queue`, `/song-request` | `RoomSongBloc` IFrame | — | Önceki oturum | — | — | ✅ | ✅ |
| PK | `/pk` + `/pk-battle` | `pk_battle_remote_datasource` | Path varyantı | Fallback zinciri | — | — | 🟡 | 🟡 |
| Typing | `POST /typing` | `setTyping` | — | Mevcut | — | — | ✅ | ✅ |
| Settings | `PATCH /settings` | `updateRoomSettings` | — | Mevcut | — | — | ✅ | ✅ |
| Voice token | `POST /voice` | TRTC `/api/trtc/token` | Agora kaldırıldı | TRTC-only | — | TRTC | ✅ | ✅ |
| Hediyeler | `/gifts` | `chat_room_gifts_remote_datasource` | — | Mevcut | ✅ CDN | — | ✅ | ✅ |
| SSE | 8+ event tipi | `ChatRoomSseService` | Ayna eksik event | Üretimde tam | — | — | ✅ | ✅ |

---

## 2. Canlı Yayın

| Özellik | Backend | Flutter | Eksik | Düzeltme | CDN | RTC | Durum |
|---------|---------|---------|-------|----------|-----|-----|-------|
| Başlat/bitir | `POST /video-streams`, `/end` | `createVideoStream`/`endVideoStream` | — | — | — | TRTC | ✅ |
| Reconnect | `/live/heartbeat` | `TrtcLiveRoomCoordinator` | Sayfa entegrasyonu | **Bu oturum** | — | TRTC | ✅ |
| Co-host | `/co-broadcast` | `co_broadcast_provider` | — | Mevcut | — | TRTC | ✅ |
| PK / battle | `/pk-battle`, `/api/pk/battles` | PK providers + UI | Global leaderboard ayna | Fallback | — | TRTC | 🟡 |
| Yorumlar | `/messages` | `fetchStreamMessages` | Guide `/comments` adı | Üretim path | — | — | ✅ |
| Hediyeler | `/gifts` + socket | `live_gift_controller` | — | Mevcut | ✅ CDN | — | ✅ |
| Moderasyon | mute/ban/moderator | sheet + datasource | unban/unmute UI | **Bu oturum** | — | — | ✅ |
| İzleyici listesi | `GET /viewers` | `fetchStreamViewers` | Ayna eksik | Üretimde var | — | — | 🟡 |
| Host transfer | — | — | Üretimde yok | N/A | — | — | N/A |

---

## 3. Canlı Falcılar

| Özellik | Backend | Flutter | Düzeltme | Durum |
|---------|---------|---------|----------|-------|
| Oturum oluştur | `POST /{tellerId}/session` | `createSession` | — | ✅ |
| Gelen istekler | `GET /sessions?status=pending` | poll + SSE | **incoming path sona alındı** | ✅ |
| Kabul/red | `PATCH /sessions/{id}` | `respondSession` | — | ✅ |
| TRTC görüşme | `/api/trtc/token` + `/api/room/*` | `TrtcLiveRoomCoordinator` | Mevcut | ✅ |
| Ödeme/dakika | room timer/extend | `live_psychics` room actions | — | 🟡 |
| SSE | `/sessions/stream` | `psychicRoomSseService` | — | ✅ |

---

## 4. Sosyal

| Özellik | Backend (üretim) | Flutter | Eksik | Düzeltme | Durum |
|---------|------------------|---------|-------|----------|-------|
| Feed | `GET /social/posts` | `SocialRemoteDataSource.fetch` | following filter | — | 🟡 |
| Tek post | `GET /posts/{id}` | `fetchPost` + `postDetailProvider` | Detay sayfası UI | **API eklendi** | 🟡 |
| View tracking | `POST /posts/{id}/view` | `registerPostView` | Ayna stub | Üretimde çalışır | 🟡 |
| Beğeni/yorum | ✅ | ✅ | — | — | ✅ |
| Shorts | `/short-videos/*` | `shorts/` modül | explore/hashtag ayna | — | 🟡 |
| Stories | Üretim kısmi | UI var | Backend storage | — | ❌ |
| Takip | `/users/{id}/follow` | `profile_remote_datasource` | — | — | ✅ |

---

## 5. CDN

| Asset tipi | Mekanizma | Cache | Lazy load | Durum |
|------------|-----------|-------|-----------|-------|
| Hediyeler (PNG/Lottie/MP4/WEBM) | `CloudMediaUrl` → `cdn.girlive.com` | `CanlifalImageCacheManager` | Preload (`gift_engine_preloader`) | ✅ |
| Profil / sosyal görseller | `CanlifalNetworkImage` + thumbnail | ✅ | ✅ | ✅ |
| Shorts / story / reels | `CloudMediaUrl` + thumb türetme | ✅ | Infinite scroll | 🟡 |
| Sticker / emoji / banner | CDN prefix listesi genişletildi | ✅ | — | 🟡 |

---

## 6. Hediye Sistemi

| Format | Destek | Süre kaynağı | Animasyon | Durum |
|--------|--------|--------------|-----------|-------|
| PNG | ✅ | catalog | Lottie/static | ✅ |
| Lottie | ✅ | `animationDurationMs` | Tam süre | ✅ |
| MP4/WEBM | ✅ | `engineDurationMs` backend | Ses + video tam | ✅ |

---

## 7. Tencent RTC

| Özellik | Durum | Not |
|---------|-------|-----|
| Agora | ❌ Kaldırıldı | Modül silindi |
| LiveKit | ❌ Kaldırıldı | `livekit_client` yok |
| WebRTC (`flutter_webrtc`) | ❌ Kaldırıldı | **Bu oturum** |
| TRTC token | ✅ | `POST /api/trtc/token` |
| join/leave/publish/mute/camera | ✅ | `TrtcRoomManager` |
| Reconnect | ✅ | `TrtcLiveRoomCoordinator` (canlı + falcı) |
| Network quality | ✅ | `networkQuality` notifier |

---

## 8. Performans (devam eden)

| Madde | Durum |
|-------|-------|
| `chat_room_providers` split (DJ mixin) | ✅ Önceki oturum |
| `flutter_webrtc` kaldırma | ✅ Bu oturum |
| const / dispose / pagination | 🟡 Kısmi |
| Isolate / shader compile | ⏳ Planlı |

---

## 9. API Senkronizasyonu — Bu Oturum Düzeltmeleri

1. `fortuneTellerIncomingSessions` → üretim `GET /sessions?status=pending` öncelikli
2. `socialPublicStats` fallback kaldırıldı → `GET /api/public-stats`
3. `agoraToken` / `livekitToken` sabitleri kaldırıldı
4. `socialPost(id)` + `fetchPost` eklendi
5. `lockSeat` / `kickFromSeat` kılavuz §9.3
6. Canlı yayın: `TrtcLiveRoomCoordinator` (heartbeat + reconnect)
7. Canlı moderasyon: unmute / unban UI
8. CDN: `CanlifalImageUrls` gift/shorts/story prefix

---

## 10. Test Sonuçları

| Suite | Sonuç |
|-------|-------|
| `flutter test` | **366 passed**, 2 skipped |
| `scripts/run-acceptance-tests.sh` | Bekleniyor (push sonrası) |

---

## Kalan işler (APK öncesi)

1. Stories — üretim API tamamlanınca Flutter UI bağlantısı
2. Shorts explore/hashtag/mentions — yalnızca üretimde varsa ekleme
3. Sosyal tek post detay sayfası (deep link)
4. Voice room lock/kick koltuk UI bağlantısı
5. `chat_room_providers.dart` tam parçalama
6. Performans profili + memory leak taraması

---

*Son güncelleme: agent oturumu `cursor/backend-flutter-sync-df6c`*
