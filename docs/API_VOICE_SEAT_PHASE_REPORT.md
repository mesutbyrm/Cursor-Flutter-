# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-21 01:53:28 UTC |
| Run | local-1787277201 |
| API | https://canlifal.com |
| Geçti | 7 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| AUTH | Login | ✅ PASS | token alındı (cursor.test.1786235468@mailinator.com) |
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmoohrbrx00a4nt08zlkdjyil |
| PJOIN | Presence join | ✅ PASS | HTTP 200, presence≈1 (room=cmoohrbrx00a4nt08zlkdjyil) |
| SEATS | Seats list | ✅ PASS | HTTP 200, seats=11 |
| STAKE | Seat take/leave | ✅ PASS | take/leave HTTP OK (presence seatIndex=?) |
| VOICE | Voice join | ⏭️ SKIP | HTTP 403 (koltuk/+V yetkisi gerekli olabilir) |
| SSE | Room SSE stream | ✅ PASS | stream açık (room=cmoohrbrx00a4nt08zlkdjyil) |
| PLEAVE | Presence leave | ✅ PASS | HTTP 200 |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
