# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.729+782` |
| Tarih (UTC) | 2026-10-06 20:47 |
| Commit | [`caacbdf303868670f0bd5bbc3424e2e448b03e51`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/caacbdf303868670f0bd5bbc3424e2e448b03e51) |
| İş akışı | [Run 37526193211](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37526193211) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.729+782 (2026-10-06) — Gerçek cihaz Diagnostic Logger (dosya + ZIP)

- **CfDiagnosticLogger:** `diagnostics/session_*/canlifal_diagnostic.log`, `summary.json`, `errors.json`, `DIAG-*` oturum kimliği; son 100 aksiyon + kritik an snapshot
- **İzleme:** Dio istekleri, timer/polling (canlı fal), oda SSE/TRTC olayları, oturum durumu, donma/jank (mevcut CfMonitors üzerine)
- **Diagnostics ekranı:** Overview / Errors / Network / Timer / Polling / SSE / TRTC / Requests / Freeze / Resources sekmeleri; «Dosyaya kaydet» + **LOGU DIŞA AKTAR (ZIP)** (`AI_DEBUG_SUMMARY.md` dahil)
- Mevcut Performance Monitor, Freeze Watchdog, ResourceTracker, CfDiag **korundu** — silinmedi


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
