# Canlifal Web ↔ Flutter API Parity Report

Tarih: 2026-06-09

## Kapsam

Bu rapor Canlifal.com web uygulamasi ile Flutter uygulamasindaki API
entegrasyonlarini karsilastirir.

Kaynaklar:

- Uretim envanteri: `https://canlifal.com/canlifal-envanter-raporu.txt`
- Flutter endpoint katalogu: `mobile/lib/core/network/api_endpoints.dart`
- Flutter HTTP/token katmani: `mobile/lib/core/network/dio_provider.dart`
- Flutter datasource/repository siniflari: `mobile/lib/features/**/data/**`
- Yerel API aynasi: `api/src/**`
- Deploy/parite dokumanlari: `docs/**`

Kisit:

- Gercek Next.js web kaynak kodu bu repoda yoktur.
- `api/` Express aynasi uretim web backend'inin tam kopyasi degildir.
- Yeni backend, yeni API veya yeni database tablosu olusturulmadi.

## Token ve hata yonetimi karsilastirmasi

| Alan | Web / backend sozlesmesi | Flutter durumu | Parite |
|---|---|---|---|
| Mobil auth | `POST /api/auth/mobile-register`, `/mobile-login`, `/mobile-google`, `/mobile-tiktok`, `/mobile-refresh` | `ApiEndpoints` + `AuthRemoteDataSource` / `NativeAuthDataSource` | Uyumlu |
| Web auth | NextAuth cookie/session | Flutter kullanmaz; mobil JWT kullanir | Bilerek farkli |
| Bearer token | `Authorization: Bearer <accessToken>` | `dio_provider.dart` otomatik ekler | Uyumlu |
| 401 refresh | Refresh endpoint ile tek kez token yenileme | `dio_provider.dart` refresh dener, basarisizsa storage temizler | Uyumlu |
| JSON error | `{ error/message }`, HTTP status | `ApiException.userMessage` ile map edilir | Uyumlu |
| 404 fallback | Production'da bazi route'lar eksik olabilir | Flutter kritik yerlerde fallback/alternatif path dener | Kismi |

## Web endpoint envanteri ve Flutter karsiligi

### Auth / session

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `POST /api/auth/[...nextauth]`, `POST /api/signup`, `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`, `POST /api/auth/change-password` | Mobilde NextAuth yerine JWT kullanilir; forgot-password var, reset/change native kismi | `features/auth`, `ApiEndpoints.authForgotPassword` | Web reset/change password native tam parite eksik |
| `POST /api/auth/mobile-register`, `/mobile-login`, `/mobile-google`, `/mobile-tiktok`, `/mobile-refresh`, `GET/PATCH /api/me` | Var | `auth_remote_datasource.dart`, `native_auth_datasource.dart`, `dio_provider.dart` | Yok |

### Kullanici / profil / takip

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik / hata |
|---|---|---|---|
| `GET /api/user/profile`, `PUT /api/user/profile`, `GET /api/users/:id`, `GET /api/users/lookup/:username`, `GET /api/users/search?q=` | Var | `profile_remote_datasource.dart`, `canlifal_user_api_datasource.dart`, `search_remote_datasource.dart` | Yok |
| `POST /api/user/:userId/follow`, `POST /api/users/:id/follow`, `GET /api/users/:id/followers`, `GET /api/users/:id/following`, `GET /api/user/followers`, `GET /api/user/following` | Var | `profile_remote_datasource.dart` | Onceki hatali `/api/users/:id/follow` liste denemesi duzeltildi; artik `/followers` |
| `GET /api/user/broadcast-history`, `GET/PATCH /api/user/activity` | Var; `/api/users/me/*` fallback var | `canlifal_user_api_datasource.dart` | Yok |

### Sosyal / hikaye

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `GET/POST /api/social/posts`, `POST /api/social/posts/:id/likes`, `GET/POST /api/social/posts/:id/comments`, `DELETE /api/social/posts/:id`, `POST /api/social/posts/auto-fortune` | Var | `features/social`, `feed_remote_datasource.dart` | Yok |
| `GET/POST /api/stories`, opsiyonel `/api/social/stories` | Kismi; feed/story strip temel veri kullanir | `feed_remote_datasource.dart`, `ApiEndpoints.feed`, `socialStories` | Story create/detail native parite kismi |

### Mesajlasma / DM

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `GET /api/messages`, `GET/POST /api/messages/:userId` | Var | `messages_remote_datasource.dart` | Yok |
| Legacy: `POST /api/messages/conversations`, `GET /api/messages/conversations`, `GET/POST /api/messages/conversations/:id/messages` | Fallback olarak var | `messages_remote_datasource.dart` | Realtime DM socket yok |

### Bildirim / push

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `GET /api/notifications`, `PATCH /api/notifications/:id/read`, `GET /api/notifications/unread` | Var; unread yoksa liste uzerinden hesaplanir | `notifications_remote_datasource.dart`, `home_remote_datasource.dart` | Yok |
| `POST /api/devices/fcm`, `POST /api/user/device-token` | Var; 404 sessiz gecilebilir | `push_registrar.dart` | Production endpoint smoke test gerekli |

