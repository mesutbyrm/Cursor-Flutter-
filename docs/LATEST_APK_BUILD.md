# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.726+779` |
| Tarih (UTC) | 2026-10-06 13:26 |
| Commit | [`9f0072cac7dbfb8b491e9ffaf3ee7db0b83e6b96`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/9f0072cac7dbfb8b491e9ffaf3ee7db0b83e6b96) |
| İş akışı | [Run 37467895320](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37467895320) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.725+778 (2026-10-06) — Psychic P0 FAIL hotfix: falcı donma + sesli oda hayalet/PK hediye

- **Canlı falcı:** bitmiş seans diskten açılmadan sunucu durumu doğrulanır; `_syncRoomInfo` terminal seansı TRTC öncesi kapatır; uygulama ön plana dönünce oda/sinyal yenilenir
- **Sesli keşif:** boş odada hayalet «1 kişi» — keşif hub `countFor` ile hizalı
- **Odadan çıkış:** ses hemen kesilir (leave adım 1 erken TRTC/audio)
- **PK hediye:** SSE `roomId` PK karşı oda alias’ı ile eşleşir (görsel + karşı taraf sesi)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
