# Web ↔ Flutter Parity Gap Report

> **Tarih:** 31 Temmuz 2026  
> **Tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) + canlifal.com üretim  
> **Sürüm:** `1.0.113+146` (Faz 3 tamamlandı)

## Kabul kriterleri durumu

| Kriter | Durum | Not |
|--------|-------|-----|
| Aynı endpoint'ler | 🟡 Kısmen | Gift insights/battle/goal/admin registry tamamlandı |
| Aynı response model | 🟡 Kısmen | PostEntity metadata genişletildi; bazı ekranlar eski DTO |
| Aynı event sistemi (SSE) | 🟢 | 5 kılavuz SSE + PK; DM poll optimize (12s global + 8s açık chat) |
| JWT / Bearer | 🟢 | `mobile-refresh`, secure storage |
| Cache web parity | 🟡 | HTTP TTL sıkılaştırıldı; hassas uçlarda stale kapalı |
| Gerçek zamanlı hediye | 🟢 | Canlı yayında SSE aktifken poll kapatıldı |
| Tek repository | 🟡 | Feed→social birleşti; voice rooms tek notifier; services deprecated |
| Global state | 🟢 | Live + voice discover tek kaynak |
| Performans | 🟡 | Skeleton var; gereksiz rebuild taraması devam |

---

## Faz 3 — Tamamlanan (1.0.113+146)

| Alan | Değişiklik |
|------|------------|
| Sosyal akış | `socialNotifierProvider` — toggleLike/registerView/addLocalPost; feed migration |
| Sesli odalar | `discover_voice_rooms.dart` + `voiceRoomsListNotifier` — home/keşif çift fetch önlendi |
| Hediye registry | `gift_insights/goal/battle/admin` datasource → `ApiEndpoints` |
| Marquee | `giftRepository.fetchRecentBigGifts` (legacy `giftService` kaldırıldı) |
| DM | `openDmConversationIdProvider`; unread bump → açık chat refresh; chat poll 8s |
| Legacy services | `@Deprecated` işaretlendi (auth/config hariç) |

## Faz 4 — Sıradaki

1. `services/` tamamen kaldırma (auth/config migrate)
2. DM gerçek SSE (backend hazır olunca)
3. Home keepAlive SSE invalidation
4. Performans audit (const, RepaintBoundary)
5. Kalan hardcoded `/api/` (`chat_room_providers.dart` vb.)

---

## Faz 2 — Tamamlanan (1.0.112+145)

| Alan | Değişiklik |
|------|------------|
| Canlı keşif | `discover_live_streams.dart` — tek notifier, ortak invalidate |
| Takip listesi | `userFollowersProvider` / `userFollowingProvider` |
| Yorumlar | `postCommentsProvider` — sheet + feed paylaşımlı cache |
| DM poll | `conversations_page` çift poll kaldırıldı |
| Falcı SSE | Oda poll SSE varken 20s |
| Admin ödeme | `AdminPaymentsSseService` |
| Hardcoded API | room music, live remote, chat room, gifts catalog |

## Faz 3 — Sıradaki (tamamlandı → Faz 4)

_Eski madde listesi Faz 3 bölümüne taşındı._

---

## 1. API — Eksik / yanlış endpoint'ler

### Bu oturumda düzeltilenler

| Alan | Düzeltme |
|------|----------|
| Auth | `authMobileApple`, email verify public path |
| Timeout | 15s connect / 30s receive (kılavuz) |
| Retry | GET 429 + 5xx, max 3 deneme |
| Bildirim okundu | `PATCH /api/notifications` + body önce |
| Burç | `POST /api/horoscope/daily` önce, GET yedek |
| İstatistik | `GET /api/public-stats` birincil |
| Fal erişim | `GET /api/fortune-access/check` eklendi |
| Sosyal görüntüleme | `POST /api/social/posts/{id}/view` |
| Presence | `POST /api/presence` heartbeat oturum yenilemede |
| Endpoint sabitleri | `paymentMethods`, `search`, `userTheme`, `followStatus`, `userPosts` |

### Hâlâ eksik / yapılacak

| Endpoint (kılavuz §9) | Öncelik |
|----------------------|---------|
| `GET /api/user/theme` + PATCH | Orta |
| `GET /api/user/{id}/follow-status` UI bağlantısı | Orta |
| `GET /api/user/likers` | Düşük |
| `GET /api/fortune-request-types` | Orta (canlı fal formu) |
| `GET /api/popups` | Orta |
| `GET /api/translations` | Düşük |
| `GET /api/ads/active` + reward | Orta |
| `GET /api/video-streams/{id}/fortune-requests/my-status` | Orta |
| Hardcoded `/api/` (~15 dosya) → `api_endpoints.dart` | Yüksek |

---

## 2. Cache

### Katmanlar

