# Faz 2 — sesli oda / chat parite (paket)

**Hedef:** 18 `extra_main` yolu (`/api/chat/*` + `/api/platform/voice-room-settings`).

## Strateji

| Flutter yolu | Kanonik / proxy |
|--------------|-----------------|
| `music-settings` | → `settings` |
| `queue` | → `music-queue` GET, `song-request` POST |
| `join-seat` | → `seats` PATCH |
| `mute`, `kick`, `report`, `roles`, `bans/*` | → `moderation` |
| `banned-words`, `background` | → `settings` |
| `dj/*` | → `dj` |
| `messages/*` | → `messages` DELETE + query |
| `song/*` | → `music` |
| `music-request-by-query` | → `youtube-audio` / `song-request` |
| `speak-requests/*` | → `speak-requests/[targetUserId]/*` |
| `mentions` | mesaj listesi / boş dizi |
| `chat/music/popular` | cache + `youtube-audio` yedek |
| `platform/voice-room-settings` | `getCachedPlatformSetting` |

`lib/chat-room-parity.ts` — oda proxy yardımcıları.

Uygulama sonrası: `yarn tsc --noEmit && yarn build`.
