# Backend Flutter Parity Report

Date: 2026-08-08

Legend:

- OK: code paths are aligned in this repository.
- PARTIAL: working fallback exists, but production contract should be confirmed.
- FIXED: changed in this sync pass.
- BACKEND NEEDED: production backend data is required before Flutter can be finalized.

## P0 parity matrix

| Area | Status | Notes |
|---|---|---|
| Base URL | OK | Flutter defaults to `https://canlifal.com`. |
| API prefix | FIXED | Flutter no longer rewrites `/api/*` to `/api/v1/*` by default. |
| Bearer auth | OK | Main Dio attaches `Authorization: Bearer <accessToken>` except public auth paths. |
| Refresh token | OK | 401 triggers a single queued refresh with refresh-token rotation support. |
| Login/register | OK | Mobile auth request bodies match guide fields. |
| Apple/password reset/change | BACKEND NEEDED | Flutter has calls; local mirror does not implement all production extras. |
| `/api/trtc/token` | FIXED | Local mirror now implements production-compatible wrapper; `/usersig` remains fallback. |
| `/api/live/join-room` | FIXED | Local mirror now returns compound room/TRTC/participants/seats/giftRanking/PK payload. |
| `/api/live/leave-room` | FIXED | Voice and stream cleanup adapters added. |
| `/api/live/heartbeat` | FIXED | Adapter returns online count and server time. |
| Voice room presence | OK | Existing `/api/chat/rooms/{id}/presence` remains canonical; live adapter reuses it. |
| Voice room SSE | OK | Backend sends connected/presence/message/dj/song events; Flutter parses via SSE services. |
| Live stream SSE | PARTIAL | Local mirror emits stream events; production exact event taxonomy should be frozen. |
| Seats | PARTIAL | `take/force/swap` need production semantics; local adapter covers basic take/leave shape. |
| PK | PARTIAL | Uses Prisma PK service; `/api/live/pk/score` remains gift-driven in local mirror. |
| Gifts | OK | Gift send delegates to existing backend gift transaction logic; Flutter does not compute jeton. |
| Social feed | OK | page/limit contract present. |
| Shorts | OK | cursor/limit contract present. |
| CDN/media | PARTIAL | R2/local fallback present; production CDN host and signed URL policy should be confirmed. |
| Cache | OK | Sensitive token/payment/stream endpoints are excluded from GET cache. |

## Critical mismatches fixed

1. `/api` endpoints were rewritten to `/api/v1` by default.
2. Flutter primary TRTC token endpoint returned 404 on local mirror.
3. Flutter live compound APIs returned 404 on local mirror.
4. Flutter live room join had to fetch room/TRTC/presence/seats/ranking separately; local mirror now supports compound payload.
5. `/api/live/gift/send` now delegates to authoritative gift transaction functions.
6. `/api/live/rooms` now exposes a combined voice/stream discovery shape for Flutter inventory tests.

## Backend-needed list for production handoff

The following should be collected from production backend before claiming full 100% parity:

1. Exact route availability for `/api/v1/*`; current Flutter default follows documented `/api/*`.
2. Exact `/api/live/pk/score` behavior, if manual score updates are allowed outside gift events.
3. Full event names and payload schemas for every SSE stream.
4. Full seat action matrix: `take`, `leave`, `swap`, `force`, admin owner auto-seat behavior.
5. Apple auth, reset-password, change-password, device verify/reclaim endpoint contracts.
6. Production CDN/R2 public URL policy for avatars, gift videos, shorts, thumbnails, audio.
7. Production notification unread counter contract, if separate from notification list.
8. Production admin/payment webhook contracts not represented in local mirror.

## Next engineering order

1. Auth datasource dedupe.
2. SSE stack consolidation into `BaseSseService` + hub.
3. Voice room controller split by state slice.
4. Remove/rename remaining Agora labels.
5. Reduce discover SSE max or multiplex server-side.
