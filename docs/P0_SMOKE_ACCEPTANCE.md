# Acceptance Test Raporu

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:48:47 UTC |
| Run | local-1786272503 |
| API | https://canlifal.com |
| Geçti | 25 |
| Başarısız | 0 |
| Atlandı | 1 |

## Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| P0 | Test account verify | ✅ PASS | cursor.test + cursor.host @mailinator.com |
| P0 | VIEWER login | ✅ PASS | userId=cmsl2h8fe007fns08myytsk6b |
| P0 | HOST login | ✅ PASS | userId=cmsl2h8tv007mns08gtxf0l8x teller=cmsl2ix6l008cns087j17rts6 |
| P0 | PSYCHIC login | ✅ PASS | HOST onaylı falcı (tellerId=cmsl2ix6l008cns087j17rts6) |
| P0 | Jeton viewer | ✅ PASS | bakiye=95680 (yeterli, dokunulmadı) |
| P0 | Jeton host | ✅ PASS | bakiye=3350 (yeterli, dokunulmadı) |
| P0 | GET /api/me authenticated | ✅ PASS | HTTP 200 |
| P0 | JWT refresh | ✅ PASS | production refresh OK |
| P0 | 401 without token | ✅ PASS | HTTP 401 |
| P0 | Voice presence join/leave/rejoin | ✅ PASS | join=200 leave=200 |
| P0 | Voice TRTC token | ✅ PASS | room=cmsloj2y800zcpk08z92tec8e |
| P0 | CREATE LIVE | ✅ PASS | streamId=cmsloj3gj00zppk0899azvest |
| P0 | TRTC token host | ✅ PASS | anchor |
| P0 | TRTC token viewer | ✅ PASS | audience |
| P0 | TRTC enterRoom/publish | ⏸️ BLOCKED | fiziksel cihaz yok |
| P0 | Gift wallet deduction | ✅ PASS | spent=1005 |
| P0 | PK create | ✅ PASS | battleId=cmslojd7a011epk08c806wrbe |
| P0 | PK accept | ✅ PASS | status=active |
| P0 | PK end | ✅ PASS | completed |
| P0 | Psychic REQUEST | ✅ PASS | sessionId=cmslojdl4011kpk087056m64j cost~50 |
| P0 | Psychic ACCEPT | ✅ PASS | status=active room=room_cmslojdl4011kpk087056m64j_1786272520203 |
| P0 | Psychic TRTC teller | ✅ PASS | token OK |
| P0 | Psychic TRTC viewer | ✅ PASS | token OK |
| P0 | Music song-request | ✅ PASS | spent=10 HTTP 200 |
| P0 | Auto fortune share | ✅ PASS | POST /api/social/posts postId=cmslojevh0124pk0842siymdj |
| P0 | SSE chat stream | ✅ PASS | events received |

**API testleri atlandı veya kısmen geçti** (1 atlandı) — istemci testleri bekleniyor.
