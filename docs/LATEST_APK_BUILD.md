# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.745+798` |
| Tarih (UTC) | 2026-10-08 23:22 |
| Commit | [`227f353b3b0a64d56747dafd168c87a0708ebda3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/227f353b3b0a64d56747dafd168c87a0708ebda3) |
| İş akışı | [Run 37856785644](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37856785644) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.745+798 (2026-10-08) — P0: explicit voice room join (implicit provider bootstrap kaldırıldı)

- **P0:** `voiceRoomLiveProvider.build()` artık `_beginRoomSession()` çağırmıyor; oturum yalnızca `joinRoomSession()` (oda RTC/Basic sayfası) ile başlar
- **active key:** `prepareVoiceRoomSwitch` → `voiceRoomPendingLiveKeyProvider`; `registerVoiceRoomLiveSession` yalnızca presence.join başarısından sonra
- **SSE/poll:** reconnect ve `_refreshImpl` artık yeni `presence.join` tetiklemez; `_startSse` / `_joinPresence` explicit session guard
- **Log:** `JOIN_INTENT`, `JOIN_START`, `JOIN_SUCCESS`, `BLOCKED_IMPLICIT_JOIN`, `LEAVE_*`, `SSE_START`, `PRESENCE_JOIN`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
