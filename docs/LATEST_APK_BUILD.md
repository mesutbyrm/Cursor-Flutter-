# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.545+586` |
| Tarih (UTC) | 2026-09-16 19:38 |
| Commit | [`452bc6d08b6947e6801b867f13a5d1c9dfbf6758`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/452bc6d08b6947e6801b867f13a5d1c9dfbf6758) |
| İş akışı | [Run 35139717006](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35139717006) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.545+586 (2026-09-16) — Sesli oda + canlı PK hata listesi

- Sesli oda: presence SSE işleme kopya liste; `voiceSeatActionLockProvider` (PK lock deseni)
- Pending seat guard + reaktif yetkili auto-seat listener (`VoiceRoomPrivilegedAutoSeatListener`)
- Sesli PK davet: `room1`/`room2` eksikse tanılama logu (backend doğrulama gerekir)
- Canlı PK: tam ekran kazanan overlay kalıntıları kaldırıldı; inline rozet latch (flicker yok)
- PK oluşturma hatası snackbar + `ApiException` mesajı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
