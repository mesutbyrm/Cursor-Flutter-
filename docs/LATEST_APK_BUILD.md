# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.599+649` |
| Tarih (UTC) | 2026-09-25 14:58 |
| Commit | [`30b12b3ead8bb862603c27fd78dd929843ff26b0`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/30b12b3ead8bb862603c27fd78dd929843ff26b0) |
| İş akışı | [Run 36148889731](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36148889731) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.599+648 (2026-09-25) — Sesli oda presence yaşam döngüsü (Aşama 1)

- **Aktif oda kaydı** yalnızca backend `presence join` onayından sonra (`registerVoiceRoomLiveSession`)
- **Sahte odadayım:** SSE/join listesine kendini ekleme yalnızca `_presenceJoined` iken
- **Çift heartbeat/join:** `RoomSessionManager.delegateLifecycleToHost` — API tek kaynak (`VoiceRoomLiveController`)
- **Heartbeat yeniden join:** koltuk talebi olmadan presence yenileme (`rejoinAfterHeartbeat`)
- **SSE selfInRoom:** backend join onayı olmadan `selfInRoom` korunmaz
- **Leave:** presence leave sonrası aktif oda registry + manager `syncHostLeft`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
