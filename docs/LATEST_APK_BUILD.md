# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.225+228` |
| Tarih (UTC) | 2026-06-16 11:24 |
| Commit | [`ed85c05c93cf231173073a9df43663764c1fae69`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ed85c05c93cf231173073a9df43663764c1fae69) |
| İş akışı | [Run 27613560738](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27613560738) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.225+228 (2026-06-12)

### Sesli oda — üretim dokümantasyonu uyumu

- **!istek:** `GET /api/youtube/search` → `POST song-request` + `skipPayment: true` (jeton gerekmez)
- **Şarkı isteği:** `song-request` birincil; `dedication`, `duration` (m:ss), `skipPayment` alanları
- **DJ kontrolü:** `POST /music` yalnızca DJ müzik kontrolünde; `set_active_dj` API + DJ panelinde yıldız
- **SSE:** `type: messages` toplu mesaj olayları işlenir
- **Presence:** 30 sn heartbeat (üretim sözleşmesi)
- **Mesaj poll:** `?after=` (since yedeği)
- **Moderasyon:** `unban_user` / `unmute_user` → `POST /moderation`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
