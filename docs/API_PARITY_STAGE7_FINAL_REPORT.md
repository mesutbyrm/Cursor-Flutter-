# API Parity — Stage 7 Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 11:32 UTC |
| API | https://canlifal.com |
| Dal | `cursor/backend-flutter-sync-0cde` |
| Flutter | `1.0.144+178` |
| adb devices | boş |

---

## Jeton (yalnızca test hesapları)

| Hesap | INITIAL | TOP-UP | SPENT | FINAL |
|-------|---------|--------|-------|-------|
| TEST_VIEWER (`cursor.test.1786235468@mailinator.com`) | 87.338 | 0 | 890 | **86.448** |
| TEST_HOST (`cursor.host.1786235468@mailinator.com`) | 2.500 | 0 | 850 | **1.650** |

Gerçek kullanıcı bakiyelerine dokunulmadı. `ACCEPTANCE_ADMIN_*` yok → otomatik top-up yapılamadı.

---

## Backend 500 — Root Cause & Fix

**Endpoint:** `POST /api/video-streams/{id}/fortune-requests`

| Kontrol | Bulgu |
|---------|-------|
| JWT / auth | ✅ Geçerli |
| Request body (üretim) | `{typeId, nickname, question, isHidden}` |
| Legacy body | `displayName`+`fortuneType` (typeId yok) → Prisma FK → uncaught → **HTTP 500** |
| Mirror fix | `parseFortuneCreateBody()` + `mapFortuneCreateException()` — **12/12 unit PASS** |
| Flutter | Yalnızca typeId body gönderir (legacy fallback kaldırıldı) |

**Üretim retest (2026-08-09):**
- typeId body → HTTP **200** ✅
- legacy body → HTTP **500** ❌ (canlifal.com deploy bekliyor)

---

## Gate Sonuçları

BACKEND 500: **FAIL** (üretim legacy body HTTP 500; mirror FIXED; Flutter typeId path PASS)

AUTH: **PASS**

LIVE: **BLOCKED** (TRTC/camera/mic/publish — adb yok; API token/create PASS)

TRTC: **BLOCKED** (adb yok; backend userSig/token API PASS)

LIVE FALCI: **BLOCKED** (enterRoom/camera/mic — adb yok; API request/accept/token PASS)

VOICE ROOM: **BLOCKED** (RTC cihaz — adb yok; API presence/join PASS)

GIFT: **PASS** (API; jeton düşümü doğrulandı)

PK LIVE: **BLOCKED** (2 cihaz/onaylı host; API create/accept/end PASS)

PK VOICE: **BLOCKED** (2 cihaz)

MUSIC: **BLOCKED** (gerçek ses — adb yok; API song-request PASS)

SSE: **PASS** (20/20 API cycle)

AUTO FORTUNE: **PASS** (POST /api/social/posts + feed)

FLUTTER ANALYZE: **PASS** (0 ERROR)

FLUTTER TEST: **PASS** (404 test)

INTEGRATION: **BLOCKED** (cihaz testleri yapılamadı; API katmanı PASS)

REGRESSION: **FAIL** (legacy body üretimde HTTP 500)

REAL DEVICE: **BLOCKED**

---

## Script Özeti

| Script | PASS | FAIL | BLOCKED/SKIP |
|--------|------|------|--------------|
| `api-acceptance.sh` | 17 | 0 | 1 |
| `p0-production-smoke.sh` | 25 | 0 | 1 |
| `api-stage7-phase.sh` | 7 | 1 | 1 |
| `api-stage6-phase.sh` | 10 | 1 | 1 |
| `api-stage5-e2e.sh` | 12 | 0 | 14 |
| `sse-20-cycle.sh` | 20/20 | 0 | — |
| Backend unit (`streamFortuneRequestService`) | 12 | 0 | — |

---

## Live Falcı E2E (API)

| Aşama | Sonuç |
|-------|-------|
| PSYCHIC ONLINE | PASS |
| VIEWER REQUEST | PASS |
| BACKEND | PASS |
| PSYCHIC RECEIVE | PASS |
| ACCEPT | PASS |
| SESSION CREATE | PASS |
| TRTC TOKEN | PASS |
| BOTH JOIN / CAMERA / MIC / END | BLOCKED (adb) |

---

## Final Karar

```
API PARITY: NOT COMPLETE
```

**Blokörler:**
1. Üretim legacy body HTTP 500 — `parseFortuneCreateBody` patch canlifal.com'a deploy edilmeli
2. Fiziksel Android + ADB yok — TRTC, Live, Music playback, PK 2-cihaz testleri yapılamadı

Sahte PASS yok. Mock success yok. Test bypass yok.
