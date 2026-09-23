# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.594+639` |
| Tarih (UTC) | 2026-09-23 19:13 |
| Commit | [`73485622282b9cd5fdcea7fd1fed60ee25ab5829`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/73485622282b9cd5fdcea7fd1fed60ee25ab5829) |
| İş akışı | [Run 35905526844](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35905526844) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.594+639 (2026-09-23) — Sesli oda PK davet akışı (kanonik API)

- **PK:** Tüm sesli oda mutasyonları `POST /api/chat/rooms/{roomId}/pk` (`action` + `targetRoomId` / `battleId`); 404 veren sahte alt yollar kaldırıldı
- **Davet:** Pop-up 60 sn geri sayım; kabul/red doğrudan oda PK ucu; `GET /api/pk/me/invites?direction=incoming`
- **Presence:** Heartbeat boş gövde (koltuk index gönderilmez); aday listede görünürlük korunur
- **Canlı PK:** İstemci yalnızca `/api/video-streams/pk`, `/api/live/pk`, `/api/pk/{id}` okuma uçları


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
