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
| 120 sn uyarı | Danışan snackbar + «Uzat»; timer ≤120 sn kırmızı |
| time_extended | `newMaxMinutes` / `remainingSeconds` SSE + oda JSON |
| Oda SSE give-up | Max 20 reconnect, `onFailed`, HTTP poll yedek |
| SSE failed UI | Görüşme banner + `retryRoomSse` |
| Bekleme temizlik | Gereksiz room SSE disconnect kaldırıldı |
| createSession sade | Kullanılmayan repo parametreleri kaldırıldı |
| extendSession sade | `totalJeton` imzadan çıkarıldı |
| Çift seans engeli | Tüm aktif/bekleyen danışan seansları |
| Legacy endpoints | `tellerChat`, `liveFalRequestAccept/Reject` kaldırıldı |
| Incoming SSE parser | `psychic_incoming_sse_parser.dart` ayrıştırıldı + unit test |
| Audit dokümanları | `FLUTTER_AUDIT.md`, `API_ENDPOINT_MATRIX.md` güncellendi |
| Oda SSE parser | `psychic_room_sse_parser.dart` + unit test |
| Push rol testleri | `psychic_flow_push_test` — danışan vs falcı yönlendirme |
| Datasource testleri | Mock Dio — createSession, cancel, roomAction, respond, status |
| Widget testleri | waiting, booking sheet, incoming dialog, video state |

---

## Kalan — testler

| Tür | Eksik |
|-----|--------|
| **CI** | `scripts/acceptance-tests/` — API smoke var; Flutter E2E yok |

Mevcut: `psychic_push_payload_test`, `psychic_model_teller_test`, `psychic_incoming_sse_parser_test`, `psychic_room_sse_parser_test`, `psychic_flow_push_test`, `live_psychics_remote_datasource_test`, `psychic_client_session_guard_test`, `psychic_waiting_screen_test`, `psychic_booking_sheet_test`, `psychic_incoming_call_dialog_test`, `psychic_video_state_test`, `session_room_sse_event_test`, invite coordinator, phase guard, profile resolver.

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
| 1.0.299+335 | 120 sn uyarı, time_extended, oda SSE give-up + banner |
| 1.0.300+336 | createSession/extendSession sade, çift seans engeli, legacy cleanup |
| 1.0.301+337 | Incoming SSE parser ayrıştırma + test, audit dokümanları |
| 1.0.302+338 | Oda SSE parser, push rol testleri, datasource mock Dio testleri |
| 1.0.303+339 | Widget testleri — waiting, booking, incoming dialog, video state |
| 1.0.306+342 | Widget test CI düzeltmeleri (import, layout, pump) |

_Bu dosya agent oturumlarında güncellenir; tamamlandıkça maddeler silinir veya «Tamamlandı» bölümüne taşınır._
