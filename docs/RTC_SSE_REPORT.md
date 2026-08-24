# RTC and SSE Report

Date: 2026-08-08

## RTC decision

Tencent TRTC is the active mobile RTC system.

| Item | Status |
|---|---|
| Flutter SDK | `tencent_rtc_sdk` |
| Primary token endpoint | `POST /api/trtc/token` |
| Fallback endpoint | `POST /api/trtc/usersig` |
| Token generation | Backend only |
| Agora runtime | Not present in Flutter dependencies |
| LiveKit runtime | Not present in Flutter dependencies |

## Changes in this pass

- Added local mirror support for `POST /api/trtc/token`.
- Kept `/api/trtc/usersig` as fallback for older/self-hosted mirrors.
- Added `/api/live/join-room` compound response so Flutter receives TRTC credentials with room state in one request.

## SSE endpoints in use

| Endpoint | Purpose | Flutter service |
|---|---|---|
| `/api/chat/rooms/{roomId}/stream` | Voice room message/presence/DJ/song updates | `ChatRoomSseService` |
| `/api/video-streams/{streamId}/stream` | Live stream message/viewer/gift/PK/fortune events | `VideoStreamSseService` |
| `/api/fortune-tellers/sessions/stream` | Incoming live fortune sessions | `PsychicIncomingSseService` |
| `/api/room/{sessionId}/stream` | Live fortune room messages/timer/status | `PsychicRoomSseService` |
| `/api/pk/{matchId}/stream` | PK updates on games backend | `PkMatchSseService` |
| `/api/notifications/stream` | Notifications | `NotificationsSseService` |

## SSE client behavior

- Bearer token is sent for authenticated streams.
- `Last-Event-ID` is sent when available.
- 401 triggers token refresh then reconnect.
- Heartbeat watchdog reconnects stale streams.
- Reconnect uses bounded exponential backoff.
- Active voice/video SSE services are ref-counted through `SseConnectionHub`.

## Remaining risk

- Production event names must be frozen in backend docs before removing compatibility aliases.
- Socket.IO still exists as fallback for some live/voice/PK events; do not remove until production SSE coverage is proven.
- Discover screen tracks up to 12 voice room SSE streams; reduce or multiplex for battery/network savings.
