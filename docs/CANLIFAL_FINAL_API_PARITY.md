# CANLIFAL FINAL API PARITY

| Alan | Değer |
|------|--------|
| Tarih (UTC) | 2026-08-10 13:50 |
| Sürüm | `1.0.146+180` |
| Base URL | `https://canlifal.com` |
| Kaynak | `docs/API_ENDPOINT_MATRIX.md`, P0/Stage5/Stage8, `sse-20-cycle.sh` |

## Özet

Path eşleşmesi (kod) ≠ runtime CONNECTED. Gerçek Android cihaz doğrulaması **yok** (`adb` boş).

---

## Envanter

| Metrik | Sayı |
|--------|------|
| TOTAL BACKEND ENDPOINTS | **438** (unique path; 690 handler) |
| Flutter normalized paths | 436 |
| Path-matched (kod) | 256 |
| Flutter-only (review) | 180 |

## Runtime sınıflandırma (gerçek cihaz kuralı)

| RUNTIME STATUS | Sayı | Açıklama |
|----------------|------|----------|
| **RUNTIME CONNECTED** | **0** | UI→Repo→HTTP→canlifal.com→model→state→UI cihazda doğrulanmadı |
| PARTIAL | ~256 | Path+repository+API smoke; cihaz runtime yok |
| MISSING | ~182 | Admin/web-only; mobil kapsam dışı |
| BLOCKED | 16 kritik feature | DEVICE / TEST ACCOUNT |
| UNUSED | ~150+ | Stripe/admin/blog vb. |
| DUPLICATE | 0 kritik | Stage 16 legacy Socket.IO path temizlendi |

---

## Kritik feature matrix

| FEATURE | BACKEND ENDPOINT | FLUTTER CALLER | MODEL | STATE | RESULT |
|---------|------------------|----------------|-------|-------|--------|
| AUTH | `/api/auth/mobile-login`, `/api/me`, refresh | `AuthRepository` | `UserDto` | `authController` | **BLOCKED** (API PASS; logout UI cihaz yok) |
| TRTC | `/api/trtc/token` | `TrtcRemoteDatasource` | token map | `TrtcRoomManager` | **BLOCKED** (token API PASS; join cihaz yok) |
| LIVE | `/api/video-streams`, join, SSE | `LiveApiRemoteDatasource` | `LiveStream` | `liveRoomProviders` | **BLOCKED** |
| LIVE FALCI | `/api/fortune-tellers/session`, room SSE | `LivePsychicsRemoteDatasource` | session DTO | psychic controllers | **BLOCKED** |
| PK LIVE | `/api/video-streams/pk` | `PkBattleRemoteDatasource` | PK DTO | `pkBattleProvider` | **BLOCKED** (API PASS) |
| PK VOICE | `/api/chat/rooms/{id}/pk` | `PkBattleRemoteDatasource` | PK DTO | voice PK pages | **BLOCKED** (API PASS) |
| VOICE ROOM | presence, `/stream` SSE, TRTC | `ChatRoomRepository` | room entities | `voiceRoomLiveProvider` | **BLOCKED** (presence API PASS) |
| GIFT | `/api/live/gift/send` | gift datasources | `GiftEvent` | gift providers | **BLOCKED** (txn API PASS) |
| JETON | wallet/me endpoints | wallet repos | balance DTO | wallet UI | **BLOCKED** (500 jeton API OK) |
| SSE | 5 canonical stream paths | `SseClient`, `ChatRoomSseService` | `SseEvent` | SSE hub | **PARTIAL** (19/20; TEST 20 header FAIL) |
| MUSIC | `/api/music/search`, song-request | `RoomMusicRepository` | queue DTO | `RoomMusicBloc` | **BLOCKED** (API PASS; playback cihaz yok) |

---

## 500 Jeton (Stage5 API — gerçek backend)

| Alan | Değer |
|------|--------|
| BEFORE | 3850 |
| TRANSACTION | `POST /api/live/gift/send` HTTP 200 |
| DEDUCTED | 500 |
| AFTER | 2850 |
| RECEIVER | BLOCKED (cihaz/SSE UI) |
| RANKING | BLOCKED (cihaz) |

Flutter `balance -=` manipülasyonu: **yok**

---

## SSE regression (2026-08-10)

| Test | Sonuç |
|------|--------|
| 20 network cycles | 20/20 PASS |
| TEST 20 `X-Accel-Buffering: no` | **FAIL** (production omit) |
| **SSE acceptance** | **19/20** |

Handoff: `docs/SSE_HEADER_PRODUCTION_HANDOFF.md`

---

## REGRESSION (önceki + SSE bu oturum)

| Suite | Sonuç |
|-------|--------|
| Fortune | 8/8 *(önceki)* |
| API | 17/17 *(önceki)* |
| P0 | 25/25 *(önceki)* |
| Stage 8 | 9/9 *(önceki)* |
| Release Gate | 11/11 *(önceki)* |
| SSE | **19/20** *(bu oturum)* |

---

## CRITICAL

1. RUNTIME CONNECTED = 0 (gerçek cihaz yok)
2. SSE TEST 20 — `X-Accel-Buffering: no` production'da yok
3. Production Next.js repo bu workspace'te değil — SSE header deploy bekliyor
4. TRTC/LIVE/VOICE/PK/MUSIC cihaz runtime doğrulanmadı

## FINAL API PARITY: **INCOMPLETE**

## PRODUCTION: **NOT READY**
