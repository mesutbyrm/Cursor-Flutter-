# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-09-07 19:25:26 UTC |
| Run | local-1788809124 |
| API | https://canlifal.com |
| Geçti | 4 |
| Başarısız | 0 |
| Atlandı | 2 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ⏭️ SKIP | giriş başarısız |
| AUTH | Login | ✅ PASS | token alındı (cursor.test.1786235468@mailinator.com) |
| QUEUE | Queue costs | ✅ PASS | kuyruk OK (fiyat song-request yanıtından) |
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| SONGREQ | Song request | ⏭️ SKIP | hesapta yeterli jeton — E2E mümkün |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık (room=cmoohrbrx00a4nt08zlkdjyil) |

**API testleri atlandı veya kısmen geçti** (2 atlandı) — istemci testleri bekleniyor.
