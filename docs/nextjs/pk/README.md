# PK Battle — canlifal.com deploy paketi

Prod'da kalan **tek büyük API gap**: `/api/pk/*` ve oda/yayın PK uçları.

## Hızlı başlangıç

1. [COPY_MANIFEST.md](./COPY_MANIFEST.md) — dosya listesi
2. [PK_PRISMA_SCHEMA.prisma](./PK_PRISMA_SCHEMA.prisma) — migrate
3. `api/src/lib/pkBattleService.ts` + `pkCache.ts` → `lib/pk/`
4. `api/src/routes/pk_battles.ts` export'ları → `lib/pk/pkBattleHandlers.ts`
5. `pk/routes/*.ts` → `app/api/.../route.ts`
6. [SOCKET_EVENTS.md](./SOCKET_EVENTS.md) — Socket.IO
7. `bash scripts/verify-pk-endpoints.sh`

## Flutter sözleşmesi

| İşlem | HTTP |
|--------|------|
| Oda PK daveti | `POST /api/chat/rooms/:id/pk-battle` `{ action, opponentRoomId }` |
| Kabul / red / bitir | `POST .../pk-battle` veya `/api/pk/battles/:id/accept` |
| Aktif PK | `GET /api/chat/rooms/:id/pk-battle` |
| Geçmiş | `GET /api/pk/history` |
| Canlı yayın | `GET/POST /api/video-streams/:id/pk-battle` |

Yanıt: `{ success: true, battle: {...}, pk: {...} }` — alanlar `pk_battle_remote_models.dart` ile uyumlu.

## Test (JWT gerekli)

```bash
export CANLIFAL_JWT="..."
export ROOM_A="cm..."
export ROOM_B="cm..."

curl -s -X POST "https://canlifal.com/api/chat/rooms/$ROOM_A/pk-battle" \
  -H "Authorization: Bearer $CANLIFAL_JWT" \
  -H "Content-Type: application/json" \
  -d "{\"action\":\"create\",\"opponentRoomId\":\"$ROOM_B\",\"durationSeconds\":300}"
```
