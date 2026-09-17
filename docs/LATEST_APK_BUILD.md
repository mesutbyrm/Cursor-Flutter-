# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.547+588` |
| Tarih (UTC) | 2026-09-17 09:15 |
| Commit | [`ef564fd133b083cf55226baf2706bfb80d109944`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/ef564fd133b083cf55226baf2706bfb80d109944) |
| İş akışı | [Run 35202086073](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35202086073) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.547+588 (2026-09-17) — Sesli oda + canlı PK TikTok/Bigo (2b)

- Sesli oda HATA 1: presence iterasyonları kopya liste (`_presenceCopy`, `List.from`)
- Sesli oda HATA 2–3: pending seat guard + `voiceSeatActionLockProvider` + reaktif auto-seat (mevcut, doğrulandı)
- Sesli PK HATA 4: `room1`/`room2` eksikse tanılama logu (backend doğrulama gerekir)
- Canlı PK HATA 1: aktif yayın oturumu + anchor odada gereksiz TRTC rejoin atlama
- Canlı PK HATA 4: PK API hata mesajı snackbar (mevcut)
- 2b: `PkStatusPill` skor barı altında; tam ekran `PkWinnerCelebration` canlı yayında yok
- PK bitti: yarım ekran konfeti + kaybeden taraf %35 karartma (~4 sn), `livePkEndedLockProvider` tek tetik


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
