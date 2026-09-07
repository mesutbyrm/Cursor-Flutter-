# Acceptance Test Raporu


> **Güncel (2026-09-07):** **`1.0.371+409`** · Release gate **FINAL PASS** · Psychic P0 cihaz · [`../../docs/DOCS_RELEASE_INDEX.md`](../../docs/DOCS_RELEASE_INDEX.md)

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 09:36:35 UTC |
| Run | local-1786268188 |
| API | https://canlifal.com |
| Geçti | 5 |
| Başarısız | 0 |
| Atlandı | 0 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ✅ PASS | 12 sonuç, videoId+title |
| AUTH | Login | ✅ PASS | token alındı |
| QUEUE | Queue costs | ✅ PASS | kuyruk OK, audio=10 jeton |
| SONGREQ | Song request | ✅ PASS | HTTP 400 (Yetersiz jeton. 10 jeton gerekiyor.) |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık |

**API acceptance testleri geçti** — istemci testleri bekleniyor.
