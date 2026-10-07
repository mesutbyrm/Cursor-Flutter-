# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.731+784` |
| Tarih (UTC) | 2026-10-07 01:04 |
| Commit | [`45a6f4e0188618f4ed3627fb4dfc6f03281711f3`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/45a6f4e0188618f4ed3627fb4dfc6f03281711f3) |
| İş akışı | [Run 37553511724](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37553511724) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.731+784 (2026-10-07) — Canlı falcı görselleri + odadan çıkış sesi

- **Avatar/hediye logoları:** `/api/upload/get-url?path=…` URL'leri CDN yoluna çevrilir (CachedNetworkImage 401 giderildi — Canlı Falcılar kartları)
- **Sesli odadan çıkış:** TRTC `leave()` artık 400ms'de kesilmiyor; tamamlanana kadar beklenir (çıktıktan sonra ses devamı)
- **Koltuktan inme:** TRTC bırakıldıktan sonra izleyici (mic kapalı) yeniden bağlanır
- **Hediye combo animasyonu:** TweenSequence `t>1` StateError düzeltmesi (canlı fal UI donması)


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
