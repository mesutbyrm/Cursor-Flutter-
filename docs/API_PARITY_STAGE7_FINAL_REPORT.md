# API Parity — Stage 7 Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 11:49 UTC |
| API | https://canlifal.com |
| Dal | `cursor/backend-flutter-sync-0cde` |
| Flutter | `1.0.144+178` |
| adb devices | boş |

---

## Backend fortune request 500: **NOT FIXED** (üretim legacy body)

**Endpoint:** `POST /api/video-streams/{id}/fortune-requests`

### Root cause (üretim — canlifal.com)
Legacy body (`displayName` + `fortuneType`, `typeId` yok) → Prisma FK/constraint → uncaught exception → HTTP **500** `Failed to create fortune request`

### Retest (2026-08-09 11:48 UTC)
| Body | HTTP | Sonuç |
|------|------|-------|
| `{typeId,nickname,question,isHidden}` | **200** | ✅ Flutter contract path çalışıyor |
| Legacy `{displayName,fortuneType,jetonCost}` | **500** | ❌ Üretim deploy bekliyor |

### Mirror fix (bu repo `api/`)
- `parseFortuneCreateBody()` — legacy map + validation → 400 (500 değil)
- `mapFortuneCreateException()` — Prisma hata map
- **12/12** unit test PASS

---

## Jeton (yalnızca test hesapları)

| Hesap | INITIAL | TOP-UP | SPENT | FINAL |
|-------|---------|--------|-------|-------|
| TEST_VIEWER | 85.443 | 0 | 1.175 | **84.268** |
| TEST_HOST | 2.000 | 0 | — | **2.150** |

Gerçek kullanıcı bakiyelerine dokunulmadı.

---

## Gate Sonuçları

| Alan | Sonuç |
|------|-------|
| **Backend fortune request 500** | **NOT FIXED** (üretim legacy); typeId path PASS |
| **flutter analyze** | **PASS** |
| **flutter test** | **PASS** (404) |
| **API acceptance** | **PASS** (17/0/1 skip) |
| **Integration** | **BLOCKED** (cihaz) |
| **Regression** | **FAIL** (legacy HTTP 500 üretimde) |
| **Real Device** | **BLOCKED** |
| **LIVE** | **BLOCKED** (adb; API PASS) |
| **LIVE FALCI** | **BLOCKED** (adb; API PASS) |
| **VOICE ROOM** | **BLOCKED** (adb; API PASS) |
| **TRTC** | **BLOCKED** (adb; token API PASS) |
| **PK** | **BLOCKED** (2 cihaz; API PASS) |
| **GIFT** | **PASS** |
| **MUSIC** | **BLOCKED** (gerçek ses; API PASS) |
| **SSE** | **PASS** (20/20) |

---

## Script Özeti

| Script | PASS | FAIL | BLOCKED |
|--------|------|------|---------|
| `api-acceptance.sh` | 17 | 0 | 1 |
| `p0-production-smoke.sh` | 25 | 0 | 1 |
| `api-stage7-phase.sh` | 7 | 1 | 1 |
| `sse-20-cycle.sh` | 20/20 | 0 | — |
| Backend unit | 12 | 0 | — |

---

## Live Falcı (API katmanı)

ONLINE → REQUEST → RECEIVE → ACCEPT → SESSION → TRTC TOKEN: **PASS**  
BOTH JOIN / CAMERA / MIC / END: **BLOCKED** (adb)

---

## Final Karar

```
API PARITY: NOT COMPLETE
```

**Blokörler:**
1. Üretim legacy body HTTP 500 — `parseFortuneCreateBody` patch canlifal.com'a deploy
2. Fiziksel Android + ADB yok