| Katman | Dosya | Web parity |
|--------|-------|------------|
| HTTP memory+disk | `api_http_cache.dart`, `api_cache_interceptor.dart` | TTL kısaltıldı |
| Stale fallback | `api_cache_policy.dart` | 7 gün → 1 saat; wallet/me/messages/social hariç |
| Sosyal akış | `social_providers.dart` | `forceRefresh: true` + skeleton refresh |
| Medya | `gift_cache_service.dart`, `video_cache_service.dart` | Oda çıkışında temizlik mevcut |
| Riverpod keepAlive | `home_providers.dart` | 60s poll — invalidation genişletilecek |

### Yapılacak

- Home `keepAlive` provider'ları SSE/presence olayında invalidate
- `CacheFirstLoader` voice discover TTL 15dk → 2dk veya SSE tetikli
- DM thread resume `forceRefresh: true`

---

## 3. Real-time (SSE / poll)

### Kılavuz SSE (5) — ✅

| Endpoint | Servis |
|----------|--------|
| `/api/chat/rooms/{id}/stream` | `ChatRoomSseService` |
| `/api/video-streams/{id}/stream` | `VideoStreamSseService` |
| `/api/room/{sessionId}/stream` | `PsychicRoomSseService` |
| `/api/fortune-tellers/sessions/stream` | `PsychicIncomingSseService` |
| `/api/notifications/stream` | `NotificationsSseService` |

### Ek SSE

- `/api/pk/{matchId}/stream` — PK
- Fortune POST stream — AI fal chunk

### Bu oturumda

- Canlı hediye: SSE bağlıyken 8s REST poll **kapalı** (`LiveGiftRealtimeService.setSseActive`)
- SSE reconnect **%30 jitter** (`SseReconnectPolicy`)

### Poll / SSE çakışması (yapılacak)

| Özellik | Poll | Öneri |
|---------|------|-------|
| DM | 5s + 12s | Tek poll veya push SSE |
| Psychic room | 3s + SSE | SSE varken poll kapat |
| Home lists | 60s | Presence/SSE invalidate |
| Live meta | 20s | SSE `stream_ended` yeterli |

---

## 4. Repository & state

### Duplicate fetch riski

- `liveStreamsProvider` + `homeLiveStreamsProvider` + `liveStreamsListNotifier`
- `voiceRoomsProvider` + `homeVoiceRoomsProvider` + discover
- `feedNotifierProvider` + `socialNotifierProvider` (feed tab = home)
- `GiftRepository` × 3 catalog path

### Önerilen birleştirme (Faz 2)

1. Tek `discoverStreamsProvider`
2. Tek `discoverVoiceRoomsProvider`
3. `feedNotifier` → `socialNotifier` migrate
4. `services/*.dart` kaldır

---

## 5. Loading & performans

- ✅ Sosyal refresh: `copyWithPrevious` (liste kaybolmaz)
- Yapılacak: `liveStreamsListNotifier`, `userSocialPostsNotifier` aynı pattern
- Yapılacak: `RepaintBoundary` shorts/live grid
- Yapılacak: `const` widget audit (home header)

---

## 6. Video & resim

| Alan | Durum |
|------|-------|
| `CanlifalNetworkImage` | ✅ |
| Gift MP4 cache | ✅ `VideoCacheService` |
| Shorts preload | Kısmi — top N preload genişletilecek |
| Story thumbnail | CachedNetworkImage üzerinden |

---

## 7. Hata yönetimi

| Kod | Dosya |
|-----|-------|
| Log + süre | `api_monitor_interceptor.dart`, `api_timing_interceptor.dart` |
| 401 refresh | `dio_provider.dart`, `auth_token_refresh_coordinator.dart` |
| ApiException | `api_exception.dart` — 403/404/429 mesajları |
| Yapılacak | 429 kullanıcı mesajı UI'da standart snackbar |

---

## 8. Ekran bazlı web karşılaştırma (özet)

| Ekran | Eksik özellik | Eksik API/Event |
|-------|---------------|-----------------|
| Ana sayfa | Canlı liste gecikmesi | Home compound + ayrı poll |
| Sosyal | — | `fortune_share` SSE ✅ |
| DM | Gerçek zamanlı yok | Message SSE yok |
| Sesli oda | — | Chat SSE ✅, müzik queue ✅ |
| Canlı yayın | Co-broadcast edge | Fortune my-status poll |
| PK | Davet popup ✅ | PK SSE ✅ |
| Profil | Takip listesi local fetch | `followersProvider` yok |
| Jeton | Bakiye flash | wallet 8s cache |
| Admin | Ödeme SSE yok | `admin/payments/stream` tanımlı, bağlı değil |

---

## Otomatik tamamlama planı (Faz 2+)

1. Hardcoded path migration (voice music, gifts admin)
2. Unified live/voice discover providers
3. DM realtime strategy (SSE veya web poll interval eşleme)
4. `followersProvider` / `postCommentsProvider`
5. Admin payments SSE
6. Legacy `services/` removal
7. Acceptance test genişletme (`docs/ACCEPTANCE_TESTS.md`)

---

_Bu dosya parity çalışması ilerledikçe güncellenir._
