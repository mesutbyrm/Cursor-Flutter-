# Faz 1 — ilerleme (mobil çekirdek)

**Hedef:** 19 `extra_main` yolu (bildirim, kullanıcı, DM, auth).

## Bu repoda hazır (`backend-parity/`)

| Flutter yolu | Durum | Not |
|--------------|--------|-----|
| `/api/users/me/activity` | re-export | → `user/activity` |
| `/api/users/me/broadcast-history` | re-export | → `user/broadcast-history` |
| `/api/users/me/profile-visitors` | re-export | → `me/profile-visitors` |
| `/api/users/me/stats` | re-export | → `user/stats` |
| `/api/auth/mobile/device-token` | re-export | → `devices/fcm` |
| `/api/user/device-token` | re-export | → `devices/fcm` |
| `/api/notifications/unread` | yeni | Prisma `Notification` count |
| `/api/notifications/payment` | yeni | DELETE ödeme tipi bildirimler |
| `/api/notifications/{}/read` | yeni | PATCH/POST `isRead` |

**Paket içi (Faz 1 tamam):** **19 / 98** route dosyası — **EKSİK: 79** (henüz `nextjs_space`’e kopyalanmadı).

## Faz 1b — pakette hazır

| Flutter yolu | Durum |
|--------------|--------|
| `/api/messages/conversations` (+ alt uçlar) | proxy → `messages`, `messages/[userId]`, typing lib, SSE keepalive |
| `/api/messages/{}/{}` | DELETE `DirectMessage` |
| `/api/auth/mobile-sessions/{}` | DELETE → `auth/sessions?deviceId=` |
| `/api/user/daily-tasks` | re-export → `daily-missions` |
| `/api/user/story` | re-export → `stories` |
| `/api/user/favorites` (+ `[id]`) | `UserContentFavorite` + prisma snippet |
| `/api/user/fortunes/{}/pin` | `Fortune.isPinned` |
| `/api/user/fortunes/{}/rate` | `FortuneRating` upsert |

**Favoriler:** `backend-parity/prisma-additive/user_content_favorites.prisma.snippet` → `schema.prisma`’a ekleyip `prisma db push` (additive).

Uygulama: `bash scripts/apply-backend-parity-to-nextjs.sh <nextjs_space>` sonra `yarn tsc && yarn build`.

## Sıradaki — Faz 2

`/api/chat/rooms/*` (17) + `/api/chat/music/popular` + `/api/platform/voice-room-settings`.
