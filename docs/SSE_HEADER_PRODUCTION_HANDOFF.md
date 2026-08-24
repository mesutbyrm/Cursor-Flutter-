# SSE Header — Production Handoff

**Tarih:** 2026-08-10  
**Durum:** `X-Accel-Buffering: no` üretim yanıtında **yok** (canlifal.com)

## Kanıt (production)

```
GET https://canlifal.com/api/chat/rooms/{roomId}/stream
Authorization: Bearer <token>
Accept: text/event-stream

HTTP/2 200
content-type: text/event-stream
cache-control: no-cache, no-transform
server: cloudflare
cf-cache-status: DYNAMIC
(x-accel-buffering: YOK)
```

## Root cause

**PROXY/CDN HEADER OMISSION** — Next.js üretim handler'ı `X-Accel-Buffering: no` göndermiyor; Cloudflare yanıtta görünmüyor. Flutter istemcisinde header eklemek çözüm değildir.

## Production Next.js (canlifal.com repo — bu Flutter reposunda yok)

Tüm SSE route'larında response başlıkları:

```
Content-Type: text/event-stream; charset=utf-8
Cache-Control: no-cache, no-transform
Connection: keep-alive
X-Accel-Buffering: no
```

Yerel mirror referans: `api/src/lib/sseResponseHeaders.ts`

## Cloudflare (yalnızca SSE path'leri)

Genel cache bypass yapma. Örnek kural:

- **If:** URI Path matches `^/api/.*/stream$` (veya bilinen 5 SSE endpoint)
- **Then:** Cache Level = Bypass, Disable buffering where applicable
- **Transform Rule (isteğe bağlı):** Response header set `X-Accel-Buffering: no` when origin omits (yedek)

SSE endpointleri (kılavuz §5):

- `/api/chat/rooms/{id}/stream`
- `/api/video-streams/{id}/stream`
- `/api/room/{sessionId}/stream`
- `/api/fortune-tellers/sessions/stream`
- `/api/notifications/stream`

## Doğrulama

```bash
bash scripts/acceptance-tests/sse-20-cycle.sh
# Hedef: SSE acceptance 20/20 (19 cycle + header TEST 20)
```

## Bu repo'da yapılan

- `api/src/lib/sseResponseHeaders.ts` — yerel mirror SSE başlıkları
- `scripts/acceptance-tests/sse-20-cycle.sh` — TEST 20 header probe

Üretim deploy bu repodan otomatik yapılmaz.
