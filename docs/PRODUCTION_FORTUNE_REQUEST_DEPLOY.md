# Production Deploy — Fortune Request Fix

> **Hedef:** `https://canlifal.com` Next.js App Router  
> **Bu repo:** Flutter + `api/` mirror — production deploy buradan yapılmaz.

## Sorun

`POST /api/video-streams/{id}/fortune-requests`

| Senaryo | Beklenen | Üretim (2026-08-09) |
|---------|----------|----------------------|
| `{typeId, nickname, question, isHidden}` | 200 | ✅ 200 |
| Legacy `{displayName, fortuneType, ...}` | 400 veya 200 (map) | ❌ **500** |
| Geçersiz `streamId` | 404 | ❌ **200** (validation yok) |
| Geçersiz `typeId` | 400 | ✅ 400 |
| Token yok | 401 | ✅ 401 |

## Deploy edilecek kod (kaynak: bu repo)

1. **`api/src/lib/streamFortuneRequestService.ts`**
   - `parseFortuneCreateBody()` — legacy `fortuneType:tarot` → `typeId:tek-soru`
   - `mapFortuneCreateException()` — Prisma P2002→409, P2003→400

2. **Next.js route handler** (`app/api/video-streams/[id]/fortune-requests/route.ts` veya eşdeğeri):
   - `getLiveStream(streamId)` yoksa **404** döndür (fortune request oluşturmadan önce)
   - `parseFortuneCreateBody(req.body)` — validation **transaction öncesi**
   - `hasPendingFortuneRequest` → 400
   - `user.coins < jetonAmount` → 402
   - catch → `mapFortuneCreateException(e)` (generic 500 değil)

## Deploy doğrulama

```bash
bash scripts/acceptance-tests/api-stage8-production.sh
```

Beklenen: Stage 8 script **0 FAIL**.

## Deployment ortamı

- **Host:** canlifal.com
- **Stack:** Next.js 14, Cloudflare CDN, Envoy upstream
- **Bu Flutter repo CI:** yalnızca APK build — canlifal.com API deploy etmez

## Cache

Deploy sonrası hâlâ eski davranış varsa:
- Cloudflare cache purge (API path'leri)
- Next.js serverless function cold start / yeni revision
- Reverse proxy upstream pool güncellemesi
