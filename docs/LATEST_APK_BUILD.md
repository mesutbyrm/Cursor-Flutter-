# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.226+229` |
| Tarih (UTC) | 2026-06-16 12:29 |
| Commit | [`9111e106dac70ac97b20c865918381007a3f7e35`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/9111e106dac70ac97b20c865918381007a3f7e35) |
| İş akışı | [Run 27616986352](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27616986352) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.226+229 (2026-06-12)

### Sesli oda — tam teknik dokümantasyon uyumu

- **myPermissions:** `GET messages` yanıtından sunucu yetkileri okunur; kick/ban/mute/oda sessiz ayrı kontrol
- **!istek / song-request:** Üretim akışı korunur (`skipPayment`, `dedication`, `duration`)
- **Presence:** 30 sn heartbeat + `nickname`; koltuk indeksi 0–14
- **SSE:** `messages` batch + `typing` kullanıcı listesi
- **Müzik:** Çalarken `GET /music` ile sunucu auto-advance tetiklenir
- **Moderasyon:** kick/ban/mute ayrı UI; `mute_room` / `unmute_room`; `PATCH song-request`
- **Odalar:** `GET /api/chat/rooms?withCounts=true`; mesajlarda `after` + `limit=100`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
