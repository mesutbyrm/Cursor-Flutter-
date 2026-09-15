# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-09-15 19:19:28 UTC |
| Run | local-1789499957 |
| API | https://canlifal.com |
| Geçti | 5 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ✅ PASS | 12 sonuç, videoId+title |
| AUTH | Login | ✅ PASS | token alındı (cursor.test.1786235468@mailinator.com) |
| QUEUE | Queue costs | ✅ PASS | kuyruk OK (fiyat song-request yanıtından) |
| ROOMKEY | Room key resolve | ✅ PASS | fallback oda (ban?) cmoohrbr → cmokyb9o9007iod09gi6pb1tb |
| SONGREQ | Song request | ⏭️ SKIP | hesapta yeterli jeton — E2E mümkün |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık (room=cmokyb9o9007iod09gi6pb1tb) |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
