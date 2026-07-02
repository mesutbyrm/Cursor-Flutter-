# Canlifal Redis Entegrasyonu

PostgreSQL + Prisma **değiştirilmedi**. Redis yalnızca önbellek, kuyruk ve gerçek zamanlı durum için kullanılır. Tüm mevcut API uçları ve Flutter sözleşmeleri korunur.

## Kurulum

`api/.env`:

```env
REDIS_URL=redis://127.0.0.1:6379
# İsteğe bağlı — çoklu instance
REDIS_INSTANCE_ID=api-1
```

Redis yoksa veya bağlantı koparsa sistem otomatik **bellek + PostgreSQL** moduna geçer; kullanıcıya hata dönmez.

## Modüller (`api/src/lib/redis/`)

| Modül | Amaç |
|--------|------|
| `client.ts` | node-redis bağlantısı, yeniden bağlanma, `kvGet`/`kvSet` fallback |
| `cache.ts` | `cacheGetOrSet` — önce Redis, yoksa loader + yaz |
| `presence.ts` | `online_users`, `user:{id}`, `room:{id}:users`, heartbeat 20s |
| `voiceRoomState.ts` | `room:{id}`, speakers/admins/listeners hash |
| `musicQueue.ts` | `music_queue:{roomId}` — LPUSH/RPUSH/BLPOP |
| `giftQueue.ts` | `gift_queue` Redis Stream + worker |
| `pubsub.ts` | chat, gift, room, music, notification kanalları |
| `rateLimit.ts` | login, message, gift, api — IP + userId |
| `shortsTrending.ts` | Sorted set trend skoru |
| `liveStreamMetrics.ts` | viewer/likes/comments/gifts sayaçları |
| `notificationQueue.ts` | Push bildirim kuyruğu |
| `session.ts` | Aktif oturum meta (JWT değişmez) |
| `aiCache.ts` | Fal sonucu kısa süreli cache |
| `bootstrap.ts` | Başlangıç + worker'lar |

## TTL

| Anahtar | TTL |
|---------|-----|
| Home feed | 60 sn |
| Trend videolar | 30 sn |
| Profil lookup | 5 dk |
| Oyun listesi | 60 sn |
| Presence heartbeat | 20 sn (×3 güvenlik) |
| AI fal cache | 120 sn |
| PK cache | 30 dk |

## Entegre route'lar

- `GET /api/banners`, `/advisors/online`, `/games`, `/daily-rewards` — cache
- `GET /api/trend-videos` — cache
- `GET /api/games` (multiplayer katalog) — cache
- `GET /api/users/lookup/:username` — profil cache
- Auth login/logout — session + presence
- Chat presence join/leave — Redis + `PATCH .../presence` heartbeat
- Müzik kuyruğu — Redis list mirror
- Hediyeler — Stream kuyruğu + rate limit
- Shorts like/view/share — trend sorted set

## Health

`GET /api/v1/health` → `{ redis: "connected" | "fallback" }`

## Üretim (canlifal.com)

Bu mirror (`api/`) üretim Next.js API ile aynı Redis anahtar sözleşmesini kullanacak şekilde tasarlandı. Üretim deploy'unda aynı `REDIS_URL` ve modüller paylaşılmalıdır.