### Cuzdan / jeton / CFC / uyelik

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `GET /api/user/credits`, `GET /api/wallet`, `GET /api/jeton`, `GET /api/payment/config`, `POST /api/payment/requests`, `GET /api/payment/requests` | Var | `profile_remote_datasource.dart`, `wallet`, `jeton_checkout_flow.dart`, `cfc_native_checkout.dart` | Yok |
| `GET/PATCH /api/admin/cfc-payment-requests`, `GET/POST /api/admin/cfc-settings`, `GET /api/admin/payment-requests`, `GET /api/admin/notifications` | Var / kismi admin hub | `features/admin` | Tam web admin panel yok |
| `GET /api/membership/packages`, `POST /api/membership/purchase` | Var, fallback katalog mevcut | `membership_remote_datasource.dart`, `premium_membership_page.dart` | Production endpoint smoke test gerekli |

### Sesli sohbet / chat rooms / muzik

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `GET /api/chat/rooms`, `POST /api/chat/rooms/create`, `GET/POST /api/chat/rooms/:id/messages`, `GET/POST/DELETE /api/chat/rooms/:id/presence`, `GET /api/chat/rooms/:id/stream` | Var | `live_remote_datasource.dart`, `chat_room_remote_datasource.dart`, `voice_room_sse_service.dart` | Yok |
| `GET/POST /api/chat/rooms/:id/dj`, `GET/POST /api/chat/rooms/:id/music-queue`, `POST /api/chat/rooms/:id/song-request`, `POST /api/chat/rooms/:id/music-queue/advance`, `DELETE /api/chat/rooms/:id/music-queue/:itemId`, `DELETE /api/chat/rooms/:id/music-queue`, `PATCH /api/chat/rooms/:id/music-settings` | Var | `chat_room_remote_datasource.dart`, `VoiceMusicHubPage`, `VoiceRoomDjPlayer` | Yok |
| `GET /api/music/search`, `GET /api/youtube/search`, `GET /api/chat/youtube-search`, `GET /api/chat/youtube-stream`, `GET /api/chat/youtube-audio`, `GET /api/chat/music/popular` | Var; fallback ve istemci stream resolver var | `chat_room_remote_datasource.dart`, `youtube_stream_resolver.dart` | Production stream route smoke test gerekli |
| `GET /api/chat/rooms/backgrounds`, `PATCH /api/chat/rooms/:id/background` | Var | `voice_room_background_catalog.dart`, `voice_room_hub_settings.dart` | Yok |
| Moderasyon: `/mute`, `/ban`, `/kick`, `/roles`, `/bans`, `/banned-words`, `/speak-request`, `/speak-requests` | Kismi/var | `chat_room_remote_datasource.dart`, voice room sheets | Tum web IRC/admin komutlari icin canli test gerekli |

### TRTC / LiveKit / canli yayin

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `POST /api/trtc/usersig` | Var | `trtc_remote_datasource.dart` | Yok |
| `POST /api/livekit/token` | Var fallback; production genelde TRTC | `livekit_remote_datasource.dart` | Yok |
| `GET/POST /api/video-streams`, `GET /api/video-streams/:id`, `POST /api/video-streams/:id/end`, `/live-started`, `/join`, `/leave`, `/messages`, `/like`, `/signal`, `/co-broadcast`, `/co-broadcast/invite` | Var | `live_remote_datasource.dart`, `live_stream_extras_datasource.dart` | Yok |
| `GET /api/video-streams/gifts`, `GET/POST /api/video-streams/:id/gifts`, `GET /api/video-streams/:id/gifts/leaderboard` | Var | `live_gifts_remote_datasource.dart`, `gift_repository.dart` | Yok |

### PK

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `POST /api/pk/battles`, `GET /api/pk/battles/:id`, `POST /api/pk/battles/:id/accept`, `/reject`, `/end`, `GET /api/pk/history`, `GET/POST /api/chat/rooms/:id/pk-battle`, `GET/POST /api/video-streams/:id/pk-battle` | Flutter istemci katmani var | `pk_battle_remote_datasource.dart`, `pk_battle_socket_service.dart` | Production route deploy/smoke test gerekli |

### Fal / tarot / kayitli fallar

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `POST /api/fortunes/*` tum fal turleri | Flutter katalog/okuma servisi var | `fortune_reading_service.dart`, `fortune_catalog.dart`, `fortune_session_page.dart` | Tum 28 endpoint birebir request/response model testi eksik |
| `GET/POST /api/user/fortunes`, `GET /api/user/fortunes/:id`, `GET/POST/DELETE /api/user/favorites` | Var/kismi | `fortune_remote_datasource.dart`, favorites datasources | Pin/rate tum web davranisi kismi |

### Home / kesfet / icerik

