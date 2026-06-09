# P1 Deploy — Sesli Oda Arka Planları

Parite raporu **#2**. Web referansı: `https://canlifal.com/images/voice-bg-1.jpg` … `voice-bg-20.jpg`.

## Durum

| Katman | Durum |
|--------|--------|
| Web | Statik `/images/voice-bg-{1..20}.jpg` — **200** |
| Prod API | `GET /api/chat/rooms/backgrounds` — **404** (deploy gerekli) |
| Flutter (bu PR) | API yoksa `VoiceRoomBackgroundCatalog.siteDefaults()` — web ile aynı 20 URL |

## canlifal.com web reposu

1. `docs/nextjs/lib/voiceRoomBackgrounds.ts` → `lib/voiceRoomBackgrounds.ts`
2. `docs/nextjs/app-api-chat-rooms-backgrounds-route.ts` → `app/api/chat/rooms/backgrounds/route.ts`
3. İsteğe bağlı env: `NEXT_PUBLIC_SITE_URL=https://canlifal.com`
4. Deploy sonrası:

```bash
curl -s https://canlifal.com/api/chat/rooms/backgrounds | head -c 300
# {"backgrounds":["https://canlifal.com/images/voice-bg-1.jpg",...]}
```

## Oda arka planı güncelleme

Flutter ve web:

```
PATCH /api/chat/rooms/:roomId/background
Authorization: Bearer <JWT>
{ "backgroundImage": "https://canlifal.com/images/voice-bg-3.jpg" }
```

Yalnızca oda sahibi / admin (sunucu tarafı yetki kontrolü).

Sıradaki: [DEPLOY_P1_FCM.md](./DEPLOY_P1_FCM.md)

## Doğrulama

```bash
bash scripts/verify-p0-endpoints.sh   # backgrounds satırını da kontrol eder
```

Statik dosyalar:

```bash
for i in 1 10 20; do
  curl -s -o /dev/null -w "%{http_code} voice-bg-$i\n" \
    "https://canlifal.com/images/voice-bg-$i.jpg"
done
```
