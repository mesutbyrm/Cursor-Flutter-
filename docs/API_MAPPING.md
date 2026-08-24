# CanliFal Backend Contract Audit — API Mapping

**Generated:** 2026-08-04  
**Sources:** `api/` (Express mirror), `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`, `mobile/lib/core/network/api_endpoints.dart`  
**Production reference:** `https://canlifal.com` (~384 API routes, 149 Prisma models per envanter)

> The local `api/` mirror is **not** a full copy of production. Flutter targets production via `api_endpoints.dart`. This document maps all three layers and highlights gaps.

---

## Summary

| Layer | Count | Notes |
|-------|------:|-------|
| API mirror route handlers | **251** | 25 route files + `index.ts` |
| Prisma models (mirror) | **36** | Subset of production schema |
| Integration guide §9 endpoints | **172** | Unique path patterns |
| Flutter `api_endpoints.dart` | **~437 path literals** / **458** `static` members | Parameterized helpers add more runtime URLs |
| Guide §9 → Flutter gaps (real) | **~5** | See §5 |
| API mirror → Flutter gaps | **22** | See §6 |

---

## 1. API Mirror Routes (grouped by domain)

Mount prefixes from `api/src/index.ts`. Legacy duplicate: `/api/v1/auth`, `/api/v1/users`, `/api/v1/*` (social).

### Index (direct)

| Method | Path |
|--------|------|
| GET | `/api/youtube/search` (deprecated; use `/api/music/search`) |

### Auth — `auth.ts` → `/api/auth` (8)

| Method | Path |
|--------|------|
| GET | `/api/auth/me` |
| POST | `/api/auth/register` |
| POST | `/api/auth/login` |
| POST | `/api/auth/google` |
| POST | `/api/auth/tiktok` |
| POST | `/api/auth/refresh` |
| POST | `/api/auth/logout` |
| POST | `/api/auth/logout-all` |

### Auth (Mobile) — `auth_mobile.ts` → `/api/auth` (10)

| Method | Path |
|--------|------|
| POST | `/api/auth/mobile-register` |
| POST | `/api/auth/mobile-login` |
| POST | `/api/auth/mobile-google` |
| POST | `/api/auth/mobile-tiktok` |
| POST | `/api/auth/mobile-refresh` |
| POST | `/api/auth/forgot-password` |
| POST | `/api/auth/mobile-send-verification` |
| POST | `/api/auth/mobile-verify-email` |
| GET | `/api/auth/mobile-sessions` |
| DELETE | `/api/auth/mobile-sessions/:id` |

### Users — `users.ts` → `/api/users` (3)

| Method | Path |
|--------|------|
| GET/PATCH/DELETE | `/api/users/me` |

### Users / Profile — `profileExtras.ts` → `/api/users` (9)

| Method | Path |
|--------|------|
| GET | `/api/users/search` |
| GET | `/api/users/lookup/:username` |
| GET | `/api/users/me/stats` |
| GET | `/api/users/me/gifts-received` |
| GET | `/api/users/me/broadcast-history` |
| GET | `/api/users/me/activity` |
| PATCH | `/api/users/me/activity` |
| GET | `/api/users/:userId/followers` |
| GET | `/api/users/:userId/following` |

### User Flutter API — `userFlutterApi.ts` → `/api/user` (10)

| Method | Path |
|--------|------|
| GET | `/api/user/broadcast-history` |
| GET | `/api/user/co-broadcast-invites` |
| GET/PATCH | `/api/user/activity` |
| GET/POST | `/api/user/fortunes` |
| GET | `/api/user/fortunes/:fortuneId` |
| GET/POST | `/api/user/favorites` |
| DELETE | `/api/user/favorites/:id` |

### Wallet / Payment / Admin — `wallet.ts` → `/api` (21)

