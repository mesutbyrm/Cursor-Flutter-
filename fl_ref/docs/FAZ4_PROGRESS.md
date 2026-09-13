# Faz 4 + Admin (extra_main kapanış)

**Hedef:** Kalan 38 `extra_main` yolu (canlı fal alias, video-stream, platform, admin).

## Canlı fal (4)

| Flutter | Kanonik |
|---------|---------|
| `live/fal-request/create` | `video-streams/{streamId}/fortune-requests` POST |
| `live/fal-request/{id}/update` | fortune-requests PATCH |
| `live/fal-request/{id}/complete` | action `complete` |
| `live/fal-requests` | fortune-requests GET + `streamId` query |

## Video-stream (4)

| Flutter | Strateji |
|---------|----------|
| `moderator` | → `moderators` |
| `background`, `image` | → `[streamId]` PATCH |
| `gifts/leaderboard` | → `gifts` GET / insights fallback |

## Platform (9)

`fortune-access/settings` → `ip-status`; `consume` → `check` POST; `teller/gifts` → `fortune-tellers/gifts`; `teller/reviews` + `tellerId`; `gifts/display-settings`, `site-animations/active` → platform cache / manifest; `advisors/online` → `fortune-tellers`; `blog/recent` → `blog`; `tournaments/join` → `tournaments` POST.

## Admin (21)

Re-export / proxy: `cfc-payment-requests`, `animations/*`, `room-themes/backgrounds`, `ledger`, `chat-rooms`, `users/{id}/360` → `full`; boş liste stub: `gifts`, `rooms`, `streams`, `ads`; SSE stub: `payments/stream`.

`lib/video-stream-parity.ts`, `parity-live-fal-handlers.ts`, `parity-faz4-misc-handlers.ts`, `parity-admin-handlers.ts`.

Durum ve telefon notu: `fl_ref/docs/BACKEND_PARITY_STATUS.md`. Üretim merge Cloud Agent / backend repo ortamında.
