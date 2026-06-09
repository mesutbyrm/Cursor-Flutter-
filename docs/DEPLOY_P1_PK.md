# P1 Deploy — PK Battle API

Parite raporu **#4**.

## Durum

| Endpoint | Prod | Flutter |
|----------|------|---------|
| `POST /api/pk/battles` | 404 | ✅ `pk_battle_remote_datasource.dart` |
| `GET /api/pk/battles/:id` | 404 | ✅ |
| `POST /api/pk/battles/:id/accept\|reject\|end` | 404 | ✅ |
| `GET /api/pk/history` | 404 | ✅ |
| `GET/POST /api/chat/rooms/:id/pk-battle` | 404 | ✅ sesli oda |
| `GET/POST /api/video-streams/:id/pk-battle` | ? | ✅ canlı yayın |

**Kaynak:** `api/src/routes/pk_battles.ts`, `api/src/lib/pkBattleService.ts`, Socket.IO `pkBattle` / `pkBattleUpdated` (`api/src/socket/giftHub.ts`).

## Deploy notu

PK sistemi tek route değil; **REST + Socket.IO** birlikte gerekir. canlifal.com web’de PK zaten çalışıyorsa Flutter uçları aynı path’leri kullanmalı — prod 404, muhtemelen route prefix veya App Router yapısı farklı.

Kontrol listesi:

1. `app/api/pk/battles/route.ts` — POST davet
2. `app/api/pk/battles/[id]/route.ts` — GET
3. `app/api/pk/battles/[id]/accept/route.ts` — POST
4. `app/api/pk/battles/[id]/reject/route.ts` — POST
5. `app/api/pk/battles/[id]/end/route.ts` — POST
6. `app/api/pk/history/route.ts` — GET
7. `app/api/chat/rooms/[roomId]/pk-battle/route.ts`
8. `app/api/video-streams/[streamId]/pk-battle/route.ts`
9. Socket.IO event’leri: `pkBattle`, `pkBattleUpdated`

## İstek gövdesi (davet)

```json
{
  "battleType": "voice_room",
  "voiceRoomId": "cm...",
  "opponentVoiceRoomId": "cm...",
  "durationSeconds": 300,
  "targetScore": 10000
}
```

Canlı yayın: `"battleType": "live_stream"`, `liveStreamId`, `opponentLiveStreamId`.

## Flutter

Ek APK gerekmez; endpoint’ler deploy edilince otomatik çalışır. Socket köprüsü: `pk_battle_socket_service.dart`.

## Doğrulama

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://canlifal.com/api/pk/history
# Deploy sonrası: 200
```
