# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.591+635` |
| Tarih (UTC) | 2026-09-22 13:45 |
| Commit | [`75cad44b53416b9168e7593475c4e4dec52e7d87`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/75cad44b53416b9168e7593475c4e4dec52e7d87) |
| İş akışı | [Run 35732929672](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35732929672) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.591+635 (2026-09-22) — Canlı falcı: kabul senkronu + süre isteği SSE

- **Danışan bekleme:** kabul sonrası `fetchActiveSessions` / oda durumu ile REQUESTING ekranından çıkış; oturuma geçiş
- **Süre el sıkışması:** oda SSE `signal` olayında iç `type`/`action` ayrıştırma; falcı tarafında `timer_start_accept` artık yanlışlıkla tekrar istek atmaz
- **Falcı panel kabul:** oturuma `pushReplacement`, kuyruk temizliği; derleme için eksik importlar eklendi
- **Durum eşleme:** `ready` / `live` / `in_progress` gibi API durumları aktif sayılır


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
