# PK Battle — canlifal.com web reposuna kopyalanacak dosyalar

Bu Flutter mirror (`api/`) ile **birebir** senkron tutulmalı.

## Prisma

1. `docs/nextjs/pk/PK_PRISMA_SCHEMA.prisma` → `prisma/schema.prisma` içine ekle veya doğrula
2. `npx prisma migrate dev --name pk_battle` (ilk kurulum)

## Sunucu kütüphanesi

| Kaynak (bu repo) | Hedef (web repo) |
|------------------|------------------|
| `api/src/lib/pkBattleService.ts` | `lib/pk/pkBattleService.ts` |
| `api/src/lib/pkCache.ts` | `lib/pk/pkCache.ts` |
| `api/src/routes/pk_battles.ts` | `lib/pk/pkBattleRoutes.ts` (handler export) |
| `api/src/socket/giftHub.ts` | mevcut Socket.IO sunucunuza `emitPkBattleEvent` ekleyin |

`pkBattleService.ts` içinde `prisma` import yolunu web projenize göre düzeltin (`@/lib/prisma`).

## App Router route dosyaları

`docs/nextjs/pk/routes/` altındaki her dosyayı tablodaki hedefe kopyalayın:

| Referans dosya | Hedef |
|----------------|-------|
| `app-api-pk-battles-route.ts` | `app/api/pk/battles/route.ts` |
| `app-api-pk-battles-id-route.ts` | `app/api/pk/battles/[id]/route.ts` |
| `app-api-pk-battles-id-accept-route.ts` | `app/api/pk/battles/[id]/accept/route.ts` |
| `app-api-pk-battles-id-reject-route.ts` | `app/api/pk/battles/[id]/reject/route.ts` |
| `app-api-pk-battles-id-end-route.ts` | `app/api/pk/battles/[id]/end/route.ts` |
| `app-api-pk-history-route.ts` | `app/api/pk/history/route.ts` |
| `app-api-chat-rooms-pk-battle-route.ts` | `app/api/chat/rooms/[roomId]/pk-battle/route.ts` |
| `app-api-video-streams-pk-battle-route.ts` | `app/api/video-streams/[streamId]/pk-battle/route.ts` |

## Hediye → PK puan

Oda/yayın hediyesi gönderildiğinde aktif PK varsa `recordPkGift` çağrılmalı (`pkBattleService.ts`). Web hediye handler'ınızda bu hook'u ekleyin.
