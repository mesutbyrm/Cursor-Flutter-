# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.599+650` |
| Tarih (UTC) | 2026-09-26 10:32 |
| Commit | [`6ae9b42fd5c4df6e3f33f1d39db919d56a34e7a6`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/6ae9b42fd5c4df6e3f33f1d39db919d56a34e7a6) |
| İş akışı | [Run 36235158672](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36235158672) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.599+650 (2026-09-25) — Sesli oda backend sözleşmesi (2. dalga)

- **selfInRoom:** yalnızca backend join onayı + presence listesi (`resolveSelfInRoomFromBackend`)
- **GET /state:** join öncesi sahte “odadayım” kapatıldı
- **Leave:** önce `DELETE .../presence` (voice_room_api.md)
- **Cold start:** kayıtlı oda için auth sonrası stale presence leave
- **TRTC:** `backendSyncReady` için 8 sn bekleme


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
