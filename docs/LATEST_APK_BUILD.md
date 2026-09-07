# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.371+409` |
| Tarih (UTC) | 2026-09-07 17:04 |
| Commit | [`814f8758`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/814f8758c925933058e5a3a466f357db2fb7c06e) |
| İş akışı | [Run 34144544248](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34144544248) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.371+409 (2026-08-27) — Faz 2: Psychic TRTC 5 sn freeze kök nedeni

- **Yanlış canlı-yayın stack kaldırıldı:** Psychic artık `POST /api/live/join-room` + 10 sn live heartbeat kullanmaz
- **Token:** yalnızca `POST /api/trtc/token` (kılavuz §9.13); token client’ta üretilmez
- **trtcRoomId drift:** SSE/`GET /room` takma adları (`room_`, `fortune_room_`) rejoin tetiklemez
- **Tek engine:** paylaşılan `TrtcRoomManager` + join/leave tek kuyruk; duplicate listener yok
- **Reconnect:** yalnızca gerçek `onConnectionLost` / ağ dönüşü / odada değilken resume; SSE veya remote A/V değil
- **Analyze gate:** gelen kutu uyumluluk sayfalarındaki bozuk inbox import yolları düzeltildi (CI ERROR=0)

_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
