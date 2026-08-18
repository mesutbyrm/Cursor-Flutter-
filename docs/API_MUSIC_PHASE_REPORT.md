# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-18 22:27:15 UTC |
| Run | local-1787092028 |
| API | https://canlifal.com |
| Geçti | 6 |
| Başarısız | 0 |
| Atlandı | 0 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| SEARCH | Music search | ✅ PASS | 12 sonuç, videoId+title |
| AUTH | Login | ✅ PASS | token alındı (cursor.test.1786235468@mailinator.com) |
| QUEUE | Queue costs | ✅ PASS | kuyruk OK, audio=10 jeton |
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| SONGREQ | Song request | ✅ PASS | HTTP 400 (Yetersiz jeton. 10 jeton gerekiyor.) |
| SSE_DJ | SSE dj stream | ✅ PASS | stream açık (room=cmoohrbrx00a4nt08zlkdjyil) |

**API acceptance testleri geçti** — istemci testleri bekleniyor.
