# Canlı Falcılar — kalan işler (2026-08-20)

Modül: `mobile/lib/features/live_psychics/`  
Referans: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §9.6–9.7, `docs/prompts/FLUTTER_CANLI_FALCILAR_PROMPT.md`

## Tamamlanan (bu oturum serisi)

| Alan | Durum |
|------|--------|
| API sözleşmesi | `PATCH sessions/{id}`, `POST room/{id}/review`, `cancel` vs `end` ayrımı |
| Kabul akışı | Bekleme → `ad-transition` → görüşme |
| Misafir liste | Giriş yapmadan gezinti; favoriler için giriş |
| Oturum geçmişi | Falcı paneli + danışan «Son Oturumlarım» |
| SSE poll | Aktifken 30 sn, değilse 4 sn HTTP yedek |
| Dead code | `held`, `incoming`, `respond`, `liveFalPending` sabitleri |
| Status sorgu | Yalnızca `GET /api/fortune-tellers/session?sessionId=` |
| respondSession | `body.isNotEmpty` false-positive düzeltmesi |
| Push falcı kabul | `openTellerSessionFromPush` (danışan `resumeFromPush` ayrı) |
| Push session_ended | Değerlendirme yalnızca danışana (`promptReview: !isTeller`) |
| Incoming SSE | `pending_sessions`, `connected.pendingSessions`, max 20 reconnect, 401 anında retry |

---

## Kalan — kod (öncelik sırasıyla)

### P1 — Davranış / UX

| # | Konu | Dosya | Açıklama |
|---|------|-------|----------|
| 1 | **120 sn süre uyarısı** | `psychic_video_controller.dart` | Prompt §11: kalan süre ≤120 sn iken danışana extend CTA / snackbar |
| 2 | **`time_extended` senkronu** | `psychic_video_controller.dart`, `psychic_room_sse_service.dart` | SSE `newMaxMinutes` / jeton kalan → client timer güncelle |
| 3 | **Oda SSE give-up** | `psychic_room_sse_service.dart` | Incoming SSE ile aynı: `SseReconnectPolicy.maxAttempts` (20) |
| 4 | **SSE failed UI** | video / waiting ekranları | 20 deneme sonrası «Bağlantı koptu — yenile» banner |

### P2 — API / model

| # | Konu | Dosya | Açıklama |
|---|------|-------|----------|
| 5 | **createSession parametreleri** | `live_psychics_repository.dart`, `psychic_flow.dart` | `staffExempt`, `clientName`, `tellerUserId` body’ye yazılmıyor — kaldır veya staff muafiyetini backend ile doğrula |
| 6 | **extendSession imzası** | repository | `totalJeton` zorunlu ama API yalnızca `{action, minutes}` — imza sadeleştir |
| 7 | **Çift seans** | `psychic_flow.dart` | Aynı falcıya eşzamanlı ikinci randevu — `_findBlockingSession` genişlet |

### P3 — Temizlik

| # | Konu | Dosya |
|---|------|-------|
| 8 | Legacy sabitler | `api_endpoints.dart` — `tellerChat`, `liveFalRequestAccept/Reject` (live modülü) |
| 9 | Waiting disconnect | `psychic_waiting_screen.dart` — gereksiz `psychicRoomSseServiceProvider.disconnect()` |
| 10 | Eski dokümanlar | `docs/API_ENDPOINT_MATRIX.md`, `FLUTTER_AUDIT.md` — `fortuneTellerSessionStatus` artık yok |

---

## Kalan — testler

| Tür | Eksik |
|-----|--------|
| **Unit** | `live_psychics_remote_datasource` (mock Dio): createSession dual path, cancel, roomAction |
| **Unit** | `PsychicFlow.openTellerSessionFromPush` / `resumeFromPush` rol ayrımı |
| **Unit** | `psychic_incoming_sse_service`: `pending_sessions` list parse |
| **Unit** | `psychic_room_sse_service`: timer_started, time_extended, session_ended |
| **Widget** | waiting, booking sheet, incoming dialog, video session |
| **CI** | `scripts/acceptance-tests/` — API smoke var; Flutter E2E yok |

Mevcut: `psychic_push_payload_test`, `psychic_model_teller_test`, `session_room_sse_event_test`, invite coordinator, phase guard, profile resolver.

---

## Kalan — manuel / E2E (cihaz)

1. **Danışan happy path** — book → wait → accept → ad → TRTC → chat → extend → end → review  
2. **Falcı happy path** — online → SSE/dialog → accept → start_timer → teller_add_time → end → bahşiş  
3. **Red / iptal / timeout** — jeton iade mesajı + cüzdan  
4. **Push** — background accept/reject; falcı bildirim **Kabul** → session route  
5. **SSE kopma** — oda + incoming reconnect; poll yedek yeterliliği  
6. **TRTC** — arka plan / ön plan, roomId değişimi  
7. **Staff** — jeton düşülmeden seans + extend  
8. **Deep link** — `/canli-falcilar/.../session` restore  

---

## Mimari not (bilinçli fark)

- **TRTC** birincil medya; prompt §14 HTTP WebRTC (`offer`/`answer`/`ice-candidate`) uygulanmıyor.  
- `sendRoomSignal` kılavuz §9.7 `{type, data}` (bahşiş, media_state) için kullanılıyor.

---

## Sürüm geçmişi (Canlı Falcılar)

| Sürüm | Özet |
|-------|------|
| 1.0.294+330 | Backend API uyumu (cancel, review, hold kaldırma) |
| 1.0.295+331 | Kabul → ad-transition, push routing |
| 1.0.296+332 | Misafir liste, falcı panel oturum geçmişi, SSE poll |
| 1.0.297+333 | Danışan oturum geçmişi, paylaşılan widget, dead code |
| 1.0.298+334 | Status path, respondSession, teller push, SSE pending_sessions |

_Bu dosya agent oturumlarında güncellenir; tamamlandıkça maddeler silinir veya «Tamamlandı» bölümüne taşınır._
