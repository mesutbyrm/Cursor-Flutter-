# PK Battle — Socket.IO olayları

Flutter: `pk_battle_socket_service.dart`  
Sunucu: `api/src/socket/giftHub.ts` → `emitPkBattleEvent`

## Oda / yayın kanalları

| Kanal | Join emit | Açıklama |
|-------|-----------|----------|
| Sesli oda | `joinRoom` `{ roomId }` | slug veya cuid |
| Canlı yayın | `joinStream` `{ streamId }` | video-stream id |
| PK | `joinPkBattle` `{ battleId }` | opsiyonel |

## Dinlenen olaylar (istemci)

`pk:invite`, `pk:accept`, `pk:reject`, `pk:start`, `pk:score-update`, `pk:gift`, `pk:end`, `pk:winner`, `pkBattle`, `pkBattleUpdated`, `PK_UPDATED`

## Payload şekli

```json
{
  "battle": { "id": "...", "status": "active", "challengerScore": 1200, ... },
  "pk": { "...": "battle ile aynı" },
  "event": "pk:score-update"
}
```

Flutter `PkBattleRemote.fromJson` hem `battle` hem kök nesneyi parse eder.

## Sunucu emit kuralları

1. Davet sonrası: `pk:invite` — her iki oda/yayın odasına
2. Kabul: `pk:accept` + `pk:start`
3. Hediye: `pk:gift` + `pk:score-update`
4. Bitiş: `pk:end` + `pk:winner`

Legacy alias: her emit'te ayrıca `pkBattle` ve `pkBattleUpdated` gönderin.
