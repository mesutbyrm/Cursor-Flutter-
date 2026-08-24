# Flutter ↔ Abacus.ai Backend Entegrasyon Durumu

**Tarih:** 15 Temmuz 2026  
**Tek kaynak:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](./FLUTTER_ENTegrasyon_KILAVUZU.md)

---

## Özet

Flutter istemcisi **yalnızca istemci** olarak çalışır; backend mantığı taşınmaz. HTTP katmanı merkezi `dioProvider` / `ApiClient` üzerinden gider; özellikler **Repository + RemoteDataSource** ile modüllere ayrılmıştır (ayrı `*Service` sınıfları isim farkıdır, davranış aynıdır).

| Alan | Durum |
|------|--------|
| JWT + refresh | ✅ `dio_provider.dart`, `token_storage.dart` |
| Backend routing (main / games) | ✅ `api_backend_router.dart` |
| Retry + cache + keep-alive | ✅ interceptors |
| SSE (oda, yayın, PK, falcı) | ✅ |
| Bildirim SSE | ✅ bu PR — `notifications_sse_service.dart` |
| Push (OneSignal / FCM) | ✅ `push_notification_service.dart` |
| Offline banner | ✅ `OfflineStatusBanner` kabukta |
| SSE ağ geri dönüşü | ✅ `connectivity_sse_reconnect_provider.dart` |
| Sesli oda PK | ✅ `docs/PK_VOICE_ROOM_PARITY.md` |
| Admin tam yetki | ✅ `staff_access_provider` + `StaffRoles` |

---

## API katmanı eşlemesi

| İstenen servis | Flutter modülü |
|----------------|----------------|
| AuthService | `features/auth/` |
| UserService / ProfileService | `features/profile/` |
| WalletService | `profile` → `WalletRepository` |
| RoomService / ChatService / MusicService | `features/voice_hub/` |
| LiveService / PKService | `features/live/` + `voice_hub/pk` |
| GiftService | `features/gifts/` |
| NotificationService | `features/notifications/` |
| StoryService | `features/social/` (story rings) |
| ShortsService | `features/shorts/` |
| SearchService | `features/search/` |
| FollowService | `ProfileRepository.follow*` |
| AdminService | `features/admin/` |

Merkezi giriş: `mobile/lib/core/network/api_client.dart`

---

## Gerçek zamanlı (web ile aynı)

| Sistem | Kanal | Dosya |
|--------|-------|-------|
| Sesli oda | SSE `GET …/chat/rooms/{id}/stream` | `chat_room_sse_service.dart` |
| Canlı yayın | SSE `GET …/video-streams/{id}/stream` | `video_stream_sse_service.dart` |
| PK (live) | SSE `GET /api/pk/{id}/stream` | `pk_match_sse_service.dart` |
| PK (voice) | Oda SSE `type: pk` + Socket.IO yedek | `pk_battle_remote_provider.dart` |
| Bildirimler | SSE `GET /api/notifications/stream` | `notifications_sse_service.dart` |
| Falcı | SSE sessions + room | `psychic_*_sse_service.dart` |

Reconnect: exponential backoff max 20; 401 → refresh; çevrimiçi olunca hub yeniden bağlanır.

---

## Performans (uygulanan)

- **Açılış:** `main.dart` paralel cache init; `home_bootstrap` 7 paralel bölüm; kabuk T+200ms cüzdan+bildirim+profil `Future.wait`
- **Sesli oda giriş:** `<1s` bütçe — `voice_room_entry_perf.dart`, optimistic presence, SSE önce
- **Liste:** `LazyListView`, `SliverList.builder`, pagination notifiers
- **Resim:** `canlifal_network_image.dart` → CDN cache
- **Provider cache:** `voiceRoomsProvider`, `liveGiftCatalogProvider` → `keepAlive`
- **HTTP cache:** `api_cache_interceptor.dart` (oda listesi 30s, bildirim 2dk, …)

---

## Bilinçli sınırlar / sonraki adımlar

| Konu | Not |
|------|-----|
| DM SSE | `message_sse_service.dart` henüz bağlı değil — üretim stream path doğrulanmalı |
| Video SSE reconnect | `VideoStreamSseService` ayrı implementasyon — connectivity reconnect eklenebilir |
| Tek `ApiClient` facade | Mevcut; tüm yeni kod datasource üzerinden |
| Backend değişikliği | **Yapılmaz** — yalnızca istemci uyumu |

---

## Doğrulama

```bash
cd mobile && flutter test test/core/network/
cd mobile && dart analyze
bash scripts/verify-pk-endpoints.sh
```

Sesli oda PK ayrıntısı: [`PK_VOICE_ROOM_PARITY.md`](./PK_VOICE_ROOM_PARITY.md)
