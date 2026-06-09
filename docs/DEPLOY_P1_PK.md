# P1 Deploy — PK Battle API (genişletilmiş)

Parite raporu **#4** — prod'da kalan ana gap.

## Durum

| Endpoint | Prod | Flutter |
|----------|------|---------|
| `GET /api/pk/history` | ❌ 404 | ✅ |
| `POST /api/pk/battles` | ❌ 404 | ✅ |
| `GET/POST /api/pk/battles/:id/*` | ❌ 404 | ✅ |
| `GET/POST /api/chat/rooms/:id/pk-battle` | ❌ 404 | ✅ |
| `GET/POST /api/video-streams/:id/pk-battle` | ❌ 404 | ✅ |
| Socket.IO PK olayları | web'de var | ✅ `pk_battle_socket_service.dart` |

## Deploy paketi

Tüm dosyalar: **`docs/nextjs/pk/`**

| Belge | İçerik |
|-------|--------|
| [pk/README.md](./nextjs/pk/README.md) | Özet ve test curl |
| [pk/COPY_MANIFEST.md](./nextjs/pk/COPY_MANIFEST.md) | Kopyalanacak dosya listesi |
| [pk/PK_PRISMA_SCHEMA.prisma](./nextjs/pk/PK_PRISMA_SCHEMA.prisma) | 4 model |
| [pk/SOCKET_EVENTS.md](./nextjs/pk/SOCKET_EVENTS.md) | Socket kanalları ve payload |
| [pk/routes/*.ts](./nextjs/pk/routes/) | 8 App Router route referansı |
| [pk/lib/pkRouteHelpers.ts](./nextjs/pk/lib/pkRouteHelpers.ts) | `pkOk` / `pkFail` |

Kaynak implementasyon (mirror): `api/src/lib/pkBattleService.ts`, `api/src/routes/pk_battles.ts`

## Adımlar

1. Prisma modellerini ekle → `npx prisma migrate deploy`
2. `pkBattleService.ts` + `pkCache.ts` kopyala
3. `pk_battles.ts` içindeki `handleVoiceRoomPkAction`, `handleLiveStreamPkAction`, `broadcastPkResult` → `pkBattleHandlers.ts`
4. Route dosyalarını `app/api/` altına yerleştir
5. Socket sunucusuna `emitPkBattleEvent` ekle (`giftHub.ts` referans)
6. Hediye gönderiminde `recordPkGift` hook'u
7. `bash scripts/verify-pk-endpoints.sh`

## Yanıt şeması (Flutter uyumlu)

```json
{
  "success": true,
  "battle": {
    "id": "cm...",
    "battleType": "voice_room",
    "status": "pending",
    "challengerScore": 0,
    "opponentScore": 0,
    "leftScore": 0,
    "rightScore": 0,
    "secondsLeft": 300,
    "durationSeconds": 300,
    "targetScore": 150000,
    "voiceRoomId": "...",
    "opponentVoiceRoomId": "...",
    "challenger": { "userId": "...", "score": 0, "displayName": "..." },
    "opponent": null
  },
  "pk": { }
}
```

`pk` alanı `battle` ile aynı nesne (geriye dönük).

## Oda PK — POST gövdesi

```json
{
  "action": "create",
  "opponentRoomId": "cm...",
  "durationSeconds": 300,
  "targetScore": 150000
}
```

`action`: `create` | `accept` | `reject` | `end` — `battleId` gerekirse ekleyin.

## Doğrulama

```bash
bash scripts/verify-pk-endpoints.sh
curl -s -o /dev/null -w "%{http_code}\n" https://canlifal.com/api/pk/history
# Deploy sonrası: 200
```
