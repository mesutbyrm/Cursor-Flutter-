# API Parity — Stage 7 Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 11:20 UTC |
| API | https://canlifal.com |
| Dal | `cursor/backend-flutter-sync-0cde` |
| Flutter | `1.0.144+178` |
| ADB | **BLOCKED** (`adb devices` boş) |

---

## 1. Backend HTTP 500 — Root Cause

### Endpoint
`POST /api/video-streams/{streamId}/fortune-requests`

### Belirti
Legacy istemci gövdesi → **HTTP 500** + `{"error":"Failed to create fortune request"}`

### Kök neden analizi

| Kontrol | Bulgu |
|---------|-------|
| **Route** | Next.js App Router `POST /api/video-streams/[id]/fortune-requests` (üretim; bu repoda `api/src/routes/video_streams.ts` mirror) |
| **Authentication** | JWT Bearer geçerli — sorun değil |
| **JWT user** | `req.userId` → `loadUser()` OK |
| **Stream ownership** | Viewer başka kullanıcının yayınına istek gönderir — beklenen akış; 500 değil |
| **Psychic/teller validation** | Canlı yayın fal isteği teller onayı gerektirmez |
| **Request body (üretim)** | `{typeId, nickname, question, isHidden}` — **source of truth** |
| **Request body (legacy)** | `{displayName, fortuneType, priority, jetonCost}` — `typeId` yok |
| **Schema validation** | Üretimde legacy path `typeId` çözümlemesi yok → geçersiz/null FK |
| **Fortune request model** | `typeId` → `FortuneRequestType` katalog FK (`tek-soru`, `evet-hayır`, `detaylı-fal`) |
| **Prisma query** | Jeton düşümü + kayıt oluşturma; geçersiz `typeId` → constraint violation |
| **Error handling** | Genel `catch` → 500 + generic mesaj; gerçek exception gizleniyor |
| **Nullable / FK** | `typeId` null veya geçersiz → DB hatası |

### Kanıt (2026-08-09 retest)

```bash
# Legacy → 500 (üretim)
POST /api/video-streams/{id}/fortune-requests
{"displayName":"S7Legacy","question":"Stage7 legacy body test sorusu?",
 "fortuneType":"tarot","priority":"standard","jetonCost":50}
→ HTTP 500 "Failed to create fortune request"

# Üretim contract → 200
POST /api/video-streams/{id}/fortune-requests
{"typeId":"tek-soru","nickname":"S7Prod","question":"Stage7 production body test sorusu?",
 "isHidden":false}
→ HTTP 200, jetonAmount=5, requestId oluşur

# Geçersiz stream → 404 (500 değil)
POST /api/video-streams/invalid-id/fortune-requests → HTTP 404

# Auth yok → 401
POST (Authorization yok) → HTTP 401
```

### Fix (bu repo — `api/` mirror)

| Dosya | Değişiklik |
|-------|------------|
| `api/src/lib/streamFortuneRequestService.ts` | `parseFortuneCreateBody()` — dual parser; `fortuneType:tarot` → `typeId:tek-soru`; validation → **400** (500 değil) |
| `api/src/routes/video_streams.ts` | POST üretim yanıtı; PATCH `action:select/complete/refund`; DELETE iade; GET my-status |
| `api/src/lib/liveStreamExtrasStore.ts` | `hasPendingFortuneRequest`, `getPendingFortuneRequest` |
| `api/src/lib/streamFortuneRequestService.test.ts` | **9 unit test** — PASS |

> **Önemli:** canlifal.com üretim backend'i **ayrı Next.js reposunda** deploy edilir. Legacy 500 kapanması için `parseFortuneCreateBody` patch'inin **canlifal.com'a deploy edilmesi** gerekir. Flutter zaten `typeId` gövdesi gönderiyor.

---

## 2. Request Contract (Flutter vs Backend)

