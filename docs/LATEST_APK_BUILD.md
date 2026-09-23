# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.597+642` |
| Tarih (UTC) | 2026-09-23 21:54 |
| Commit | [`d83885d430b9dc980ff95e3df11d591f2ad5c4f5`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/d83885d430b9dc980ff95e3df11d591f2ad5c4f5) |
| İş akışı | [Run 35923422967](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/35923422967) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.597+642 (2026-09-23) — Odalar arası PK: davet + oda kopması

- **Sesli PK sınıflandırma:** `stream1Id/stream2Id` artık canlı yayın PK sanılmıyor; davet ingest ve popup hedefi düzeldi
- **Davet dinleyici:** Yanlış `owned.first` popup kaldırıldı; yalnızca gerçek hedef oda + `isPkInviteTarget`; rakip oda poll’u kaldırıldı
- **Oda girişi:** PK poll presence sonrası 2 sn gecikmeli; SSE oda anahtarı yalnızca cuid yükseltmede yenilenir
- **Davet gönder:** Eski pending için `cancel`; aday/host sorguda slug yedek anahtarı


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
