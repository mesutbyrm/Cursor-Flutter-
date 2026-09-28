# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.619+670` |
| Tarih (UTC) | 2026-09-28 00:28 |
| Commit | [`aadf07b467aea0a6d1bb322fb72cfc2102fecc80`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/aadf07b467aea0a6d1bb322fb72cfc2102fecc80) |
| İş akışı | [Run 36360938226](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/36360938226) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.619+670 (2026-09-27) — PR #397/#399 birleşimi + SSE (#400 kalanı)

- **Animasyon (#397):** `CurvedAnimation` initState/dispose — sızıntı ve gereksiz listener birikimi giderildi (home, fal, sesli oda, arama)
- **Google giriş (#399):** Cihazdaki APK SHA-1 parmak izi `AppSignature` ile gösterilir; `scripts/verify-google-signin-config.sh` güncellendi
- **SSE (#400 kalan):** Bağlantı nesli sayacı, 40 sn heartbeat toleransı, timeout’ta backoff’lu yeniden bağlanma
- **Reklam (#400 — önceki commit):** Ödüllü geçiş reklamı (`RewardedInterstitialAd`), üretim App ID manifest’te


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
