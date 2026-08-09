# Canlifal Backend API Inventory

Date: 2026-08-08

Scope:

- Production source of truth: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`
- Local mirror implementation: `api/src/**`
- This file lists implemented local mirror routes and the production-aligned adapters added for Flutter verification.

## Route mounts

| Base path | Implementation | Notes |
|---|---|---|
| `/api/auth` | `api/src/routes/auth.ts`, `auth_mobile.ts` | Mobile JWT, refresh tokens, session list |
| `/api/users`, `/api/user`, `/api/me` | `users.ts`, `profileExtras.ts`, `userFlutterApi.ts`, `wallet.ts` | Profile, stats, wallet aliases |
| `/api/social/posts` | `socialPosts.ts` | Posts, likes, comments, page pagination |
| `/api/chat/rooms` | `chat_rooms.ts` | Voice rooms, messages, presence, seats, music, SSE |
| `/api/video-streams` | `video_streams.ts`, `gifts.ts` | Live stream lifecycle, SSE, stream gifts |
| `/api/trtc` | `trtc.ts`, `live_field.ts` | `/usersig`; production-compatible `/token` adapter |
| `/api/live` | `live_field.ts`, `live_fal_requests.ts` | Compound room lifecycle, seats, gifts, PK, live-fal aliases |
| `/api/pk` | `pk_battles.ts` | Prisma PK battle service |
| `/api/gifts` | `gifts.ts` | Gift catalog and send logic |
| `/api/short-videos` | `short_videos.ts` | Cursor-paginated shorts + R2/local media |
| `/api/notifications` | `notifications.ts` | Notification list/read/payment clear |
| `/api/music` | `music.ts` | YouTube-backed music search |
| `/api/games` | `games.ts` | Game rooms/stubs |

## P0 production-compatible adapters

| Method | Path | Auth | Request | Response | Real implementation |
|---|---|---|---|---|---|
| POST | `/api/trtc/token` | Bearer | `{ roomId, role? }` | `{ success, data: { sdkAppId, userId, userSig, roomId, expireTime, role } }` | `api/src/routes/live_field.ts` + `generateTrtcUserSig` |
| POST | `/api/live/create-room` | Bearer | `{ title?, description?, category?, thumbnailUrl?, coverUrl? }` | `{ success, data: { stream, room, trtc } }` | `live_field.ts` + `liveStreamStore` |
| POST | `/api/live/join-room` | Bearer | `{ roomId, roomType: "voice"|"stream", nickname? }` | compound `{ room, trtc, user, participants, seats, giftRanking, pkStatus }` | `live_field.ts` + voice/live stores |
| POST | `/api/live/leave-room` | Bearer | `{ roomId, roomType }` | `{ message, roomId, viewerCount? }` | `live_field.ts` |
| POST | `/api/live/heartbeat` | Bearer | `{ roomId, roomType }` | `{ onlineCount, staleRemoved, serverTime }` | `live_field.ts` |
| GET | `/api/live/rooms` | Optional | `type,page,limit,search?` | `{ rooms, items, pagination }` | `live_field.ts` |
| GET/POST | `/api/live/seats` | Optional/Bearer | `roomId`, `{ action, seatIndex?, targetUserId? }` | `{ roomId, seats }` | `live_field.ts` + `assignSeat` |
| POST | `/api/live/gift/send` | Bearer | `{ roomId, roomType, giftTypeId|giftId, recipientId?, quantity }` | existing gift send result | `sendRoomGift` / `sendStreamGift` |
| GET | `/api/live/gift-types` | Optional | none | `{ giftTypes }` | Prisma `Gift` |
| GET/POST | `/api/live/pk` | Bearer | `roomId` / `{ action, roomId, targetRoomId, battleId? }` | `{ battle }` | `pkBattleService` |

## Existing realtime endpoints

| Method | Path | Auth | Events |
|---|---|---|---|
| GET | `/api/chat/rooms/{roomId}/stream` | Optional | `connected`, `presence`, `message`, `dj`, song events |
| GET | `/api/video-streams/{streamId}/stream` | Optional | messages, viewer count, fortune request, PK, heartbeat |
| GET | `/api/fortune-tellers/sessions/stream` | Bearer | `fortune_session_invite`, ping |
| GET | `/api/admin/payments/stream` | Staff | payment queue updates |

## Data model groups

| Domain | Prisma models |
|---|---|
| Auth/profile | `User`, `RefreshToken`, `Follow` |
| Social | `SocialPost`, `SocialPostLike`, `SocialPostComment`, `SocialFortunePost` |
| Gifts | `Gift`, `GiftEvent` |
| Wallet/payment | `CfcSettings`, `CfcPaymentRequest`, `PaymentAuditLog` |
| Push/notifications | `DevicePushToken`, `AppNotification` |
| Messages | `Conversation`, `DirectMessage` |
| PK | `PKBattle`, `PKParticipant`, `PKGift`, `PKResult` |
| Shorts | `ShortVideo`, `ShortVideoLike`, `ShortVideoComment`, `ShortVideoView`, `ShortVideoSave` |
| Music | `RoomSongQueue`, `RoomCurrentSong`, `RoomSongHistory`, `MusicQueue`, `MusicActionLog` |
| Voice economy | `VoiceRoom`, `VoiceRoomSettings`, `VoiceRoomFinanceAuditLog` |

## Backend requirements still needing production confirmation

- Whether production accepts `/api/v1/*`. Flutter now defaults to documented `/api/*`; `/api/v1` remains opt-in.
- Exact production event list for `/api/video-streams/{id}/stream` and `/api/chat/rooms/{id}/stream`.
- Exact production semantics for `/api/live/pk/score`; local mirror keeps gift-driven PK scoring authoritative.
- Missing production-only surfaces not represented in local mirror: full admin CMS, agency/blog/fan-club/ads/Stripe-like systems.
