# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.116+118` |
| Tarih (UTC) | 2026-06-03 16:00 |
| Commit | [`7da948316e7d2a0bb139253bf6dc34077f8d5054`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/7da948316e7d2a0bb139253bf6dc34077f8d5054) |
| İş akışı | [Run 26895372956](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/26895372956) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.116+118 (2026-05-19)

### Native canlifal.com API uyumu (WebView yok)

- Şifre sıfırlama: `POST /api/auth/forgot-password` (native ekran)
- DM: `conversations` / `requests` ayrıştırma; mobil `GET /api/messages`
- Takip: `POST /api/users/:id/follow` toggle
- Profil: `PATCH /api/me` (`name`, `image`)
- Canlı: `/api/video-streams`; sesli odalar her zaman `/api/chat/rooms`
- Okunmamış mesaj: `GET /api/messages?unreadCount=true`
- Site yolları → `native_site_routes` (şifre sıfırlama dahil)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
