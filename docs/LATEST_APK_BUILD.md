# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.193+195` |
| Tarih (UTC) | 2026-06-12 08:10 |
| Commit | [`b6c503d8180b143e224d69d39d2b722114d34f47`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/b6c503d8180b143e224d69d39d2b722114d34f47) |
| İş akışı | [Run 27402890117](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27402890117) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.193+195 (2026-06-11)

### API dokümantasyonu ve gap analizi

- `docs/FLUTTER_API_DOCS.md` — tam API referansı (300+ endpoint)
- `docs/FLUTTER_GAP_ANALYSIS.md` — web/mobil eksik modül özeti

### Kritik / yüksek öncelik uygulamaları

- **Fal SSE:** `FortuneSseService` — oturumlu kullanıcıda `POST /api/fortunes/*` LLM akışı; `FortuneSessionPage` canlı metin önizlemesi
- **Reset password:** `/auth/reset-password?token=` native sayfa + `POST /api/auth/reset-password`
- **Achievements:** `AchievementsRemoteDataSource` + Growth Hub sunucu rozetleri
- **api_endpoints:** ajans, blog like/favorite, teller gifts, fortune pin/rate, auth reset/change
- `.gitignore`: `curl-*.json`, `t-*.json`, `ci-runs.json`


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
