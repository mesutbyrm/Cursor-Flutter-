# Son APK derlemesi

> **Güncel:** Release gate **FINAL PASS** · **RELEASE READY: NO** (Psychic P0 cihaz) · [`DOCS_RELEASE_INDEX.md`](DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.453+491` |
| Tarih (UTC) | 2026-09-09 13:42 |
| Commit | [`7c81d391e8afe9a92253d433ac443f597bd4def1`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/7c81d391e8afe9a92253d433ac443f597bd4def1) |
| İş akışı | [Run 34357386140](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/34357386140) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.453+491 (2026-09-09) — Release gate düzeltmesi

### CI / release gate
- `dart-analyze-gate.sh`: `rg` → `grep` (CI'da yanlış PASS engellendi)
- Derleme hataları: `admin_hub_page` sınıf kapanışı, import path düzeltmeleri (voice/live)
- `acceptance-preflight.sh`: API erişim kontrolü + secret özeti; curl timeout (10s/60s)
- `run-release-gate.sh`: Gate 1/2 hata mesajları logda görünür


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
