# API Parity — Stage 7 Final Report

| Alan | Değer |
|------|--------|
| Tarih | 2026-08-09 11:28 UTC |
| API | https://canlifal.com |
| Dal | `cursor/backend-flutter-sync-0cde` |
| Flutter | `1.0.144+178` |
| ADB | **BLOCKED** (`adb devices` boş) |

---

## Backend 500 Root Cause

**Endpoint:** `POST /api/video-streams/{streamId}/fortune-requests`

| Kontrol | Bulgu |
|---------|-------|
| Auth / JWT | ✅ Geçerli — sorun değil |
| Stream ownership | Viewer → host stream'i — beklenen |
| Stream status | Üretimde **streamId varlığı doğrulanmıyor** (geçersiz ID ile HTTP 200) — ayrı bug |
| Request body (üretim) | `{typeId, nickname, question, isHidden}` — **source of truth** |
| Legacy body | `displayName` + `fortuneType` (typeId yok) → Prisma FK hatası → **uncaught** → HTTP **500** |
| typeId / fortune type | `tek-soru`, `evet-hayır`, `detaylı-fal` — katalog FK |
| Prisma / transaction | Jeton decrement + kayıt; geçersiz typeId → constraint violation |
| Error handling | Genel catch → `Failed to create fortune request` (gerçek hata gizleniyor) |

### Fix durumu

| Ortam | Legacy body | typeId body | Durum |
|-------|-------------|-------------|-------|
| **canlifal.com (üretim)** | HTTP **500** | HTTP **200** | **NOT FIXED** (legacy) |
| **`api/` mirror (bu repo)** | → 400 veya 200 (map) | HTTP **200** | **FIXED** |

**Mirror fix dosyaları:**
- `api/src/lib/streamFortuneRequestService.ts` — `parseFortuneCreateBody()`, `mapFortuneCreateException()`
- `api/src/routes/video_streams.ts` — doğru status kodları, Prisma hata map
- `api/src/lib/streamFortuneRequestService.test.ts` — **12/12 PASS**

**Flutter fix:** `live_fortune_request_datasource.dart` — yalnızca üretim body (`typeId`, `nickname`, `question`, `isHidden`); legacy fallback **kaldırıldı**.

---

## Regression Test Sonuçları (üretim — 2026-08-09)

| Test | Beklenen | Gerçek | Sonuç |
|------|----------|--------|-------|
| Valid typeId body | 200 | 200 | ✅ PASS |
| Unauthorized | 401/403 | 401 | ✅ PASS |
| Invalid typeId | 400 | 400 | ✅ PASS |
| Duplicate pending | 400/409 | 400 | ✅ PASS |
| PATCH action=select | 200 | 200 | ✅ PASS |
| Invalid streamId | 404 | **200** | ❌ FAIL (üretim stream doğrulamıyor) |
| Legacy body | 400 veya 200 | **500** | ❌ FAIL (NOT FIXED prod) |

---

## Test Jetonları (yalnızca test hesapları)

| Hesap | INITIAL | TOP-UP | SPENT (oturum) | FINAL |
|-------|---------|--------|----------------|-------|
| TEST_VIEWER (`cursor.test.1786235468@mailinator.com`) | 88.523 | 0 | ~20 | **88.503** |
| TEST_HOST (`cursor.host.1786235468@mailinator.com`) | 2.350 | 0 | 0 | **2.350** |

`ACCEPTANCE_ADMIN_*` yok → otomatik top-up yapılamadı. Gerçek kullanıcılara dokunulmadı.

---

## Gate Sonuçları (kullanıcı formatı)

| Alan | Sonuç |
|------|-------|
| **Backend 500** | **NOT FIXED** (üretim legacy body); mirror **FIXED** |
| **Auth** | **PASS** |
| **Live** | **BLOCKED** (TRTC/camera/mic — adb yok); API **PASS** |
| **TRTC** | **BLOCKED** (adb yok); token API **PASS** |
| **Live Falcı** | **BLOCKED** (enterRoom/camera/mic); API **PASS** |
| **Voice Room** | **BLOCKED** (RTC cihaz); API **PASS** |
| **Gift** | **PASS** (API) / **BLOCKED** (cihaz SSE) |
| **PK Live** | **PASS** (API) / **BLOCKED** (2 cihaz) |
| **PK Voice** | **BLOCKED** (2 cihaz) |
| **Music** | **BLOCKED** (gerçek ses — adb yok); API request **PASS** |
| **SSE** | **PASS** (20/20 API) / **BLOCKED** (cihaz dispose) |
| **Auto Fortune** | **PASS** (POST /api/social/posts) |
| **flutter analyze** | **PASS** (0 ERROR) |
| **flutter test** | **PASS** (404 test) |
| **Integration** | **PARTIAL** (API PASS; prod legacy 500; cihaz BLOCKED) |
| **Real Device** | **BLOCKED** |

---

## Script Özeti

| Script | PASS | FAIL | SKIP/BLOCKED |
|--------|------|------|--------------|
| `api-acceptance.sh` | 17 | 0 | 1 |
| `p0-production-smoke.sh` | 25 | 0 | 1 |
| `api-stage7-phase.sh` | 6 | 2 | 1 |
| `sse-20-cycle.sh` | 20/20 | 0 | — |
| Backend unit tests | 12 | 0 | — |

---

## Live Falcı E2E (API katmanı — cihaz hariç)

| Aşama | Sonuç |
|-------|-------|
| PSYCHIC ONLINE | ✅ PASS |
| VIEWER REQUEST | ✅ PASS |
| BACKEND | ✅ PASS |
| PSYCHIC RECEIVE | ✅ PASS |
| ACCEPT | ✅ PASS |
| SESSION CREATE | ✅ PASS |
| TRTC TOKEN | ✅ PASS (sdkAppId + userSig) |
| BOTH JOIN | ⏸️ BLOCKED |
| CAMERA / MIC | ⏸️ BLOCKED |
| SESSION END | ⏸️ BLOCKED |

---

## Final Karar

```
API PARITY: NOT COMPLETE
```

**Gerekçe:**
- Üretimde legacy body hâlâ HTTP **500** (deploy bekliyor)
- Üretimde geçersiz `streamId` doğrulanmıyor (HTTP 200 — ayrı backend bug)
- Fiziksel cihaz / ADB yok → TRTC, Live, Music playback, PK 2-cihaz **BLOCKED**

**Sahte PASS yok. Test bypass yok. Mock success yok.**

---

## Sonraki Adımlar

1. `parseFortuneCreateBody` + `mapFortuneCreateException` patch'ini **canlifal.com** Next.js backend'e deploy et
2. Üretimde `streamId` varlık kontrolü ekle (404)
3. `ACCEPTANCE_ADMIN_*` GitHub Secrets ekle
4. Fiziksel Android + `adb devices` ile TRTC/Live/Music/PK cihaz testleri