| Alan | Backend (üretim) | Flutter (`live_fortune_request_datasource.dart`) | Durum |
|------|------------------|--------------------------------------------------|-------|
| `typeId` | ✅ Zorunlu | ✅ `resolveTypeId()` → gönderilir | **UYUMLU** |
| `nickname` | ✅ Zorunlu | ✅ `displayName` → `nickname` | **UYUMLU** |
| `question` | ✅ Zorunlu (≥5 karakter) | ✅ Gönderilir | **UYUMLU** |
| `isHidden` | ✅ Opsiyonel | ✅ `false` | **UYUMLU** |
| `displayName` | Legacy alias → nickname | Fallback legacy path'te | Mirror'da map |
| `fortuneType` | Legacy → typeId map | Primary path'te kullanılmıyor | Mirror'da map |
| `jetonCost` | Katalogdan hesaplanır | Primary path'te gönderilmez | OK |
| `streamId` | URL path param | URL path param | OK |
| `userId` | JWT'den | Gönderilmez (JWT) | OK |
| `psychicId` | Bu endpoint'te yok | Gönderilmez | OK |
| `roomId` | Bu endpoint'te yok | Gönderilmez | OK |

**Geçerli `typeId` değerleri:** `tek-soru` (5 jeton), `evet-hayır` (10), `detaylı-fal` (50)

---

## 3. Auth / Ownership

| Senaryo | Beklenen | Üretim retest |
|---------|----------|---------------|
| Geçerli JWT + geçerli stream | 200 | ✅ PASS |
| Token yok | 401 | ✅ PASS |
| Geçersiz streamId | 404 | ✅ PASS |
| Yetersiz jeton | 400/402 | ✅ HTTP 400 |
| Bekleyen istek var | 400 | ✅ PASS |
| Başka kullanıcının stream'i | 200 (viewer isteği) | ✅ Beklenen |

---

## 4. Backend Regression Tests

`api/src/lib/streamFortuneRequestService.test.ts` — **9/9 PASS**

| Test | Sonuç |
|------|-------|
| Valid production body → success | ✅ PASS |
| Valid legacy body → mapped typeId | ✅ PASS |
| Invalid fortuneType → 400 (INVALID_TYPE) | ✅ PASS |
| Missing nickname → VALIDATION | ✅ PASS |
| Short question → VALIDATION | ✅ PASS |
| `message` alias for question | ✅ PASS |
| Empty typeId/fortuneType → INVALID_TYPE | ✅ PASS |
| Fortune action parse (select/complete/refund) | ✅ PASS |
| typeId resolution (tarot→tek-soru) | ✅ PASS |

---

## 5. Flutter Regression

| Komut | Sonuç |
|-------|-------|
| `flutter analyze` | ✅ PASS (0 ERROR, 323 info) |
| `flutter test` | ✅ PASS (404 test) |

Flutter primary path `typeId` gövdesi kullanıyor; backend fix sonrası ek Flutter değişikliği **gerekmedi**.

---

## 6. Test Kullanıcıları & Jeton

| Rol | E-posta | userId |
|-----|---------|--------|
| TEST_VIEWER | cursor.test.1786235468@mailinator.com | cmsl2h8fe007fns08myytsk6b |
| TEST_HOST / PSYCHIC | cursor.host.1786235468@mailinator.com | cmsl2h8tv007mns08gtxf0l8x |

| Hesap | Oturum başı (yaklaşık) | Top-up (agent) | Harcanan (oturum) | Son bakiye |
|-------|------------------------|----------------|-------------------|------------|
| VIEWER | ~90.418 | 0 (`ACCEPTANCE_ADMIN_*` yok) | ~1.895 (fal, falcı, gift, müzik) | **88.523** |
| HOST | ~2.700 | 0 | ~350 (gift testleri) | **2.350** |

Gerçek kullanıcı bakiyelerine dokunulmadı.

---

## 7. Acceptance / Integration Script Sonuçları

| Script | PASS | FAIL | SKIP/BLOCKED |
|--------|------|------|--------------|
| `api-acceptance.sh` | **17** | 0 | 1 (admin secret) |
| `p0-production-smoke.sh` | **25** | 0 | 1 (TRTC device) |
| `api-stage7-phase.sh` | 3 | **1** (legacy 500) | 1 (ADB) |
| `api-stage6-phase.sh` | 10 | **1** (admin jeton) | 1 (ADB) |
| `api-stage5-e2e.sh` | 12 | 0 | 14 (device/teller) |
| `sse-20-cycle.sh` | **20/20** | 0 | — |
| `device-trtc-smoke.sh` | — | — | **BLOCKED** (adb boş) |

