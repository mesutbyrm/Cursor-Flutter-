# Flutter API Audit — Canlifal Mobile

Sürüm: **1.0.331+367**  
Kaynak: `mobile/lib/core/network/api_endpoints.dart` + `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`  
Tarih: **2026-08-21**

## Özet

| Metrik | Değer |
|--------|------:|
| `ApiEndpoints` tanımları | **~200+** (const + dynamic path) |
| Flutter dosyalarında referans | **~860** unique path/string |
| Remote datasource dosyaları | **51** |
| Repository impl | **37** |
| Base URL | `https://canlifal.com` |
| Auth | JWT Bearer (`/api/auth/mobile-*`, `/api/me`) |

## HTTP katmanı

| Bileşen | Dosya | Rol |
|---------|-------|-----|
| Primary Dio | `core/network/dio_provider.dart` | Interceptors, refresh, cookies |
| Auth public Dio | `auth_service_provider.dart` | Login/register (no Bearer) |
| SSE Dio | `base_sse_service.dart`, `sse_client.dart` | EventSource streams |
| Upload Dio | `cloud_upload_service.dart` | PUT uploads |

**Duplicate risk (P2):** 7+ ayrı Dio factory — psychic SSE, PK SSE, upload, refresh-only. Interceptor tutarsızlığı riski; birleştirme büyük refactor — raporlandı, bu aşamada değiştirilmedi.

## SSE endpointleri (kılavuz §5)

| Stream | Path pattern | Service |
|--------|--------------|---------|
| Voice room | `/api/chat/rooms/{id}/stream` | `ChatRoomSseService` |
| Live video | `/api/live/streams/{id}/stream` | `VideoStreamSseService` |
| Notifications | `/api/notifications/stream` | `NotificationsSseService` |
| DM messages | `/api/messages/{id}/stream` | `MessageSseService` |
| Fortune | fortune stream endpoints | `FortuneSseService` |
| PK match | PK SSE paths | `PkMatchSseService` |
| Psychic | session SSE | `PsychicRoomSseService`, `PsychicIncomingSseService` |

Hub: `SseConnectionHub` — voice + video ref-counted; logout'ta `dispose()` eklendi (Aşama 12 fix).

## Endpoint tablosu (örnek — tam liste `api_endpoints.dart`)

| METHOD | PATH | AUTH | FLUTTER SERVICE | SCREEN / FEATURE | STATUS |
|--------|------|------|-----------------|------------------|--------|
| POST | `/api/auth/mobile-login` | public | `AuthRemoteDataSource` | Login | USED |
| POST | `/api/auth/mobile-refresh` | refresh token | `dio_provider` interceptor | global | USED |
| GET | `/api/me` | JWT | `AuthRemoteDataSource` | boot | USED |
| GET | `/api/mobile/home` | JWT | `HomeRemoteDataSource` | Home | USED |
| GET | `/api/messages` | JWT | `MessagesRemoteDataSource` | Messages | USED |
| GET | `/api/notifications` | JWT | `NotificationsRemoteDataSource` | Notifications | USED |
| GET | `/api/notifications/unread` | JWT | `NotificationsRemoteDataSource` | badge | PARTIAL (404 fallback) |
| GET/PATCH | `/api/chat/rooms/{id}` | JWT | `ChatRoomRemoteDataSource` | Voice room | USED |
| POST | `/api/chat/rooms/{id}/presence` | JWT | `ChatRoomRemoteDataSource` | Voice join/leave | USED |
| GET | `/api/chat/rooms/{id}/stream` | JWT SSE | `ChatRoomSseService` | Voice realtime | USED |
| GET | `/api/live/streams` | JWT | `LiveRemoteDataSource` | Live hub | USED |
| POST | `/api/gifts/send` | JWT | `LiveGiftsRemoteDataSource` | Gift overlay | USED |
| GET | `/api/games` | JWT | `GameRemoteDataSource` | Games | USED |
| GET | `/api/fortune-tellers` | JWT | `LivePsychicsRemoteDataSource` | Canlı falcılar | USED |
| GET | `/api/social/posts` | JWT | `SocialRemoteDataSource` | Social feed | USED |
| GET | `/api/stories` | JWT | `FeedRemoteDataSource` | Feed/Stories | USED |

> Tam envanter: `mobile/lib/core/network/api_endpoints.dart` — her sabit için `rg ApiEndpoints.<name> lib/` ile kullanım doğrulanabilir.

## UNUSED IMPORTANT ENDPOINTS (backend dokümanında önemli, mobilde yok veya kısmi)

1. **`/api/notifications/unread`** — tanımlı; bazı ortamlarda 404 → liste fallback (Aşama 11 branch'te API provider var, main'de kısmi)
2. **Gizlilik ayarları REST** — settings toggle'ları local-only
3. **`/api/games/sos/*`** — endpoint tanımlı, datasource kullanımı sınırlı/eksik (SOS oyun modu)
4. **Celebrity/blog endpoints** — `api_endpoints.dart`'ta var, aktif feature yok (dead path risk P3)

## Dokümantasyon uyumu

| Doküman | Durum |
|---------|-------|
| `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` | **Tek kaynak** — mobil path/body buraya uygun |
| `sesli-sohbet-api-dokumantasyonu.md` | Arka plan; çelişkide kılavuz geçerli |
| `FLUTTER_API_DOCS.md` | Legacy |

## Cache policy (GET)

| Veri | Cache | Invalidation |
|------|-------|--------------|
| Home sections | `CacheFirstLoader` | login, pull-refresh |
| Notifications list | 10 min + local read prefs | mark read, logout clear |
| Conversations | per-user key | send message, logout |
| Wallet/profile | short TTL / force refresh | purchase, gift send |
| Room state | **no stale** | join, SSE event, leave |
| Seat/participants | backend canonical | SSE presence |

## Aşama 12 değişiklikleri

- Logout → `SseConnectionHub.dispose()` + provider invalidation
- TRTC `_activeSession` global guard
- DM poll scope reduction (call signal scan)

## DEĞİŞEN DOSYALAR (audit fix)

- `mobile/lib/core/bootstrap/user_session_cleanup.dart`
- `mobile/lib/features/auth/presentation/providers/auth_providers.dart`
- `mobile/lib/features/trtc/presentation/trtc_room_manager.dart`
- `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`
- `mobile/lib/features/messages/presentation/widgets/dm_realtime_listener.dart`
- `mobile/lib/features/messages/data/hidden_conversations_store.dart`
- `mobile/lib/features/messages/data/deleted_messages_store.dart`
- `mobile/lib/features/notifications/data/repositories/notifications_repository_impl.dart`
