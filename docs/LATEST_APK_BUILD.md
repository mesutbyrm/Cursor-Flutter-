# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.544+585` |
| Tarih (UTC) | 2026-09-16 18:22 |
| Commit | [`8c42e6db39c7f0fbe3df621fe0c5b7f482c3e7c3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/8c42e6db39c7f0fbe3df621fe0c5b7f482c3e7c3) |
| İş akışı | [Run 35131101953](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35131101953) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.544+585 (2026-09-16) — Sesli oda koltuk senkron yarışı

- Pending seat lock (5 sn): seat-take/leave sırasında presence snapshot kullanıcıyı düşürmez
- Reaktif yetkili auto-seat: rol/izin + presence değişince tek deneme (context latch)
- Host reconciliation: koltuksuz host 3 sn sonra yeniden oturma (pending yoksa)
- Birim test: `voice_seat_pending_guard_test.dart`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
