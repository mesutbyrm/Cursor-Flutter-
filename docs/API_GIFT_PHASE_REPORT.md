# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 09:51:08 UTC |
| Run | local-1786269062 |
| API | https://canlifal.com |
| Geçti | 4 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| CATALOG | Gift catalog | ✅ PASS | 25 hediye |
| AUTH | Login | ✅ PASS | token alındı |
| WALLET | Wallet | ✅ PASS | bakiye=5280 |
| INSUFF | Yetersiz jeton | ⏭️ SKIP | hesapta yeterli jeton var — 500 jeton testi mümkün |
| SSE | SSE gift stream | ✅ PASS | stream açık |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