| Method | Path |
|--------|------|
| GET | `/api/me` |
| GET | `/api/referral` |
| GET | `/api/user/credits` |
| GET | `/api/wallet` |
| GET | `/api/jeton` |
| GET/POST/PATCH | `/api/payment/requests` |
| GET | `/api/payment/config` |
| GET/POST | `/api/membership/packages`, `/api/membership/purchase` |
| GET/POST | `/api/admin/cfc-settings` |
| GET/PATCH | `/api/admin/cfc-payment-requests` |
| GET | `/api/admin/payment-requests` |
| GET | `/api/admin/payment-notifications` |
| GET | `/api/admin/payments/stream` (SSE) |
| POST | `/api/admin/payment-requests/dismiss-pending` |
| GET | `/api/admin/notifications` |
| POST | `/api/admin/bootstrap` |

### Voice Room Settings — `voice_room_settings.ts` → `/api` (5)

| Method | Path |
|--------|------|
| GET | `/api/platform/voice-room-settings` |
| GET | `/api/platform/commission-rate` |
| GET/POST | `/api/admin/voice-room-settings` |
| GET | `/api/admin/voice-room-finance-audit` |

### Social / Fortune / Home — `social.ts` → `/api` (24)

| Method | Path |
|--------|------|
| GET | `/api/trend-videos` |
| GET | `/api/video-streams` (list alias) |
| GET | `/api/announcements` |
| GET | `/api/public-stats` |
| GET/POST | `/api/fortune-tellers/*` (list, detail, apply, my-profile, toggle-online, session, sessions, incoming) |
| GET | `/api/fortune-tellers/sessions/stream` (SSE) |
| PATCH | `/api/fortune-tellers/sessions/:sessionId` |
| GET/POST | `/api/teller-chat/:sessionId` |
| GET | `/api/celebrities/posts/latest` |
| GET/POST/DELETE | `/api/users/:userId`, `/api/users/:userId/follow` |
| GET/POST | `/api/coins/balance`, `/api/coins/spend` |

### Home — `home.ts` → `/api` (4)

| Method | Path |
|--------|------|
| GET | `/api/banners` |
| GET | `/api/advisors/online` |
| GET | `/api/games` |
| GET | `/api/daily-rewards` |

### Social Posts — `socialPosts.ts` → `/api/social` (7)

| Method | Path |
|--------|------|
| GET/POST | `/api/social/posts` |
| POST | `/api/social/posts/auto-fortune` |
| POST | `/api/social/posts/:id/likes` |
| GET/POST | `/api/social/posts/:id/comments` |
| DELETE | `/api/social/posts/:id` |

### Gifts — `gifts.ts` (5)

| Mount | Method | Path |
|-------|--------|------|
| `/api/gifts` | GET | `/api/gifts/` (catalog) |
| `/api/video-streams` | GET | `/api/video-streams/gifts` |
| `/api/video-streams` | GET/POST | `/api/video-streams/:streamId/gifts` |
| `/api/video-streams` | GET | `/api/video-streams/:streamId/gifts/leaderboard` |
| `/api/chat` (via handlers) | GET/POST | `/api/chat/rooms/:roomId/gifts` |

**Mirror gap:** No `/api/gifts/send`, `/api/gifts/types`, `/api/gifts/recent-big` (production + guide §9.9).

### Video Streams — `video_streams.ts` → `/api/video-streams` (30)

CRUD, join/leave, messages, like, mute/ban, moderators, co-broadcast, fortune-requests, pk-battle, signal, **SSE** `/stream`.

### Chat Rooms / Voice — `chat_rooms.ts` → `/api/chat` (56)

Rooms CRUD, presence, seats, messages, mentions, bans, banned-words, background, gifts, pk-battle, speak-requests, DJ, **full music subsystem** (see §8), **SSE** `/rooms/:roomId/stream`, YouTube helpers.

**Mirror gaps vs guide §9.3:** No `/voice`, `/moderation`, `/settings`, `/typing`, `/transfer-ownership`, `/pk` (uses `/pk-battle` only), no `GET/PATCH /rooms/:roomId` detail.

### Messages / DM — `messages.ts` → `/api/messages` (9)

Peer DMs, conversations, typing. No conversation SSE `/stream` in mirror.

### Notifications — `notifications.ts` → `/api/notifications` (3)

| Method | Path |
|--------|------|
| GET | `/api/notifications/` |
| PATCH | `/api/notifications/:id/read` |
| DELETE | `/api/notifications/payment` |

