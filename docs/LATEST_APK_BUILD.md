# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.371+409` |
| Tarih (UTC) | 2026-09-07 23:15 |
| Commit | [`ace2fffc53e6d4829622bd53b6b9ac4e8c1de8c3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ace2fffc53e6d4829622bd53b6b9ac4e8c1de8c3) |
| İş akışı | [Run 34168449363](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34168449363) |
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
