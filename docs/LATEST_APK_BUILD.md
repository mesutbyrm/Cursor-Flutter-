# Son APK derlemesi

| Alan | Değer |
|------|--------|
| Sürüm | `1.0.265+268` |
| Tarih (UTC) | 2026-06-18 15:32 |
| Commit | [`14d8bfbebb0a894b96e0cf9ae6f57f48cd943fe8`](https://github.com/mesutbyrm/Cursor-Flutter-/commit/14d8bfbebb0a894b96e0cf9ae6f57f48cd943fe8) |
| İş akışı | [Run 27769813443](https://github.com/mesutbyrm/Cursor-Flutter-/actions/runs/27769813443) |
| APK | [canlifal-mobile-release.apk](https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk) |

## Özellikler

## 1.0.265+268 (2026-06-18)

### Canlı falcı — bağlantı ve çıkış düzeltmeleri

- **Falcı daveti SSE:** `GET /api/fortune-tellers/sessions/stream` — yayın/oda olmadan istek alımı
- **Poll:** Falcı profili yüklenene kadar bekler; `incoming` ucu öncelikli; 2 sn aralık
- **Kabul:** «Seansı Başlat» kapatılırsa artık otomatik red yok; seansa geçiş devam eder
- **Bekleme çıkışı:** İptal API başarısız olsa bile ekrandan çıkış; «Ana sayfaya dön» + zorla çık
- **Seans kapatma:** API hatasında da güvenli çıkış


_Bu dosya Build release APK iş akışı tarafından otomatik güncellenir._
