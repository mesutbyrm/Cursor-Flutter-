# Flutter ↔ Backend Parite — Deploy Kontrol Listesi

Güncelleme: 2026-05-19. Bu repo `api/` altında Express mirror; **canlifal.com** üretimi Next.js’tir.

## Müzik arama (P0)

| Katman | Durum | Not |
|--------|--------|-----|
| Flutter | ✅ `GET /api/music/search` | Piped/Invidious kaldırıldı (1.0.129+131) |
| API mirror | ✅ `api/src/routes/music.ts` | `YOUTUBE_API_KEY` gerekli |
| canlifal.com | ✅ route var (401 oturumsuz) | `YOUTUBE_API_KEY` + JWT; deploy: `docs/DEPLOY_P0.md` |
| YouTube stream | ⚠️ | `GET /api/chat/youtube-stream` prod **404** — `docs/nextjs/app-api-chat-youtube-stream-route.ts` |

**Vercel / sunucu `.env`:**
```env
YOUTUBE_API_KEY=AIza...
```

## TRTC (P0)

| Endpoint | Mirror | Prod |
|----------|--------|------|
| `POST /api/trtc/usersig` | ✅ | ✅ 200 (env doğruysa); `docs/nextjs/app-api-trtc-usersig-route.ts` |

## Mesajlaşma (P1)

- `GET /api/messages` — sohbet listesi
- `GET/POST /api/messages/:userId` — thread

## Sosyal (P1)

- `POST/DELETE /api/social/posts/:id/likes`
- `GET/POST /api/social/posts/:id/comments`

## Diğer (P1)

| Özellik | Endpoint |
|---------|----------|
| Kullanıcı arama | `GET /api/users/search?q=` |
| Davet | `GET /api/referral` |
| Hikaye | `GET/POST /api/stories` |
| Şikayet | `POST /api/reports` |
| Canlı listesi | `GET /api/video-streams` |
| Yayın bitir | `POST /api/video-streams/:id/end` |
| Oda SSE | `GET /api/chat/rooms/:id/stream` |

## Mobil auth (P1)

- `POST /api/auth/mobile-register|login|google|tiktok|refresh`
- `POST /api/auth/forgot-password`

## Üretim deploy adımları

1. canlifal.com reposuna `app/api/music/search/route.ts` ekleyin (referans dosyayı kopyalayın; JWT doğrulamayı mevcut auth ile birleştirin).
2. Vercel’de `YOUTUBE_API_KEY` ekleyin ve redeploy.
3. TRTC için `TRTC_SDK_APP_ID` + `TRTC_SECRET_KEY` ekleyin.
4. APK: `API_BASE_URL=https://canlifal.com` ile 1.0.129+131 derleyin.

## Yerel test (mirror)

```bash
cd api && npm run build && npm start
# YOUTUBE_API_KEY=... JWT=... curl "http://localhost:3000/api/music/search?q=test"
```
