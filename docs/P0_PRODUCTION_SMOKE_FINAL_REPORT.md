# P0 Production Smoke — Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:19:05 UTC |
| API | https://canlifal.com |
| Run | local-1786270725 |

## Test Accounts

| Rol | E-posta | userId | Jeton (başlangıç → son) | Harcanan |
|-----|---------|--------|---------------------------|----------|
| TEST_VIEWER | cursor.test.1786235468@mailinator.com | cmsl2h8fe007fns08myytsk6b | 1380 → 220 | 1160 |
| TEST_HOST | cursor.host.1786235468@mailinator.com | cmsl2h8tv007mns08gtxf0l8x | 2400 → 2550 | -150 |
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
| Auto Fortune Share | FAIL | POST /api/social/posts/auto-fortune HTTP 405 | backend route deploy | pending |
| SSE | PASS (API) | dispose/cihaz | flutter widget test | API PASS |

## Detaylı Sonuçlar

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

**P0 STATUS:** FAIL

**API PARITY:** NOT COMPLETE

## Otomatik test paketleri

| Paket | Sonuç |
|-------|--------|
| `flutter analyze` | PASS (0 error) |
| `flutter test` | PASS (404 passed, 2 skipped) |
| `api-final-phase.sh` | PASS |
| `p0-production-smoke.sh` | 24 PASS / 1 FAIL / 1 BLOCKED |
| `run-acceptance-tests.sh` | Legacy `/api/live` düzeltildi — yeniden çalıştırılmalı |

## Kalan BLOCKED (cihaz gerekli — bilgisayar yok)

- TRTC enterRoom / publish / subscribe / camera / mic
- Gerçek müzik ses playback
- Gift animasyon ekranda
- SSE dispose (widget lifecycle)

## Tek FAIL (backend)

- `POST /api/social/posts/auto-fortune` → **HTTP 405** (production'da route deploy edilmemiş veya method yanlış)

> Gerçek RTC/ses/kamera/animasyon cihaz olmadan BLOCKED sayılır. API PARITY COMPLETE yazılmaz.
