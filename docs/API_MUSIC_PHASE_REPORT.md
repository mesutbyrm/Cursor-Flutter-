# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-09-07 19:29:39 UTC |
| Run | local-1788809372 |
| API | https://canlifal.com |
| Geçti | 2 |
| Başarısız | 1 |
| Atlandı | 3 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ⏭️ SKIP | giriş başarısız |
| AUTH | Login | ❌ FAIL | token yok |
| QUEUE | Queue costs | ⏭️ SKIP | token yok |
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| SONGREQ | Song request | ⏭️ SKIP | hesapta yeterli jeton — E2E mümkün |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık (room=cmoohrbrx00a4nt08zlkdjyil) |

**Release APK oluşturulmadı** — yukarıdaki başarısız testleri düzeltin.
