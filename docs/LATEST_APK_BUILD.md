# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.744+797` |
| Tarih (UTC) | 2026-10-08 19:27 |
| Commit | [`d86292838c25fead4f1dae949c1e8c529f8080cf`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d86292838c25fead4f1dae949c1e8c529f8080cf) |
| İş akışı | [Run 37829723559](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37829723559) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.744+797 (2026-10-08) — Oda çıkışı: sunucu leave sırası + SSE alias + duplicate leave

- **Kök neden (ek):** `DELETE presence?leave=1` öncesi `PATCH /seats` çift gidiyordu (409); slug/cuid çift SSE lease leave sonrası açık kalabiliyordu; eşzamanlı `leaveRoomSession` (dispose + UI) ikinci sunucu leave tetikliyordu; poll/refresh async yanıtları leave sonrası state yazabiliyordu
- **Sunucu:** Önce `presence?leave=1` (koltuk + user_left); yalnızca kabul edilmezse `clearSeat`; `VoiceRoomServerLeaveDedupe` ile tek uçuş
- **SSE:** Tüm oda alias'larında `forceRelease`; keşif-only `connect` stale live handler'ları temizler; SSE key upgrade `forceRelease`
- **Leave:** `_ongoingLeaveRoomSession` birleştirme; erken `clearVoiceRoomLiveSession`; poll/refresh generation + `_leaveInFlight` guard
- **Log:** `ROOM_LIFECYCLE` LEAVE_* / SSE_CANCEL; `STALE_CALLBACK_IGNORED`; `SEAT_REQUEST duplicate=`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
