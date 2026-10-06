# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.730+783` |
| Tarih (UTC) | 2026-10-06 23:40 |
| Commit | [`583348565db6a08411e3d4d878e5601455309862`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/583348565db6a08411e3d4d878e5601455309862) |
| İş akışı | [Run 37545972310](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37545972310) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.730+783 (2026-10-07) — Sesli oda: koltuk ses sızıntısı + admin otomatik koltuk

- **Koltuktan inince** TRTC + `/voice` oturumu tam kapatılır (`releaseSeatVoice`) — karşı tarafa ses gitmesi / yeniden bağlanma sızıntısı
- **Admin/sahip otomatik koltuk** yeniden etkin (`schedulePrivilegedSeatAttempts` boş stub kaldırıldı)
- **Keşif SSE:** canlı oda oturumundayken eşzamanlı izlenen oda sayısı 6→4 (Redmi yük azaltma)
- **SSE hub:** `forceReleaseVoiceRoom` diagnostic kaynağını dispose eder


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
