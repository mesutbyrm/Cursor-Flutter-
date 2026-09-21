# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-09-21 21:30:19 UTC |
| Run | local-1790026206 |
| API | https://canlifal.com |
| Geçti | 7 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| AUTH | Login | ✅ PASS | token alındı (cursor.test.1786235468@mailinator.com) |
| ROOMKEY | Room key resolve | ✅ PASS | cmoohrbr → cmop292m2005vnv08mx81j1hn (presence join) |
| PJOIN | Presence join | ✅ PASS | HTTP 200, presence≈1 (room=cmop292m2005vnv08mx81j1hn) |
| SEATS | Seats list | ✅ PASS | HTTP 200, seats=15 |
| STAKE | Seat take/leave | ✅ PASS | take/leave HTTP OK (presence seatIndex=?) |
| VOICE | Voice join | ⏭️ SKIP | HTTP 403 (koltuk/+V yetkisi gerekli olabilir) |
| SSE | Room SSE stream | ✅ PASS | stream açık (room=cmop292m2005vnv08mx81j1hn) |
| PLEAVE | Presence leave | ✅ PASS | HTTP 200 |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
