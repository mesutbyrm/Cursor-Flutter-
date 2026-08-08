# API Parity Final Report

Date: 2026-08-08

| Metric | Count |
|---|---:|
| Backend unique paths | 438 |
| Flutter normalized paths | 437 |
| Backend ↔ Flutter connected | 256 |
| Missing backend->Flutter normalized paths | 182 |
| Wrong/Flutter-only normalized paths | 181 |
| Deprecated risk paths | 3 |
| MCP tools | 10 |
| Flutter runtime MCP | 0 |

## Fixed

- PAYMENT: `/api/payment/*` production constants migrated to `/api/payments/*`.
- MEMBERSHIP: `/api/membership/*` production constants migrated to `/api/memberships/*`.
- GIFT: public JSON catalog fallback uses `/api/gifts/types`; `/api/gifts` page route is not parsed as JSON.
- MUSIC: skip uses canonical DELETE `/api/chat/rooms/{roomId}/music`; unsupported pause/resume no longer call fake endpoints.
- HEALTH: `/api/v1/health` literal removed; warmup uses `/api/warmup`.
- Regression tests added for canonical endpoint literals.

## Feature status

| Feature | Status | Notes |
|---|---|---|
| AUTH | PARTIAL | Mobile JWT code path connected; real device/session lifecycle still needs device validation. |
| PAYMENT | CONNECTED | Canonical paths set; real payment request requires production account flow. |
| MEMBERSHIP | CONNECTED | Canonical package/purchase paths set. |
| LIVE | PARTIAL | Paths connected; authorized broadcaster account/device required for runtime. |
| VOICE | PARTIAL | Presence REST tested; device/TRTC/SSE runtime still blocked. |
| TRTC | PARTIAL | `/api/trtc/token` verified with JWT; SDK device test blocked. |
| PK | PARTIAL | HTTP contracts connected; two-user event validation blocked. |
| GIFT | PARTIAL | Catalog fixed; send blocked by insufficient jeton on test accounts. |
| CHAT | CONNECTED | Chat room message/presence endpoints connected. |
| MUSIC | PARTIAL | Search and song request connected; payment/playback needs jeton/device test. |
| SOCIAL | CONNECTED | Feed endpoints connected; runtime scroll/perf not device-tested. |
| SHORTS | CONNECTED | Cursor endpoints connected; runtime memory/video controller device test blocked. |
| FAL | PARTIAL | Fortune endpoints present; live falcı two-user flow blocked. |
| PROFILE | CONNECTED | `/api/me`, profile/user paths connected. |
| NOTIFICATION | PARTIAL | List/read paths connected; push/device runtime blocked. |
