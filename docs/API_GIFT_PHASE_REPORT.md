# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:51:50 UTC |
| Run | local-1786272703 |
| API | https://canlifal.com |
| Geçti | 4 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| CATALOG | Gift catalog | ✅ PASS | 25 hediye |
| AUTH | Login | ✅ PASS | token alındı |
| WALLET | Wallet | ✅ PASS | bakiye=92628 |
| INSUFF | Yetersiz jeton | ⏭️ SKIP | hesapta yeterli jeton var — 500 jeton testi mümkün |
| SSE | SSE gift stream | ✅ PASS | stream açık |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