**Mirror gap:** No `/api/notifications/stream` (SSE).

### Music — `music.ts` → `/api/music` (1)

| Method | Path |
|--------|------|
| GET | `/api/music/search` |

### TRTC / LiveKit

| Method | Path |
|--------|------|
| POST | `/api/trtc/usersig` |
| POST | `/api/livekit/token` |

### PK Battles — `pk_battles.ts` → `/api/pk` (6)

`/battles`, `/battles/:id`, accept/reject/end, `/history`.

### Live Fal — `live_fal_requests.ts` → `/api` (5)

`/live/fal-request/create`, update, complete, list, get by id.

### Games — `games.ts` → `/api` (14)

Games list, rooms, auto-match, room join/chat, leaderboard, history, profile, mini-scores, tournaments.

### Short Videos — `short_videos.ts` → `/api/short-videos` (14)

Feed, upload, like/save/share/view, comments, profile, user videos, **media** `/stream` (not SSE).

### Stories, Devices, Reports

| Domain | Routes |
|--------|--------|
| Stories | GET/POST `/api/stories/` |
| Devices | POST `/api/devices/fcm` |
| Reports | POST `/api/reports/` |

### API v1 (legacy)

| Method | Path |
|--------|------|
| GET | `/api/v1/health` |
| + | `/api/v1/auth/*`, `/api/v1/users/*`, `/api/v1/*` social |

### Socket.IO (not REST)

`initGiftSocket` on `/socket.io` — see §7.

---

## 2. Prisma Models (mirror)

**Total: 36 models** in `api/prisma/schema.prisma` (production: ~149).

| Domain | Models |
|--------|--------|
| **User & auth** | `User`, `RefreshToken`, `Follow`, `DevicePushToken` |
| **Social** | `SocialPost`, `SocialPostLike`, `SocialPostComment`, `SocialFortunePost` |
| **Fortune** | `UserFortune`, `UserFavorite`, `FortuneTeller` |
| **Gifts & economy** | `Gift`, `GiftEvent`, `CfcSettings`, `CfcPaymentRequest`, `PaymentAuditLog` |
| **Messaging** | `Conversation`, `DirectMessage`, `AppNotification` |
| **PK** | `PKBattle`, `PKParticipant`, `PKGift`, `PKResult` |
| **Short video** | `ShortVideo`, `ShortVideoLike`, `ShortVideoComment`, `ShortVideoSave`, `ShortVideoView` |
| **Music / voice room** | `RoomSongQueue`, `RoomCurrentSong`, `RoomSongHistory`, `MusicQueue`, `MusicActionLog`, `VoiceRoom`, `VoiceRoomSettings`, `VoiceRoomFinanceAuditLog` |

---

## 3. Integration Guide §9 — Repository Tables

Source: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9 (172 unique endpoints).

### 9.1 AuthRepository (9)

`mobile-login`, `mobile-register`, `mobile-google`, `mobile-tiktok`, `mobile-refresh`, `logout`, `change-password`, `forgot-password`, `reset-password`

### 9.2 UserRepository (33)

`/api/me`, `/api/user/profile`, credits, stats, followers/following, follow, block, achievements, xp, active-sessions, fortunes, activity, wallet, theme, daily-login, missions, received-gifts, likers, referral, profile-frames, users/online, users/search, presence, watch-ad

### 9.3 ChatRoomRepository (31 + SSE)

rooms, create, backgrounds, messages, presence, seats, voice, moderation, dj, typing, settings, gifts, music, music-queue, song-request, transfer-ownership, pk (invite/respond/end), **SSE stream**

### 9.4 LiveStreamRepository (28 + SSE)

video-streams CRUD, join/leave, comments, like, viewers, gifts, messages, mute/ban, moderators, signal, co-broadcast, fortune-requests, pk, **SSE stream**

### 9.5 FortuneRepository (17 + streaming)

`/api/fortunes/*` (kahve, tarot, burç, rüya, el, numeroloji, melek, aşk, aura, doğum haritası, evet-hayır, istihare, katina, kurşun), horoscope/daily, homepage-fortune-cards, fortune-access/check, fortune-request-types

