# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.555+596` |
| Tarih (UTC) | 2026-09-17 22:35 |
| Commit | [`a8ca45c5574bf58cc2bd44eba1471719047a4dac`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/a8ca45c5574bf58cc2bd44eba1471719047a4dac) |
| İş akışı | [Run 35281465413](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35281465413) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.555+596 (2026-09-17) — PK: TRTC oda, davet 60 sn, sonuç kapanışı

- İki yönlü PK: her iki yayıncı aynı TRTC odasına (host stream / `pkRoomId`); `pkSessionId` battle UUID artık oda olarak kullanılmıyor
- PK daveti: 60 sn geri sayım; global listener 1 sn poll + yayın odasında SSE bump
- PK bitiş: sonuç ~4 sn sonra split kapanır, normal yayın TRTC’ye dönülür
- Split UI: üstte eşit kare video bandı, rakip sessize alma yalnızca yerel playback


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
