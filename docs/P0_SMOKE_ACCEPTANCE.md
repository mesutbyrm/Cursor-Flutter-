# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:19:05 UTC |
| Run | local-1786270725 |
| API | https://canlifal.com |
| Geçti | 24 |
| Başarısız | 1 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| P0 | Test account verify | ✅ PASS | cursor.test + cursor.host @mailinator.com |
| P0 | VIEWER login | ✅ PASS | userId=cmsl2h8fe007fns08myytsk6b |
| P0 | HOST login | ✅ PASS | userId=cmsl2h8tv007mns08gtxf0l8x teller=cmsl2ix6l008cns087j17rts6 |
| P0 | PSYCHIC login | ✅ PASS | HOST onaylı falcı (tellerId=cmsl2ix6l008cns087j17rts6) |
| P0 | Jeton viewer | ✅ PASS | bakiye=1380 (yeterli, dokunulmadı) |
| P0 | Jeton host | ✅ PASS | bakiye=2400 (yeterli, dokunulmadı) |
| P0 | GET /api/me authenticated | ✅ PASS | HTTP 200 |
| P0 | JWT refresh | ✅ PASS | production refresh OK |
| P0 | 401 without token | ✅ PASS | HTTP 401 |
| P0 | Voice presence join/leave/rejoin | ✅ PASS | join=200 leave=200 |
| P0 | Voice TRTC token | ✅ PASS | room=cmslngy9700hppk08u3gr5hsl |
| P0 | CREATE LIVE | ✅ PASS | streamId=cmslngyt900i2pk08vvcg32yv |
| P0 | TRTC token host | ✅ PASS | anchor |
| P0 | TRTC token viewer | ✅ PASS | audience |
| P0 | TRTC enterRoom/publish | ⏸️ BLOCKED | fiziksel cihaz yok |
| P0 | Gift wallet deduction | ✅ PASS | spent=1000 |
| P0 | PK create | ✅ PASS | battleId=cmslnh65r00iqpk08kh5ji0j3 |
| P0 | PK accept | ✅ PASS | status=active |
| P0 | PK end | ✅ PASS | completed |
| P0 | Psychic REQUEST | ✅ PASS | sessionId=cmslnh6lu00iwpk08xs6zt6nc cost~50 |
| P0 | Psychic ACCEPT | ✅ PASS | status=active room=room_cmslnh6lu00iwpk08xs6zt6nc_1786270738225 |
| P0 | Psychic TRTC teller | ✅ PASS | token OK |
| P0 | Psychic TRTC viewer | ✅ PASS | token OK |
| P0 | Music song-request | ✅ PASS | spent=10 HTTP 200 |
| P0 | auto-fortune POST | ❌ FAIL | HTTP 405 (production 405?) |
| P0 | SSE chat stream | ✅ PASS | events received |

**Release APK oluşturulmadı** — yukarıdaki başarısız testleri düzeltin.