### 9.6 FortuneTellerRepository (13 + SSE)

tellers, reviews, session, apply, my-profile, toggle-online, favorites, awards, gifts, sessions, **SSE sessions/stream**

### 9.7 LiveSessionRepository (8 + SSE)

`/api/room/{sessionId}` messages, tip, signal, **SSE stream**

### 9.8 NotificationRepository (2 + SSE)

list, mark read, **SSE stream**

### 9.9 GiftRepository (4)

`/api/gifts/types`, `/send`, `/recent-big`, `/check-reciprocal`

### 9.10 SocialRepository (10)

posts CRUD, likes, comments, view, user posts, stories

### 9.11 ShortVideoRepository (8)

list, detail, upload, like, comments, view, user videos

### 9.12 PaymentRepository (8)

credit-packages, payment-methods, payment config/requests, jeton, wallet, memberships, withdrawals

### 9.13 Other (27+)

search, agora, trtc, devices/fcm, upload, announcements, popups, leaderboards, homepage buttons/ticker, public-stats, trends, football, music/youtube search, celebrities, dreams, blog, translations, site-pages, broadcast-images, online-fal, membership-badges, ads

---

## 4. Flutter `api_endpoints.dart`

| Metric | Value |
|--------|------:|
| `static const` + `static String` helpers | **458** |
| Literal `/api/...` path strings | **~437** |
| Parameterized patterns (runtime) | **~290** unique path templates |

Flutter is **production-oriented**: includes admin, agency, PK unified API, live/TRTC, gifts CMS, short-video extended endpoints, and many aliases not present in the local mirror.

Key helpers: `fortuneReading(slug)`, `chatRoom*(roomId)`, `videoStream*(streamId)`, `liveFortuneRoom(sessionId)`, `pkMatch*(matchId)`.

---

## 5. Gaps: Guide §9 NOT in `api_endpoints.dart`

After pattern matching (`{id}` ↔ `$roomId` / function helpers):

| Endpoint pattern | Status |
|------------------|--------|
| `/api/broadcast-images` | **Missing** |
| `/api/football` | **Missing** |
| `/api/online-fal` | **Missing** |
| `/api/translations` | **Missing** |
| `/api/user/likers` | **Missing** |
| `/api/fortunes/*` (15 slugs) | Covered by `fortuneReading(slug)` |
| `/api/room/*` | Covered by `liveFortuneRoom*` helpers |
| `/api/chat/rooms/*` | Covered by `chatRoom*` helpers |
| `/api/video-streams/*` | Covered by `videoStream*` helpers |
| `/api/fortune-tellers/*/reviews` | Covered by `fortuneTellerReviews(tellerId)` |

**Action:** Add 5 missing constants or document as web-only / soft-fail.

---

## 6. Gaps: API Mirror NOT in Flutter

| Mirror path pattern | Notes |
|---------------------|-------|
| `/api/admin/bootstrap` | Internal bootstrap |
| `/api/auth/logout-all` | Flutter has single `logout` only |
| `/api/celebrities/posts/latest` | Not in Flutter |
| `/api/chat/youtube-search`, `/api/chat/youtube-audio` | Flutter has `chatYoutubeStream`, `musicSearch` |
| `/api/chat/rooms/*/youtube-search` | Room-scoped search |
| `/api/chat/rooms/*/bans` | Flutter uses `chatRoomBan` per user |
| `/api/chat/rooms/*/banned-words/*` | Flutter has `chatRoomBannedWord` |
| `/api/chat/rooms/*/music-queue/advance\|complete\|*` | Partial — Flutter has advance/complete/item helpers |
| `/api/chat/rooms/*/pk-battle` | Flutter uses `/pk` production path + `chatRoomPk` alias |
| `/api/coins/balance`, `/api/coins/spend` | Legacy coin API |
| `/api/gifts/gifts`, `/api/gifts/*/gifts*` | Mount artifact; Flutter uses `videoStreamGifts*` |
| `/api/live/fal-request/*` | Flutter has `liveFalRequest*` |
| `/api/membership/packages` | Flutter uses `/api/membership/plans` + `/api/memberships` |
| `/api/users/me`, `/api/users/me/gifts-received` | Flutter uses `/api/me`, `/api/user/received-gifts` |
| `/api/users/lookup/*` | Covered by `userLookup(username)` |

