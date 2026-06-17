# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.255+258` |
| Tarih (UTC) | 2026-06-17 21:33 |
| Commit | [`a1c775b218cc11dc7f51eb1298524968060891c7`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a1c775b218cc11dc7f51eb1298524968060891c7) |
| İş akışı | [Run 27720534672](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27720534672) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.255+258 (2026-06-17)

### Canlı falcı — üretim oda API (`/api/room/*`)

- **Oda:** `GET /api/room/{sessionId}` — timer, peerId, jeton bakiyesi
- **Timer:** Falcı `start_timer`; her iki taraf 60 sn `ping`; client-side countdown sunucu `timerStartedAt` ile
- **Sohbet:** `GET/POST /api/room/{sessionId}/messages` (teller-chat yedek)
- **Süre:** Kullanıcı `extend`, falcı `teller_add_time`; seans bitişi `PATCH action: end`
- **Seans oluşturma:** `fortuneType` + `duration` alanları; falcı poll `?status=pending`
- **Bekleme:** Danışan «Falcı hazırlanıyor…» overlay'i timer başlayana kadar


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
