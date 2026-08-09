# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:51:57 UTC |
| Run | local-1786272710 |
| API | https://canlifal.com |
| Geçti | 4 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ✅ PASS | 12 sonuç, videoId+title |
| AUTH | Login | ✅ PASS | token alındı |
| QUEUE | Queue costs | ✅ PASS | kuyruk OK (fiyat song-request yanıtından) |
| SONGREQ | Song request | ⏭️ SKIP | hesapta yeterli jeton — E2E mümkün |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
