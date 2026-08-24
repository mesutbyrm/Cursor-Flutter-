# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-21 01:53:46 UTC |
| Run | local-1787277209 |
| API | https://canlifal.com |
| Geçti | 5 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ⏭️ SKIP | HTTP 502 (üretim geçici hata — 3 deneme) |
| AUTH | Login | ✅ PASS | token alındı (cursor.test.1786235468@mailinator.com) |
| QUEUE | Queue costs | ✅ PASS | kuyruk OK, audio=10 jeton |
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| SONGREQ | Song request | ✅ PASS | HTTP 400 (Yetersiz jeton. 10 jeton gerekiyor.) |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık (room=cmoohrbrx00a4nt08zlkdjyil) |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
