# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.314+317` |
| Tarih (UTC) | 2026-06-20 19:13 |
| Commit | [`d4b497a53bd526bf5938fa127bd8be4c0bf28e66`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d4b497a53bd526bf5938fa127bd8be4c0bf28e66) |
| İş akışı | [Run 27880762254](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27880762254) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.314+317 (2026-06-20)

### Sesli oda — PK SSE entegrasyonu

- **chat_room_providers:** Oda SSE akışına `onPk` callback — PK güncellemeleri artık ayrı Socket.IO yerine ana SSE'den besleniyor
- **pk_battle_remote_provider:** `connectSocket` / `disconnectSocket` no-op; REST + SSE mimarisi
- **chat_room_sse_service:** `type: pk` olayları parse edilip `PkBattleRemote` olarak iletiliyor


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
