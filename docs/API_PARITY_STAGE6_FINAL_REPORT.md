# API Parity — Stage 6 Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:48:28 UTC |
| API | https://canlifal.com |

## Environment Blockers
- ADB cihaz yok (dış bağımlılık)

## Fixable (config/credentials)
- Jeton top-up: ACCEPTANCE_ADMIN_* yok — manuel admin panel gerekli

## Test Accounts

| Rol | userId | Jeton başlangıç → son |
|-----|--------|------------------------|
| TEST_VIEWER | cmsl2h8fe007fns08myytsk6b | 95680 → 93675 |
| TEST_HOST | cmsl2h8tv007mns08gtxf0l8x | 3350 → 3950 |
| TEST_PSYCHIC | cmsl2ix6l008cns087j17rts6 (HOST) | — |

## Sonuç Tablosu

| Test | Result | Root Cause | Fix | Retest |
|---|---|---|---|---|
| Profile | PASS | jeton OK | - | PASS |
| Auth | PASS | - | - | PASS |
| Live Create | PASS | - | video-streams | PASS |
| Live TRTC | PASS (token) | enterRoom cihaz | telefon+adb | API PASS |
| Live Viewer | PASS (token) | subscribe cihaz | telefon | API PASS |
| Gift | PASS | - | elmas fallback | PASS |
| Auto Fortune | PASS | auto-fortune 405 → posts fallback | Flutter datasource fix | PASS |
| Live Falcı | PASS (create+select) | eski body 500 → typeId fix | Flutter+test script | PASS |
| PK Voice | PASS | - | stage5 unblock | PASS |
| PK Live | BLOCKED | live PK 2-stream cihaz | telefon | - |
| Voice Room | PASS (API) | RTC cihaz | adb | API PASS |
| Music | PASS (API) | playback cihaz | adb | API PASS |
| SSE | PASS | dispose cihaz | - | API PASS |

## Root Cause Örnekleri

### FAIL: auto-fortune HTTP 405
- **Root cause:** Production'da `POST /api/social/posts/auto-fortune` route deploy edilmemiş
- **Fix:** Flutter `shareFortuneAuto` → 405'te `POST /api/social/posts` fallback (Stage 6)
- **Retest:** PASS (posts + feed)

### FAIL: Live fortune request HTTP 500
- **Root cause:** Backend `POST /api/video-streams/{id}/fortune-requests` 500
- **Fix:** canlifal.com backend (Flutter dışı)
- **Retest:** pending

### BLOCKED: TRTC enterRoom
- **Root cause:** ADB cihaz yok (Cloud VM)
- **Fix:** Fiziksel Android + USB
- **Retest:** BLOCKED

## Final Decision

| Kontrol | Sonuç |
|---------|--------|
| flutter analyze | PASS |
| flutter test | PASS |
| API acceptance | FAIL |
| Integration (API) | FAIL |
| Real device | BLOCKED |

**P0 STATUS:** FAIL

**API PARITY:** NOT COMPLETE
