# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.592+636` |
| Tarih (UTC) | 2026-09-22 17:00 |
| Commit | [`8e7b4a35742833dcfb2fda468a63fc2ad02f0d88`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8e7b4a35742833dcfb2fda468a63fc2ad02f0d88) |
| İş akışı | [Run 35756067212](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35756067212) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.592+636 (2026-09-22) — Canlı fal: süre isteği sinyal formatı (üretim)

- **POST/GET `/api/room/signal`:** üretim alanları `signalType` + `signalData` (mobilde `type`/`data` ile birlikte gönderilir)
- **Poll:** gelen sinyaller normalize edilir; danışanda **Görüşmeyi Başlat** istemi tetiklenir
- **SSE:** `event: signal` ve `timer_start_*` kök tipleri doğru ayrıştırılır
- **Süre iste:** falcı **Süre iste** ile peer TRTC olmasa da isteği yeniden gönderebilir


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