| Web endpointleri | Flutter kullanim durumu | Flutter dosyalari | Eksik servis |
|---|---|---|---|
| `GET /api/banners`, `/api/homepage-fortune-cards`, `/api/advisors/online`, `/api/games`, `/api/daily-rewards`, `/api/trend-videos` | Var | `home_remote_datasource.dart` | Yok |
| Blog/CMS: `/api/blog/*`, `/api/site-pages/*` | Link/katalog seviyesi | `content_hub`, `canlifal_web` | Native blog/CMS servisleri eksik |
| Rüya: `/api/dreams/*`, `/api/dream-symbols/*`, `/api/dream-contest/*` | Fal rüya yorum var; sozluk/yarismalar yok | `fortune` + content links | Native rüya servisleri eksik |
| Unluler/fan club: `/api/celebrities/*`, `/api/fan-clubs/*` | Link/katalog seviyesi | `content_hub`, home rows | Native servisler eksik |
| TMDB/football/TikTok/trend topics | Link/katalog veya home row | `home_site_catalog`, `content_hub` | Native servisler eksik |
| Ajans: `/api/agency/*` | Yok | Yok | Native ajans servisleri eksik |
| Oyunlar: `/api/games/*`, `/api/tournaments/*` | Home listesi var; tam oyun servisleri yok | `home_remote_datasource.dart` | Native oyun servisleri eksik |

## Socket / realtime API parity

| Sistem | Web/socket sozlesmesi | Flutter durumu |
|---|---|---|
| Sesli oda SSE | `GET /api/chat/rooms/:id/stream` payload: `connected`, `presence`, `message`, `dj` | Var: `VoiceRoomSseService` |
| Sesli oda Socket.IO mirror | `joinRoom`, `leaveRoom`, `gift`, `giftSent`, `chatMessage`, `message`, `roomMessage`, `dj`, `music`, `QUEUE_UPDATED`, `CURRENT_SONG_CHANGED`, `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` | Var/kismi: `VoiceRoomGiftSocket` |
| Canli yayin Socket.IO | `joinStream`, `leaveStream`, `gift`, `giftSent`, `streamMessage`, `chatMessage`, `message`, `viewerCount`, `viewerCountUpdated`, `streamEnded`, `STREAM_ENDED` | Var |
| PK Socket.IO | `pk:*`, `pkBattle`, `pkBattleUpdated`, `PK_UPDATED` | Var |
| TRTC | `POST /api/trtc/usersig` + SDK room events | Var |

## Request / response model parity

| Alan | Flutter model durumu | Risk |
|---|---|---|
| Auth user | `UserDto.fromApiMap`, aliases destekli | Dusuk |
| Social post/comment | DTO/freezed model var | Orta: web alanlari genisleyebilir |
| Messages | Conversation/message DTO var | Dusuk |
| Profile activity/broadcast | Alias ve fallback path var | Dusuk |
| Voice room messages/presence/DJ | Alias destekli entity parserlar var | Orta: production payload degisirse test gerekli |
| Music queue | `MusicQueueItem.fromJson` coklu alan alias okur | Dusuk |
| Live streams | `LiveStreamDto` + remote mapper var | Orta |
| Gifts | catalog mapper + fallback display var | Orta |
| PK | remote models var | Orta: production endpoint deploy durumu |
| Missing large modules | Blog, rüya sozlugu, games, agency, TMDB, football | Yuksek: native model/service yok |

## Hatalı endpoint kullanımı kontrolu

Son duzeltilen hata:

- `userPublicFollowers(userId)` artik `/api/users/{id}/followers`.

Bu turda yeniden taramada yeni guvenli endpoint hatasi bulunmadi.

## Eksik Flutter API servisleri

Yeni backend/API/DB eklemeden, mevcut web endpointleriyle eklenmesi gereken
Flutter servis gruplari:

1. `DreamRemoteDataSource`
   - `/api/dreams`, `/api/dream-symbols`, `/api/dream-contest`,
     `/api/dream-diary`, `/api/dream-stats`, `/api/weekly-dream-report`
2. `BlogRemoteDataSource`
   - `/api/blog`, `/api/blog/:slug`, comments/likes/favorites/categories
3. `CelebrityRemoteDataSource` / `FanClubRemoteDataSource`
   - `/api/celebrities/*`, `/api/fan-clubs/*`
4. `AgencyRemoteDataSource`
   - `/api/agency/*`
5. `GamesRemoteDataSource`
   - `/api/games/*`, `/api/tournaments/*`
6. `EntertainmentRemoteDataSource`
   - `/api/tmdb/*`, `/api/football/*`, TikTok/trend topic endpoints
7. `AchievementsRemoteDataSource`
   - `/api/user/achievements`, `/api/user/daily-tasks`
8. `AdminFullRemoteDataSource`
   - Web admin panelinin 50 sayfalik API kapsami; mobilde hangi bolumlerin
     native olacagi urun karari gerektirir.

## Test durumu

Son mobil kod degisikligi icin:

- Surum: `1.0.168+170`
- Workflow: <https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27239091897>
- `Dependencies`: basarili
- `Analyze`: basarili
- `Build release APK`: basarili
- `apk-latest`: yayinlandi

Bu rapor dokuman degisikligi olarak eklendi; yeni APK gerektirmez.

