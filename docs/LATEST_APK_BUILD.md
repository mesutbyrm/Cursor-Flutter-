# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.704+757` |
| Tarih (UTC) | 2026-10-03 22:17 |
| Commit | [`acac15b5da9224e70b33cf7350f1b44e65fdfc6f`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/acac15b5da9224e70b33cf7350f1b44e65fdfc6f) |
| İş akışı | [Run 37156655890](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/37156655890) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.704+757 (2026-10-03) — Reklam ödülü sunucu doğrulamalı (AdMob SSV) ile uyumlu

- **Reklam ödülü:** reklam bitince istemci önce ~6 sn bakiyeyi yoklar; AdMob SSV (`/api/ads/ssv/admob`) ödülü sunucuda verdiyse bakiye artar ve istemci **ek ödül çağrısı yapmaz** (çifte ödül yok). SSV ödülü gelmezse (bayrak kapalı/gecikme) eski `/api/user/watch-ad` yedeğine düşer — SSV bayrağı açılınca istemci çağrısı kendiliğinden devre dışı kalır


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
