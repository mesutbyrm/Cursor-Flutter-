# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.457+495` |
| Tarih (UTC) | 2026-09-10 02:15 |
| Commit | [`0fe7598279514c1924a1a2beae91cfd445309cdf`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/0fe7598279514c1924a1a2beae91cfd445309cdf) |
| İş akışı | [Run 34428015324](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34428015324) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.458+496 (2026-09-10) — Abacus backend entegrasyon, jeton katalog

### Backend kaynak seti
- `backend-docs/abacus-current/` + OpenAPI 502 path / 780 endpoint index materialize
- `_zip_analysis/CURRENT_BACKEND_SOURCE_SET.md` — Sep 10 canlı kod envanteri (852 endpoint)
- MCP `lib.mjs` schema fallback; parity betiği `scripts/abacus-openapi-parity.sh`

### Jeton / ödeme
- `GET /api/jeton` backend authoritative — API fail'de sahte preset katalog gösterilmez
- Ödeme bildirimi preset chip'leri yalnızca API paketlerinden


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