---

## 7. SSE Endpoints & Event Types

### 7.1 Documented (guide §5.1) — 5 production SSE endpoints

| Endpoint | Documented events |
|----------|-------------------|
| `GET /api/chat/rooms/{roomId}/stream` | `connected`, `message`, `presence`, `typing`, `gift`, `system`, `dj_update`, `pk` |
| `GET /api/video-streams/{streamId}/stream` | `connected`, `streamMessage`, `viewerCount`, `streamEnded`, `gift` |
| `GET /api/room/{sessionId}/stream` | `connected`, `message`, `timer_started`, `time_extended`, `session_ended` |
| `GET /api/fortune-tellers/sessions/stream` | `connected`, `session_request`, `session_cancelled` |
| `GET /api/notifications/stream` | `connected`, `notification` |

### 7.2 Implemented in API mirror

| Endpoint | Implemented events | Gap vs doc |
|----------|-------------------|------------|
| `/api/chat/rooms/:roomId/stream` | `connected`, `message`, `presence`, `dj` (+ song queue via `songQueueSse`) | No `typing`, `gift`, `system`, `pk` on SSE (gifts via Socket.IO) |
| `/api/video-streams/:id/stream` | `connected`, `streamMessage`, `viewerCount`, `streamEnded`, `fortune_request`, `pk` | No `gift` on SSE |
| `/api/fortune-tellers/sessions/stream` | `fortune_session_invite`, `ping` | Doc names differ (`session_request`) |
| `/api/admin/payments/stream` | `payment_update`, `ping` | Admin-only; not in guide §5 |
| `/api/notifications/stream` | — | **Not in mirror** |
| `/api/room/{sessionId}/stream` | — | **Not in mirror** |

### 7.3 Song queue SSE (`songQueueSse.ts`) — piggybacks on chat room stream

`song_started`, `song_paused`, `song_resumed`, `song_finished`, `queue_updated`, `song_removed`

### 7.4 Gift engine — Socket.IO (`giftHub.ts`)

**Join events (client → server):** `joinStream`, `leaveStream`, `joinRoom`, `leaveRoom`, `joinPk`, `leavePk`

**Emit events (server → client):**

| Channel | Event names |
|---------|-------------|
| Stream gifts | `gift`, `giftSent` |
| Stream chat | `streamMessage`, `chatMessage`, `message` |
| Viewers | `viewerCount`, `viewerCountUpdated` |
| Stream end | `streamEnded`, `STREAM_ENDED` |
| Fortune | `fortune_request`, `fal_request`, `live_fal_request` |
| PK | `pkBattle`, `pkBattleUpdated`, `PK_UPDATED`, dynamic `pk:*` |
| Voice room gifts | `gift`, `giftSent` |
| Voice room chat | `chatMessage`, `message`, `roomMessage` |
| DJ / music | `dj`, `music`, `QUEUE_UPDATED`, `CURRENT_SONG_CHANGED`, `roomVideo` |
| Presence | `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft` |

**Redis gift queue pub/sub:** `{ type: "queued", job: GiftQueueJob }` on `RedisKeys.pubsub.gift`

Flutter uses SSE as primary (guide §5); mirror supplements with Socket.IO for gifts/PK/DJ on local dev.

---

## 8. Music System Endpoints

### Guide §9.3 + Flutter `api_endpoints.dart`

