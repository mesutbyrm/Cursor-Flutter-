# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.743+796` |
| Tarih (UTC) | 2026-10-08 01:43 |
| Commit | [`53b1d5b2d6b655c280383225feb770afd8c21bac`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/53b1d5b2d6b655c280383225feb770afd8c21bac) |
| İş akışı | [Run 37712360431](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37712360431) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.743+796 (2026-10-08) — Leave sonrası SSE callback / ref dispose

- **Kök neden:** `ChatRoomSseService.connect` yalnızca verilen handler'ları güncelliyordu; keşif hub yeniden bağlanınca eski oda live callback'leri (`onPresence`, `onRoomEvent`) bellekte kalıyordu → backend leave başarılı olsa bile eski oda SSE snapshot state'e yazılıyordu
- **SSE:** `disconnect` / `forceRelease` → `clearLiveEventHandlers()`; leave adım 1'de erken `_tearDownLiveSseImmediately`
- **Guard:** `_liveSessionGeneration` + `_acceptRoomLifecycleCallback` (`ROOM_CALLBACK`); presence merge / seat refresh / room_event leave sırasında no-op
- **409:** `PATCH /seats` çakışması loglanır (`SEAT_REQUEST`); leave pipeline `clearSeat` 409 = zaten boş; `clearUserSeat` leave sırasında atlanır
- **UI:** RTC dispose'da notifier önce yakalanır; listener'larda `mounted` guard


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
