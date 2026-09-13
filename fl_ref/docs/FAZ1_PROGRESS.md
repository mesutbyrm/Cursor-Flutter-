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

**Paket içi EKSİK:** 98 − 9 = **89** (henüz `nextjs_space`’e kopyalanmadı).

## Faz 1b (sıradaki — `nextjs_space` içinde implement)

| Flutter yolu | Öneri |
|--------------|--------|
| `/api/messages/conversations/{}/messages` | `Conversation` + `DirectMessage` |
| `/api/messages/conversations/{}/stream` | SSE (mevcut chat-events lib) |
| `/api/messages/conversations/{}/typing` | presence / kısa TTL cache |
| `/api/messages/{}/{}` | legacy alias → peer messages |
| `/api/auth/mobile-sessions/{}` | `auth/sessions` ile hizala |
| `/api/user/daily-tasks` | görev modeli / `daily-rewards` |
| `/api/user/favorites` | kullanıcı favori tablosu |
| `/api/user/fortunes/{}/pin` | fal kaydı pin |
| `/api/user/fortunes/{}/rate` | fal puanlama |
| `/api/user/story` | hikâye CRUD |

Uygulama: `bash scripts/apply-backend-parity-to-nextjs.sh <nextjs_space>` sonra `yarn tsc && yarn build`.
