# canlifal.com Next.js — P0 API Deploy Paketi

Bu klasör, **canlifal.com** web reposuna kopyalanacak üretim route referanslarını içerir. Flutter mobil uygulama bu uçları `https://canlifal.com` üzerinden çağırır.

## Hızlı kurulum

1. `lib/` dosyalarını web reposuna kopyalayın:
   - `lib/verifyApiAuth.ts`
   - `lib/youtubeMusicSearch.ts`
   - `lib/trtcUserSig.ts`
   - `lib/resolveYoutubeStream.ts`
   - `lib/voiceRoomBackgrounds.ts`

2. Route dosyalarını App Router yoluna taşıın:

| Bu dosya | Hedef |
|----------|-------|
| `app-api-music-search-route.ts` | `app/api/music/search/route.ts` |
| `app-api-trtc-usersig-route.ts` | `app/api/trtc/usersig/route.ts` |
| `app-api-chat-youtube-stream-route.ts` | `app/api/chat/youtube-stream/route.ts` |
| `app-api-chat-rooms-backgrounds-route.ts` | `app/api/chat/rooms/backgrounds/route.ts` |
| `app-api-devices-fcm-route.ts` | `app/api/devices/fcm/route.ts` |
| `app-api-membership-packages-route.ts` | `app/api/membership/packages/route.ts` |

3. `verifyApiAuth.ts` içinde `verifyWebSession` fonksiyonunu mevcut NextAuth `getServerSession` ile doldurun.

4. Vercel ortam değişkenlerini ekleyin (bkz. `docs/DEPLOY_P0.md`).

5. `npm install tls-sig-api-v2 jsonwebtoken` (web reposunda yoksa).

6. Deploy sonrası: `bash scripts/verify-p0-endpoints.sh`

## Flutter eşlemesi

| Özellik | Flutter dosyası | API |
|---------|-------------------|-----|
| Müzik arama | `chat_room_remote_datasource.dart` | `GET /api/music/search` |
| TRTC oda | `trtc_remote_datasource.dart` | `POST /api/trtc/usersig` |
| Stream çözümleme | `youtube_stream_resolver.dart` | `GET /api/chat/youtube-stream` |
| Oda arka planları | `voice_room_background_catalog.dart` | `GET /api/chat/rooms/backgrounds` |
| Push token | `push_registrar.dart` | `POST /api/devices/fcm` |
| Üyelik | `membership_remote_datasource.dart` | `GET /api/membership/packages` |
| PK Battle | `pk_battle_remote_datasource.dart` | `api/src/routes/pk_battles.ts` (çoklu route) |

## api/ mirror

Yerel test için `api/` Express mirror aynı sözleşmeyi uygular:

```bash
cd api && npm run build && npm start
```
