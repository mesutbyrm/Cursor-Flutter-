# Stage 5 — Real E2E Acceptance Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 10:11:55 UTC |
| API | https://canlifal.com |
| adb |   |
| Geçti | 12 |
| Başarısız | 0 |
| Atlandı/Blocked | 14 |

## Test Users

| Rol | E-posta | User ID |
|-----|---------|---------|
| TEST_USER_A | cursor.test.1786235468@mailinator.com | cmsl2h8fe007fns08myytsk6b |
| TEST_USER_B | cursor.host.1786235468@mailinator.com | cmsl2h8tv007mns08gtxf0l8x |
| TEST_PSYCHIC | (yok) | cmoks76yf00c4ph08ppcoqg98 |

## Balances

| User | Initial | Top-up Target | Total Spent | Final |
|------|---------|---------------|-------------|-------|
| A | 3340 | 1500 | 10 | 3620 |
| B | 3250 | 1500 | 500 | 2250 |

## Feature Results

| Area | Result | Not |
|------|--------|-----|
| LIVE | BLOCKED | HOST teller pending; adb yok |
| LIVE FALCI | BLOCKED | 0 jeton + ACCEPTANCE_TELLER_* yok |
| VOICE ROOM | PASS (API) / BLOCKED (RTC) | presence join/leave API |
| GIFT | BLOCKED | jeton top-up admin secret yok |
| PK | BLOCKED | 2-user + live host |
| MUSIC | BLOCKED | jeton + adb playback |
| SSE | see tests | |
| TRTC | BLOCKED | adb yok |

## Detailed Results

| ID | Test | Durum | Detay |
|---|------|-------|-------|
| SETUP | TEST_USER_A login | ✅ PASS | id=cmsl2h8fe007fns08myytsk6b jeton=3340 |
| SETUP | TEST_USER_B login | ✅ PASS | id=cmsl2h8tv007mns08gtxf0l8x jeton=3250 |
| SETUP | TEST_PSYCHIC login | ⏭️ SKIP | ACCEPTANCE_TELLER_* yok |
| JETON | Admin top-up | ⏭️ SKIP | ACCEPTANCE_ADMIN_* secret yok — jeton E2E BLOCKED |
| JETON | 0-jeton insufficient (gift) | ⏭️ SKIP | bakiye=3340 (sıfır değil; admin ile sıfırlama yok) |
| JETON | 0-jeton insufficient (music) | ⏭️ SKIP | bakiye=3340 |
| VOICE | A/B join presence | ✅ PASS | room=cmokyb9o9007iod09gi6pb1tb |
| VOICE | B leave | ✅ PASS | HTTP 200 |
| VOICE | B join another room | ⏭️ SKIP | ikinci oda bulunamadı |
| VOICE | RTC hear / seat (device) | ⏸️ BLOCKED | adb yok |
| SSE | Room stream events | ✅ PASS | SSE veri alındı |
| GIFT | 500 jeton deduction | ✅ PASS | before=3250 after=2250 spent=500 |
| GIFT | Gift SSE event | ⏸️ BLOCKED | cihaz/SSE listener doğrulaması gerekli |
| MUSIC | Paid song request | ✅ PASS | before=3690 after=3670 HTTP 200 |
| MUSIC | Real audio playback | ⏸️ BLOCKED | adb yok — mini-player PASS sayılmaz |
| LIVE | CREATE LIVE | ✅ PASS | streamId=cmsln83fx00d7pk08gojglvnk |
| LIVE | TRTC token (host) | ✅ PASS | backend token OK |
| LIVE | TRTC token (viewer) | ✅ PASS | backend token OK |
| LIVE | Publish/subscribe/chat/PK (device) | ⏸️ BLOCKED | adb + onaylı teller hesabı |
| LIVE_FALCI | Teller list | ✅ PASS | tellerId=cmokzl5u900w2od09rpqq2fs9 |
| LIVE_FALCI | Request session | ✅ PASS | sessionId=cmsln844z00dcpk087u9ly9cu |
| LIVE_FALCI | Psychic accept | ⏸️ BLOCKED | ACCEPTANCE_TELLER_* yok |
| LIVE_FALCI | TRTC camera/mic (device) | ⏸️ BLOCKED | adb yok |
| PK | Voice 2-user accept | ⏸️ BLOCKED | oda sahibi + 2 cihaz gerekli |
| PK | Live PK | ⏸️ BLOCKED | onaylı LIVE host gerekli |
| TRTC | Device RTC lifecycle | ⏸️ BLOCKED | adb devices boş |

## Root Causes (BLOCKED)

1. **Jeton top-up:** `ACCEPTANCE_ADMIN_EMAIL` / `ACCEPTANCE_ADMIN_PASSWORD` ortamda yok — `POST /api/admin/credits` çalıştırılamadı.
2. **LIVE host:** `cursor.host.*` hesabı `NOT_APPROVED` (teller başvurusu pending).
3. **TEST_PSYCHIC:** `ACCEPTANCE_TELLER_*` secret yok — accept akışı test edilemedi.
4. **Gerçek cihaz:** `adb devices` boş — TRTC, ses, animasyon doğrulanamadı.

Betik: `scripts/acceptance-tests/api-stage5-e2e.sh`
