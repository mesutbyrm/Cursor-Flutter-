# API Parity — Stage 4 Final Gate

**Tarih:** 2026-08-09  
**Dal:** `cursor/backend-flutter-sync-0cde`  
**Üretim API:** `https://canlifal.com`  
**Mobil sürüm:** `1.0.144+178`

Stage 4 hedefi: Production master + API parity **son kapatma** — gerçek kullanıcı akışları, P0/P1 gap matrix, kod düzeltmeleri (duplicate live create guard).

---

## P0 / P1 Gap Matrix

| ID | Öncelik | Madde | STATUS | Not |
|----|---------|-------|--------|-----|
| P0-1 | P0 | Canlı yayın oluşturma — alan doğrulama (title, category, privacy) | **VERIFIED** | `live_broadcast_prep_page` + `createVideoStream` 400 → kullanıcı mesajı; API 400 INVALID_INPUT |
| P0-2 | P0 | Fortune paylaşımı — gerçek cihaz | **BLOCKED** | `adb devices` boş |
| P0-3 | P0 | Endpoint raporu CI otomasyonu | **BLOCKED** | `scripts/generate-endpoint-report.sh` + secrets yok |
| P1-1 | P1 | createVideoStream timeout/retry duplicate room | **FIXED** | Reconcile: `GET /api/video-streams?status=live` title eşleşmesi retry öncesi |
| P1-2 | P1 | TRTC token client üretimi | **VERIFIED** | Yalnızca `POST /api/trtc/token`; Agora prod RTC yok |
| P1-3 | P1 | approvedPsychicProvider + my-profile fallback | **VERIFIED** | Kod + `GET /api/fortune-tellers` 200; session E2E **BLOCKED** |
| P1-4 | P1 | Gift/jeton hard-coded 0 | **VERIFIED** | `coinCost` toplam; yetersiz jeton API mesajı |
| P1-5 | P1 | Music pause backend+player | **VERIFIED** | `controlPlayback` switch; duplicate videoId guard |
| P1-6 | P1 | Voice leave → peer offline | **VERIFIED** | Kod: presence leave + SSE; cihaz **BLOCKED** |
| P1-7 | P1 | SSE 20-cycle leak | **VERIFIED** | `sse_20_cycle_test.dart` + `sse-20-cycle.sh` 20/20 |
| P1-8 | P1 | Legacy `/api/v1`, `/api/payment`, rooms music | **VERIFIED** | `api_endpoint_canonical_contract_test.dart` |

---

## Feature Gate Matrix

| FEATURE | API | BACKEND | FLUTTER | REAL DEVICE | RESULT |
|---------|-----|---------|---------|-------------|--------|
| AUTH | login, refresh, /api/me | PASS | PASS | BLOCKED | **BLOCKED** |
| PROFILE | /api/me, /api/users/me | PASS | PASS | BLOCKED | **BLOCKED** |
| VOICE | presence join/leave, SSE | PASS | PASS | BLOCKED | **BLOCKED** |
| TRTC | POST /api/trtc/token | PASS | PASS | BLOCKED | **BLOCKED** |
| LIVE | POST /api/video-streams | PASS (NOT_A_TELLER) | PASS + reconcile retry | BLOCKED | **BLOCKED** |
| PK | /api/pk/* | PASS (no active PK) | PASS | BLOCKED | **BLOCKED** |
| GIFT | POST /api/gifts/send | PASS (insufficient) | PASS | BLOCKED (0 jeton) | **BLOCKED** |
| MUSIC | search, queue, playback | PASS | PASS | BLOCKED (playback) | **BLOCKED** |
| SSE | 5 endpoint + 20 cycle | PASS | PASS | BLOCKED | **BLOCKED** |
| CHAT | send + list | PASS | PASS | BLOCKED | **BLOCKED** |
| LIVE FALCI | fortune-tellers, requests | PASS (liste) | PASS | BLOCKED (session) | **BLOCKED** |

---

## Stage 4 Kod Değişiklikleri

### createVideoStream — duplicate stream önleme

Timeout/5xx retry öncesi:

1. `GET /api/video-streams?limit=20&status=live`
2. Başlık normalize eşleşmesi → mevcut `streamId` döndür
3. Eşleşme yoksa tek retry (`POST /api/video-streams`)

Böylece aynı yayın için iki `streamId` oluşması engellenir.

---

## Test Komutları (bu oturum)

```bash
cd mobile && flutter analyze && flutter test
bash scripts/acceptance-tests/api-final-phase.sh
bash scripts/acceptance-tests/api-stage3-phase.sh
bash scripts/acceptance-tests/sse-20-cycle.sh
```

---

## Parity Tamamlama Kriteri

**API PARITY TAMAMLANDI:** **HAYIR**

Gerekçe: AUTH, PROFILE, VOICE, TRTC, LIVE, PK, GIFT, MUSIC, SSE, CHAT, LIVE FALCI — tamamı gerçek cihazda PASS değil (`adb` yok; jeton 0; teller hesabı yok).

---

## Sonraki Adımlar (insan)

1. Fiziksel Android + `adb`
2. Test hesabına jeton (`ACCEPTANCE_TEST_USER_EMAIL` + bakiye)
3. `ACCEPTANCE_TELLER_EMAIL` / `ACCEPTANCE_TELLER_PASSWORD` (LIVE + LIVE FALCI)
4. İki cihaz PK + voice leave + TRTC publish/subscribe
5. `!istek` → gerçek audio playback doğrulama