| Purpose | Method | Path | Mirror |
|---------|--------|------|--------|
| YouTube search | GET | `/api/music/search` | ✅ |
| Legacy YouTube | GET | `/api/youtube/search` | ✅ (deprecated) |
| Popular tracks | GET | `/api/chat/music/popular` | ✅ |
| Room music state | GET/POST | `/api/chat/rooms/{id}/music` | ❌ mirror |
| Song request | POST | `/api/chat/rooms/{id}/song-request` | ✅ |
| Current song | GET | `/api/chat/rooms/{id}/current-song` | ✅ |
| FIFO queue | GET | `/api/chat/rooms/{id}/queue` | ✅ |
| Skip / pause / resume | POST | `.../skip`, `.../pause`, `.../resume` | ✅ |
| Remove from queue | DELETE | `.../song/{queueId}`, `.../queue` | ✅ |
| Legacy music-queue | GET/POST | `.../music-queue` | ✅ |
| Queue admin | POST | `.../music-queue/complete`, `.../advance` | ✅ |
| Queue item delete | DELETE | `.../music-queue/{itemId}` | ✅ |
| Music settings | PATCH | `.../music-settings` | ✅ |
| Search by query | POST | `.../music-request-by-query` | ✅ |
| Stream URL resolve | POST | `.../music-stream` | ✅ |
| DJ assign | GET/POST | `.../dj`, `.../dj/{userId}` | ✅ |
| YouTube proxy | GET | `/api/chat/youtube-stream` | ✅ |
| SSE (room stream) | GET | `.../stream` (+ song events) | ✅ |

**Prisma:** `RoomSongQueue`, `RoomCurrentSong`, `RoomSongHistory`, `MusicQueue`, `MusicActionLog`

---

## 9. Auth Endpoints (consolidated)

### Production / Guide (mobile JWT)

| Endpoint | Mirror | Flutter |
|----------|:------:|:-------:|
| POST `/api/auth/mobile-register` | ✅ | ✅ |
| POST `/api/auth/mobile-login` | ✅ | ✅ |
| POST `/api/auth/mobile-google` | ✅ | ✅ |
| POST `/api/auth/mobile-apple` | ❌ | ✅ (prod only) |
| POST `/api/auth/mobile-tiktok` | ✅ | ✅ |
| POST `/api/auth/mobile-refresh` | ✅ | ✅ |
| POST `/api/auth/logout` | ✅ | ✅ |
| POST `/api/auth/change-password` | ❌ | ✅ |
| POST `/api/auth/forgot-password` | ✅ | ✅ |
| POST `/api/auth/reset-password` | ❌ | ✅ |
| POST `/api/auth/mobile-send-verification` | ✅ | ✅ |
| POST `/api/auth/mobile-verify-email` | ✅ | ✅ |
| GET `/api/auth/mobile-sessions` | ✅ | ✅ |
| DELETE `/api/auth/mobile-sessions/:id` | ✅ | ✅ |
| POST `/api/auth/mobile/device-token` | ❌ | ✅ |
| GET/POST `/api/auth/verify-device`, `/reclaim-device` | ❌ | ✅ |
| GET `/api/me` | ✅ (wallet router) | ✅ |

### Legacy / self-hosted (mirror + Flutter)

`login`, `register`, `google`, `tiktok`, `refresh`, `logout-all`, `/api/auth/me`

### Token flow (guide §1)

1. `Authorization: Bearer <accessToken>` on protected routes  
2. 401 → `POST /api/auth/mobile-refresh` with `{ refreshToken }`  
3. Refresh fail → login screen  
4. Storage: `flutter_secure_storage`

---

## 10. Cross-layer gap matrix (high priority)

| Feature | Production (guide) | API mirror | Flutter |
|---------|-------------------|------------|---------|
| Gift send (`/api/gifts/send`) | ✅ | ❌ | ✅ |
| Gift types / recent-big | ✅ | ❌ | ✅ |
| Chat voice token | ✅ | ❌ | ✅ |
| Chat moderation/settings/typing | ✅ | ❌ | ✅ |
| Notification SSE | ✅ | ❌ | ✅ (`notificationsStream`) |
| Live session room SSE | ✅ | ❌ | ✅ |
| Fortune AI POST (streaming) | ✅ | ❌ | ✅ (`fortuneReading`) |
| Agora token | ✅ | ❌ | ✅ |
| Full admin panel | ✅ | partial | ✅ |

---

## References

- Integration guide: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`
- Flutter endpoints: `mobile/lib/core/network/api_endpoints.dart`
- API entry: `api/src/index.ts`
- SSE client spec: guide §5–6
- Gift socket: `api/src/socket/giftHub.ts`
- Song queue SSE: `api/src/lib/songQueueSse.ts`
