# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.619+670` |
| Tarih (UTC) | 2026-09-27 22:45 |
| Commit | [`766978e4d725ee360ab5718a145a42bf3251ab69`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/766978e4d725ee360ab5718a145a42bf3251ab69) |
| İş akışı | [Run 36355253248](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36355253248) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.619+670 (2026-09-27) — PR #397/#399 birleşimi + SSE (#400 kalanı)

- **Animasyon (#397):** `CurvedAnimation` initState/dispose — sızıntı ve gereksiz listener birikimi giderildi (home, fal, sesli oda, arama)
- **Google giriş (#399):** Cihazdaki APK SHA-1 parmak izi `AppSignature` ile gösterilir; `scripts/verify-google-signin-config.sh` güncellendi
- **SSE (#400 kalan):** Bağlantı nesli sayacı, 40 sn heartbeat toleransı, timeout’ta backoff’lu yeniden bağlanma
- **Reklam (#400 — önceki commit):** Ödüllü geçiş reklamı (`RewardedInterstitialAd`), üretim App ID manifest’te


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
