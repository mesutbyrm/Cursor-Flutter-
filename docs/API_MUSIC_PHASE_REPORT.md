# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-20 11:33:57 UTC |
| Run | local-1787225629 |
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
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| SONGREQ | Song request | ⏭️ SKIP | hesapta yeterli jeton — E2E mümkün |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık (room=cmoohrbrx00a4nt08zlkdjyil) |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
