# Performance Before / After

Date: 2026-08-08

This report records measured/static evidence from this repository. Device metrics such as frame drops, cold start, CPU, memory, and live join time require an Android device or emulator and are not claimed here.

## Baseline risks before this pass

| Metric / area | Baseline finding |
|---|---|
| Startup API count | Auth restore can validate cached user and enrich profile in the background. |
| Post-login network burst | `invalidateAuthenticatedShellData` refreshes home, voice, live, social, wallet, profile stats, fortune access, and presence. |
| API path routing | `/api/*` was rewritten to `/api/v1/*` by default, causing broad 404 risk when backend only exposes `/api/*`. |
| Live join network count | Without `/api/live/join-room`, Flutter needed separate TRTC/state/presence/seats/gift-ranking calls or fallbacks. |
| Voice discover network | Up to 12 concurrent room SSE streams. |
| Duplicate realtime | SSE, Socket.IO, and REST polling coexist for some voice/live paths. |
| UI rebuild risk | Voice room state remains concentrated in one large controller. |
| Media memory | Shorts/video/gift preloading needs viewport discipline. |

## After this pass

| Area | Change | Expected effect |
|---|---|---|
| API path routing | `/api` is default again; `/api/v1` opt-in. | Removes version-prefix 404 class for documented production contract. |
| TRTC token | Local mirror implements `/api/trtc/token`. | Primary Flutter TRTC path works in mirror tests. |
| Live join | Local mirror implements compound `/api/live/join-room`. | Reduces live/voice join round trips when backend supports compound response. |
| Live leave/heartbeat | Local mirror adapters added. | Lifecycle tests can validate cleanup and heartbeat paths. |
| Live gifts | `/api/live/gift/send` delegates to existing gift transaction functions. | Prevents Flutter-side jeton math and duplicate transaction logic. |
| Live rooms | `/api/live/rooms` combines voice rooms and streams. | Discovery inventory tests can use one contract. |

## Metrics still requiring runtime measurement

- Cold start
- Warm start
- First screen render
- Average API latency
- Payload size
- Duplicate request count per screen
- Cache hit ratio
- Frame drops
- Memory/CPU under TRTC
- Voice room join time
- Live stream join time

## Next performance fixes

1. Cap discover SSE to visible rooms, or add backend multiplex stream.
2. Split `VoiceRoomLiveController` into presence/seats/music/gifts/PK notifiers.
3. Make login success refresh staged instead of invalidating all shell providers at once.
4. Remove legacy SSE client after all users migrate to `BaseSseService`.
5. Rename old Agora error labels to generic RTC/TRTC labels.
