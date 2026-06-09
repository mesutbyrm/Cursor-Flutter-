# P0 Deploy — Müzik Arama + TRTC (canlifal.com)

Parite raporu madde **#1**. Bu belge, üretimde Flutter sesli oda ve canlı yayın için gerekli minimum API’leri deploy etmeyi anlatır.

## Durum kontrolü (2026-05-19)

| Endpoint | Beklenen | Prod sondası |
|----------|----------|--------------|
| `GET /api/music/search?q=` | 401 (oturumsuz) / 200 (JWT + key) | ✅ 401 — route mevcut |
| `POST /api/trtc/usersig` | 200 + sdkAppId | ✅ 200 |
| `GET /api/chat/youtube-stream?url=` | 200 veya 404 | ❌ 404 — deploy gerekli |

## 1. Vercel ortam değişkenleri

Vercel → Project → Settings → Environment Variables:

```env
# Müzik arama (YouTube Data API v3)
YOUTUBE_API_KEY=AIzaSy...

# Mobil JWT doğrulama (POST /api/auth/mobile-login ile aynı secret)
JWT_ACCESS_SECRET=<üretimdeki mevcut değer>

# Tencent TRTC
TRTC_SDK_APP_ID=1400000000
TRTC_SECRET_KEY=<tencent konsol secret>
```

**Not:** `JWT_ACCESS_SECRET` zaten mobil auth için tanımlıysa tekrar eklemeyin; `verifyApiAuth.ts` aynı secret’ı kullanır.

## 2. Next.js route dosyaları

Kaynak: `docs/nextjs/` (bu repo).

```text
docs/nextjs/lib/*.ts          →  lib/
docs/nextjs/app-api-*.ts      →  app/api/.../route.ts
```

Detaylı tablo: `docs/nextjs/README.md`.

## 3. Bağımlılıklar (web reposu)

```bash
npm install tls-sig-api-v2 jsonwebtoken
npm install -D @types/jsonwebtoken
```

## 4. Deploy sonrası doğrulama

```bash
# Oturumsuz — müzik 401, TRTC 200
bash scripts/verify-p0-endpoints.sh

# JWT ile müzik arama (token'ı mobil login'den alın)
export CANLIFAL_JWT="eyJ..."
bash scripts/verify-p0-endpoints.sh --auth
```

Başarılı müzik yanıtı örneği:

```json
{
  "items": [
    {
      "videoId": "abc123",
      "title": "Şarkı adı",
      "thumbnail": "https://i.ytimg.com/vi/abc123/hqdefault.jpg",
      "channelTitle": "Kanal",
      "duration": "3:45"
    }
  ]
}
```

Başarılı TRTC yanıtı:

```json
{
  "sdkAppId": 1400000000,
  "userSig": "...",
  "userId": "cuid_xxx",
  "roomId": "voice_room_..."
}
```

## 5. Flutter tarafı

Ek APK gerekmez; mevcut sürüm zaten şu uçları kullanır:

- `ApiEndpoints.musicSearch` → `/api/music/search`
- `ApiEndpoints.trtcUserSig` → `/api/trtc/usersig`
- `YoutubeStreamResolver` → `/api/chat/youtube-stream` (deploy sonrası devreye girer)

**Önemli:** Kullanıcı giriş yapmadan müzik araması 401 döner — bu beklenen davranıştır.

## 6. Sorun giderme

| Belirti | Olası neden | Çözüm |
|---------|-------------|-------|
| Müzik 503 | `YOUTUBE_API_KEY` yok | Vercel env + redeploy |
| Müzik 401 (girişli) | JWT secret uyuşmazlığı | `JWT_ACCESS_SECRET` mobil auth ile aynı olmalı |
| TRTC 500 | TRTC env eksik | `TRTC_SDK_APP_ID` + `TRTC_SECRET_KEY` |
| Stream 404 | Route deploy edilmedi | `app/api/chat/youtube-stream/route.ts` ekle |
| Flutter ses çalmıyor | googlevideo Referer | `VoiceRoomDjStreamLoader` yerel indirme kullanır; stream API yine de önerilir |

## İlgili: P1 arka planlar

Sesli oda arka plan kataloğu: `docs/DEPLOY_P1_BACKGROUNDS.md`

## Yerel mirror testi

```bash
cd api
cp .env.example .env   # YOUTUBE_API_KEY ve TRTC değerlerini doldurun
npm run build && npm start

curl -s "http://localhost:3000/api/music/search?q=test" \
  -H "Authorization: Bearer $JWT"

curl -s -X POST "http://localhost:3000/api/trtc/usersig" \
  -H "Content-Type: application/json" \
  -d '{"userId":"test","roomId":"room1"}'
```