---

## 8. Live Falcı E2E (API katmanı)

| Aşama | API | Sonuç |
|-------|-----|-------|
| PSYCHIC ONLINE | GET `/api/fortune-tellers` | ✅ PASS |
| VIEWER REQUEST | POST `/api/fortune-tellers/session` | ✅ PASS (P0) |
| BACKEND | sessionId + cost | ✅ PASS |
| PSYCHIC RECEIVE | GET pending sessions | ✅ PASS |
| ACCEPT | POST respond `action:accept` | ✅ PASS (P0) |
| SESSION CREATE | status=active, roomId | ✅ PASS |
| TRTC TOKEN | POST `/api/trtc/usersig` | ✅ PASS (teller+viewer) |
| BOTH JOIN | enterRoom | ⏸️ **BLOCKED** (adb yok) |
| CAMERA / MIC | publish/subscribe | ⏸️ **BLOCKED** |
| SESSION END | — | ⏸️ **BLOCKED** (cihaz) |

---

## 9. Gerçek Cihaz Gate

```
adb devices → (boş)
REAL DEVICE = BLOCKED
TRTC enterRoom / camera / mic / viewer subscribe = BLOCKED
Live PK (2 cihaz) = BLOCKED
Voice PK (2 cihaz) = BLOCKED
Music real audio playback = BLOCKED
```

Sahte PASS üretilmedi.

---

## 10. Sonuç Tablosu

| Test | API | Backend | Flutter | Device | Result |
|------|-----|---------|---------|--------|--------|
| Auth | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Live Create | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| TRTC | ✅ PASS (token) | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **BLOCKED** |
| Live Viewer | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Gift | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Live PK | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Voice Room | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Voice PK | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **BLOCKED** |
| Music | ✅ PASS (request) | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **BLOCKED** (playback) |
| SSE | ✅ PASS (20/20) | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Live Falcı | ✅ PASS | ✅ PASS | ✅ PASS | ⏸️ BLOCKED | **API PASS** |
| Fortune Share | ✅ PASS | ✅ PASS | ✅ PASS | — | **PASS** |
| Fortune Request (typeId) | ✅ PASS | ✅ PASS | ✅ PASS | — | **PASS** |
| Fortune Request (legacy) | ❌ 500 | ✅ mirror fix | N/A (primary typeId) | — | **FAIL** (prod deploy bekliyor) |

---

## 11. Final Decision

```
flutter analyze     = PASS
flutter test        = PASS
API acceptance      = PASS (17/0/1 skip)
Integration         = PARTIAL (legacy 500 prod; admin secret; device blocked)
Real device         = BLOCKED
TRTC                = BLOCKED (adb boş)
Live (device RTC)   = BLOCKED
Live Falcı (device) = BLOCKED
Voice Room (device) = BLOCKED
Live PK (2 device)  = BLOCKED
Voice PK (2 device) = BLOCKED
Music playback      = BLOCKED
SSE (device)        = BLOCKED

API PARITY: NOT COMPLETE
```

### Kalan blokörler

1. **Üretim legacy body HTTP 500** — `parseFortuneCreateBody` patch'i canlifal.com'a deploy edilmeli
2. **`ACCEPTANCE_ADMIN_*` secret** — CI'da admin jeton top-up ve admin bildirimi testleri
3. **Fiziksel Android + ADB** — TRTC, kamera, mikrofon, gerçek ses, 2-cihaz PK

### FAIL → ROOT CAUSE → FIX → RETEST

| | |
|---|---|
| **FAIL** | Legacy body HTTP 500 (üretim) |
| **Root cause** | `typeId` eksik; uncaught Prisma FK/constraint → generic catch 500 |
| **Fix** | `parseFortuneCreateBody()` + legacy map (`api/` mirror) |
| **Retest typeId** | ✅ PASS HTTP 200 |
| **Retest legacy prod** | ❌ FAIL HTTP 500 (deploy bekliyor) |
| **Retest mirror unit** | ✅ PASS 9/9 |
