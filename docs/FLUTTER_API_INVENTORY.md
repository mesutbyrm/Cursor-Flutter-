# Canlifal Flutter API Inventory

Date: 2026-08-08

Scope: `mobile/lib/**`, `mobile/pubspec.yaml`, API contract files.

## API configuration

| Concern | Implementation |
|---|---|
| Base URL | `mobile/lib/core/config/env.dart` -> default `https://canlifal.com` |
| Endpoint registry | `mobile/lib/core/network/api_endpoints.dart` |
| API prefix behavior | `mobile/lib/core/config/api_config.dart`; `/api` by default, `/api/v1` only with `USE_API_V1=true` |
| Main Dio | `mobile/lib/core/network/dio_provider.dart` |
| Backend routing | `BackendRoutingInterceptor` + `ApiBackendRouter` |
| Auth token storage | `TokenStorage` with `flutter_secure_storage` |
| Auth refresh | `AuthTokenRefreshCoordinator`, one in-flight refresh queue |
| GET cache | `ApiCacheInterceptor` + `ApiCachePolicy` + `ApiCacheStore` |
| Retry | GET-only controlled retry for timeout, 429, 5xx |

## Repository / datasource groups

| Domain | Main files | Endpoint groups |
|---|---|---|
| Auth | `features/auth/data/datasources/auth_service.dart`, `auth_remote_datasource.dart` | `/api/auth/mobile-*`, `/api/me`, sessions, email verification |
| Profile/wallet | `profile_remote_datasource.dart`, `canlifal_user_api_datasource.dart`, `wallet_remote_datasource_extended.dart` | `/api/users/*`, `/api/user/*`, `/api/wallet`, `/api/payment/*` |
| Home | `home_remote_datasource.dart`, `mobile_compound_remote_datasource.dart` | `/api/mobile/*`, banners, stats, advisors |
| Social | `social_remote_datasource.dart`, `social_repository_impl.dart` | `/api/social/posts`, stories, comments |
| Shorts | `shorts_remote_datasource.dart`, `short_video_upload_service.dart` | `/api/short-videos/*`, `/api/upload/*` |
| Notifications | `notifications_remote_datasource.dart`, `notifications_sse_service.dart` | `/api/notifications`, `/stream` |
| Messages | `messages_remote_datasource.dart`, `message_sse_service.dart` | `/api/messages`, conversations |
| Voice rooms | `chat_room_remote_datasource.dart`, `voice_rooms_discover_remote_datasource.dart` | `/api/chat/rooms/*`, `/api/live/*` compound fallback |
| Voice music | `room_music_remote_datasource.dart`, `room_song_remote_datasource.dart` | `/api/music/search`, room music queue/song request |
| Live streams | `live_remote_datasource.dart`, `live_api_remote_datasource.dart`, `live_field/*` | `/api/video-streams/*`, `/api/live/*` |
| Live fortune teller | `live_psychics_remote_datasource.dart`, psychic SSE services | `/api/fortune-tellers/*`, `/api/room/*`, `/api/live-fal/*` |
| TRTC | `trtc_remote_datasource.dart`, `trtc_room_manager.dart`, `voice_trtc_engine.dart` | `/api/trtc/token`, fallback `/api/trtc/usersig` |
| PK | `live/data/pk/*`, `pk_battle_remote_datasource.dart` | `/api/pk/*`, `/api/live/pk`, `/api/chat/rooms/{id}/pk` |
| Gifts | `gift_repository.dart`, live/voice gift datasources | `/api/gifts`, `/api/live/gift-*`, stream/room gifts |
| Admin | `admin_remote_datasource.dart`, admin SSE | `/api/admin/*` |

## Realtime stack

| Stack | Status |
|---|---|
| SSE | Primary for chat room, video stream, notifications, PK, fortune teller sessions |
| Socket.IO | Secondary/backward-compatible bridge for live/voice gift and PK events |
| Tencent RTC | Active RTC path via `tencent_rtc_sdk` |
| Agora | No runtime SDK dependency; only old comments/error labels remain |
| LiveKit | No Flutter runtime client; local backend still exposes old token route |

## Cache and pagination

| Area | Current behavior |
|---|---|
| GET cache | Default 45s TTL, short TTL for wallet/live/chat, no cache for stream/token/payment/admin |
| Social | page/limit |
| Live streams | page/limit |
| Shorts | cursor/limit |
| Notifications | list fetch, no local unread endpoint dependency required |
| Images | `cached_network_image`, DPR-aware widgets, cache manager |
| Video | controller pool and warm cache for shorts/video media |

## Known duplicate / cleanup candidates

- `AuthService` and `AuthRemoteDataSource` overlap; keep one public auth service plus a small sessions datasource.
- `BaseSseService` and legacy `core/sse_client.dart` overlap; migrate remaining users to the hub.
- Socket.IO fallback exists beside SSE; retain only where production actually emits events.
- `VoiceRoomLiveController` remains too broad and should be split by presence/seats/music/gifts/PK.
- Legacy Agora names in errors should be renamed to RTC/TRTC to avoid support confusion.
