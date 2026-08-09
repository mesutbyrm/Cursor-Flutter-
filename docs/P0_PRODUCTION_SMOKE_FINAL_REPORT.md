# P0 Production Smoke — Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 11:01:52 UTC |
| API | https://canlifal.com |
| Run | local-1786273288 |

## Test Accounts

| Rol | E-posta | userId | Jeton (başlangıç → son) | Harcanan |
|-----|---------|--------|---------------------------|----------|
| TEST_VIEWER | cursor.test.1786235468@mailinator.com | cmsl2h8fe007fns08myytsk6b | 91578 → 90418 | 1160 |
| TEST_HOST | cursor.host.1786235468@mailinator.com | cmsl2h8tv007mns08gtxf0l8x | 2700 → 2850 | -150 |
| TEST_PSYCHIC | cursor.host.1786235468@mailinator.com (HOST teller) | cmsl2ix6l008cns087j17rts6 | — | — |

## Maliyetler (backend)

- Hediye (elmas): 500 jeton
- Müzik !istek: 10 jeton
- Oda oluşturma: 100 jeton
- Falcı seansı: 50 jeton

## Sonuç Tablosu

| Test | Result | Root Cause | Fix | Retest |
|---|---|---|---|---|
| Auth | PASS | - | - | PASS |
| Production JWT | PASS | - | - | PASS |
| Voice Room | PASS (API) | RTC/mic cihaz | telefon | API PASS |
| Live Create | PASS | - | - | PASS |
| Live TRTC | PASS (token) | cihaz RTC yok | telefon+adb | API PASS |
| Live Viewer | PASS (token+join) | publish/subscribe cihaz | telefon | API PASS |
| Gift | PASS (API) | animasyon cihaz | telefon | API PASS |
| PK | PASS | - | - | PASS |
| Live Falcı | PASS (API) | camera/mic cihaz | telefon | API PASS |
| Music | PASS (API) | gerçek ses playback cihaz | telefon | API PASS |
| Auto Fortune Share | PASS | auto-fortune 405 fallback | Flutter+test script | PASS |
| SSE | PASS (API) | dispose/cihaz | flutter widget test | API PASS |

## Detaylı Sonuçlar

| # | Test | Durum | Detay |
|---|------|-------|-------|
| P0 | Test account verify | ✅ PASS | cursor.test + cursor.host @mailinator.com |
| P0 | VIEWER login | ✅ PASS | userId=cmsl2h8fe007fns08myytsk6b |
| P0 | HOST login | ✅ PASS | userId=cmsl2h8tv007mns08gtxf0l8x teller=cmsl2ix6l008cns087j17rts6 |
| P0 | PSYCHIC login | ✅ PASS | HOST onaylı falcı (tellerId=cmsl2ix6l008cns087j17rts6) |
| P0 | Jeton viewer | ✅ PASS | bakiye=91578 (yeterli, dokunulmadı) |
| P0 | Jeton host | ✅ PASS | bakiye=2700 (yeterli, dokunulmadı) |
| P0 | GET /api/me authenticated | ✅ PASS | HTTP 200 |
| P0 | JWT refresh | ✅ PASS | production refresh OK |
| P0 | 401 without token | ✅ PASS | HTTP 401 |
| P0 | Voice presence join/leave/rejoin | ✅ PASS | join=200 leave=200 |
| P0 | Voice TRTC token | ✅ PASS | room=cmslozwbp019bpk08ekqhqr5u |
| P0 | CREATE LIVE | ✅ PASS | streamId=cmslozwvp019opk08dpr8dp8b |
| P0 | TRTC token host | ✅ PASS | anchor |
| P0 | TRTC token viewer | ✅ PASS | audience |
| P0 | TRTC enterRoom/publish | ⏸️ BLOCKED | fiziksel cihaz yok |
| P0 | Gift wallet deduction | ✅ PASS | spent=1000 |
| P0 | PK create | ✅ PASS | battleId=cmslp079l01acpk08zr8dj041 |
| P0 | PK accept | ✅ PASS | status=active |
| P0 | PK end | ✅ PASS | completed |
| P0 | Psychic REQUEST | ✅ PASS | sessionId=cmslp07o101aipk082lylkdpt cost~50 |
| P0 | Psychic ACCEPT | ✅ PASS | status=active room=room_cmslp07o101aipk082lylkdpt_1786273305693 |
| P0 | Psychic TRTC teller | ✅ PASS | token OK |
| P0 | Psychic TRTC viewer | ✅ PASS | token OK |
| P0 | Music song-request | ✅ PASS | spent=10 HTTP 200 |
| P0 | Auto fortune share | ✅ PASS | POST /api/social/posts postId=cmslp090y01b3pk08y69ca3q4 |
| P0 | SSE chat stream | ✅ PASS | events received |

**P0 STATUS:** BLOCKED

**API PARITY:** NOT COMPLETE

> Gerçek RTC/ses/kamera/animasyon cihaz olmadan BLOCKED sayılır. API PARITY COMPLETE yazılmaz.
