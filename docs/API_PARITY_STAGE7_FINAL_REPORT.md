# API Parity — Stage 7 Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 11:00:16 UTC |
| API | https://canlifal.com |

## Backend 500 Root Cause

Üretim `POST /api/video-streams/{id}/fortune-requests` endpoint'i **typeId** tabanlı şema kullanır.
Legacy body (`displayName` + `fortuneType` without `typeId`) gönderildiğinde sunucu geçersiz FK/constraint ile **uncaught exception** → HTTP **500** (`Failed to create fortune request`).

**Doğru body:** `{typeId, nickname, question, isHidden}` → HTTP 200

## Backend Fix (api/ mirror — bu repo)

- `api/src/lib/streamFortuneRequestService.ts` — dual body parser, typeId catalog, action map
- `api/src/routes/video_streams.ts` — POST/PATCH/DELETE/my-status üretim uyumu
- Legacy `fortuneType: tarot` → `typeId: tek-soru` map (500 yerine 400 veya 200)

> **Not:** canlifal.com üretim backend'i ayrı Next.js reposunda deploy edilir. Bu fix `api/` mirror'da uygulandı; üretimde legacy 500 kapanması için aynı patch'in canlifal.com'a deploy edilmesi gerekir.

## Test Kullanıcıları & Jeton

| Rol | userId | Başlangıç | Son |
|-----|--------|-----------|-----|
| TEST_VIEWER | cmsl2h8fe007fns08myytsk6b | 91588 | 91583 |

## Stage 7 Sonuçları

| Test | Sonuç |
|------|-------|
| POST typeId body (production) | PASS |
| POST legacy body (backward compat) | FAIL on production until deploy |
| PATCH select | PASS |
| Real device ADB | BLOCKED |

## Gate Checklist

| Gate | Sonuç |
|------|-------|
| flutter analyze | (see CI log) |
| flutter test | (see CI log) |
| API acceptance | (see api-acceptance.sh) |
| Integration | (see stage5/6 scripts) |
| Real device | **BLOCKED** |
| Live Falcı API | PASS (typeId) |
| Live PK API | PASS (stage6) |
| TRTC device | **BLOCKED** |

## Final

```
API PARITY:        NOT COMPLETE
P0:                BLOCKED (TRTC cihaz)
LIVE:              BLOCKED (RTC cihaz; API PASS)
LIVE FALCI:        PASS (API)
SESLİ ODA:         BLOCKED (RTC cihaz; API PASS)
TRTC:              BLOCKED (adb boş)
PK:                PASS (voice API)
GIFT:              PASS
MUSIC:             PASS
SSE:               PASS
```
