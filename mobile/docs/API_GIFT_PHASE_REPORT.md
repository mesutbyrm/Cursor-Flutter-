# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 09:36:28 UTC |
| Run | local-1786268181 |
| API | https://canlifal.com |
| Geçti | 5 |
| Başarısız | 0 |
| Atlandı | 0 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| CATALOG | Gift catalog | ✅ PASS | 25 hediye |
| AUTH | Login | ✅ PASS | token alındı |
| WALLET | Wallet | ✅ PASS | bakiye=0 |
| INSUFF | Yetersiz jeton | ✅ PASS | HTTP 400 (insufficient_jeton) |
| SSE | SSE gift stream | ✅ PASS | stream açık |

**API acceptance testleri geçti** — istemci testleri bekleniyor.
