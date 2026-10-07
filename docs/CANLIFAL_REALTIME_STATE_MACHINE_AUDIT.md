# CANLIFAL — Realtime State Machine Audit

> 2026-10-07 · Yalnız denetim · Durumlar en fazla **CODE PASS**; gerçek cihaz **BLOCKED**.

## 1. Canlı fal seansı

### Backend durumları
`pending → active → completed`, yan dallar `cancelled`, `rejected`. Kodda `expired` bekleyen seans için **atanmıyor**, istemci kendi zaman aşımını uyguluyor.

| Geçiş | Backend | Sorun |
|---|---|---|
| request → `pending` | `POST /api/fortune-tellers/session` | — |
| `pending` → `active` | `PATCH /api/fortune-tellers/sessions/{id}` `{action:'accept'}` | **B-C1:** okuma-kontrol-güncelle atomik değil; her kabulde yeni `roomId = room_${id}_${Date.now()}` (`route.ts:54–68, :164`) |
| `pending` → expired | **yok** | **B-C2:** `sessions/stream/route.ts:59,105` zaman filtresi olmadan tüm `pending` kayıtları döndürüyor |
| `active` → `completed` | ping/end aksiyonları | — |

### İdempotency
- Backend: `accept` idempotent **değil** (B-C1).
- Flutter, rezervasyon tarafı: tekil kapı `PsychicFlow.isBookingInFlight` (PR #449). Aynı anda tek istek, 60 sn tavan. **CODE + widget test PASS.**
- Flutter, falcı tarafı: gelen istekler bellek içi `_pollGate` ile tekilleştiriliyor (`psychic_incoming_host.dart:306–326`). Uygulama yeniden açılınca bu bellek sıfırlanıyor. Sunucu `pending` döndürmeyi sürdürdüğü için istek yeniden görünüyor. Kök neden backend'de (B-C2).

### İki cihaz senkronu (A=danışan, B=falcı)
| Alan | Kaynak | Değerlendirme |
|---|---|---|
| sessionId | backend | ortak |
| roomId | `accept` yanıtı | **B-C1 nedeniyle iki farklı değer oluşabilir → STATE MISMATCH** |
| startedAt / timerStartedAt | backend `room` (timerStarted, remainingSeconds) | Flutter `_tick` her saniye: `room.timerStarted ? room.remainingSeconds : local-1` (`psychic_video_controller.dart` `_startTimers`) → **PARTIAL**: senkronlar arası yerel sayım, sapma ≤ yoklama aralığı (SSE yoksa 2–3 sn) |
| maxMinutes | backend | ortak |

**Önerilen tek state machine (Flutter):**
`REQUESTED → PENDING → ACCEPTED → ROOM_READY → RTC_CONNECTING → RTC_CONNECTED → TIMER_ACTIVE → ENDED`.
Tek kaynak `PsychicSessionPhase` + backend `room` olmalı. `remainingSeconds = serverTimerStartedAt + duration − serverNow` hesaplanmalı, sunucu saati ofseti ilk yanıttan alınmalı.

## 2. Sesli oda

| Aşama | Beklenen | Kod durumu |
|---|---|---|
| Join | presence join → TRTC audience → SSE | **F-C1:** TRTC `audioOnly` join yerel mikrofonu açıyor, sonra kapatılıyor |
| Koltuğa otur | seats (backend `pg_advisory_xact_lock`, `seats/route.ts:187–196`) → mikrofon | Backend kilidi **CODE PASS**. **F-H1:** mikrofon açmak tam TRTC çık+gir |
| Koltuktan in | mikrofon OFF → publish OFF → seat null | `08a2de49` (Cursor) "seat leave TRTC release" — **CODE (cihaz doğrulanmadı)** |
| Odadan çık | leave → SSE kapat → TRTC leave | `45a6f4e0` (Cursor) "voice TRTC leave on room exit" — **CODE (cihaz doğrulanmadı)** |
| Ana sayfada görünürlük | presence leave anında | **B-H1:** zorla kapanışta 5 dk hayalet |
| Oda değişimi A→B | A leave tamamlanmadan B join olmamalı | **F-C2:** iki TRTC yöneticisinin işlem kapısı ortak değil |

### CRITICAL STATE DUPLICATION
| State | Tutulduğu yerler | Önerilen tek kaynak |
|---|---|---|
| Mikrofon | `TrtcRoomManager._micOn`, `VoiceTrtcEngine._micOn`, `chat_room_providers_room_sync` | `TrtcRoomManager` (native ile birebir) + provider yalnız okur |
| Katılınan oda | `TrtcRoomManager._joinedStrRoomId`, `VoiceTrtcEngine._roomId`, `room_event_scope` aktif oda | tek `RealtimeSessionRegistry` |
| seatIndex | 28 alan tanımı (çoğu widget parametresi) | backend presence/seats yanıtı + SSE |
| sseConnected | 6 alan | servis başına tek `SseStatusController` |
| Oda olayı süzgeci | `core/room/room_event_scope.dart` ve `voice_hub/domain/room_event_scope.dart` (farklı mantık) | tek fonksiyon |

## 3. PK
- Sesli PK `/api/chat/rooms/{roomId}/pk` ve canlı PK `/api/live/pk` ana backend'de. Flutter **CODE PASS** (`api_backend_router.dart:23–25`).
- Oyun/eşleşme PK `/api/pk/*`: REST games backend'e, SSE ana backend'e gidiyor (**F-H2**). Aynı `matchId` için iki kaynak var.
- Mevcut belge: `docs/PK_STATE_MACHINE_FLUTTER.md`. İki cihazda `battleId/status/startedAt/endsAt/score` eşitliği **BLOCKED**.

## 4. Hediye
- Backend olayları: `gift_received`, `gift_queue_updated`, `gift_finished` (`lib/gift-engine.ts`). Sohbet SSE'si tip `gift` gönderiyor (`chat/rooms/[roomId]/stream/route.ts:104`).
- Flutter tekilleştirme: `gift_event_listener.dart` + `global_gift_event_bridge.dart`, `core/room/room_event_scope.dart` süzgecini kullanıyor; oda tarafı başka bir süzgeç kullanıyor (F-M4).
- Süre: **F-C3 / B-H3.**
- Gecikme: sohbet SSE'si DB'yi 2 sn'de bir yokluyor (B-M1), alıcıda gecikme 0–2 sn.

## 5. Arka plan görseli zinciri
```
ADMIN (POST /api/admin/chat-rooms backgroundImage)   ✔ yazar   (admin/chat-rooms/route.ts:95–108)
→ DB ChatRoom.backgroundImage                         ✔          (schema.prisma:544)
→ GET /api/chat/rooms (liste)                         ✔ döner    (chat/rooms/route.ts:78)
→ GET /api/chat/rooms/{id}/state                      ✔ döner    (state/route.ts:202)
→ SSE değişiklik olayı                                ✘ YOK      (B-H2)
→ Flutter model                                       ✔ backgroundImageUrl ← 'backgroundImage'
→ Provider (SSE ile güncelleme)                       ✘ yanlış anahtar (F-H3)
→ Admin ekranı (POST /api/admin/voice-room-backgrounds) ✘ web oturumu → JWT 401 (MISMATCH)
```
Kırıldığı yerler: **(1)** admin mobil ekranından yükleme 401, **(2)** canlı değişiklik diğer kullanıcılara iletilmiyor, **(3)** Flutter SSE anahtarı yanlış.

## 6. Uygulama yaşam döngüsü (arka plan/ön plan, zorla kapatma)
| Kaynak | Sunucu temizliği | Değerlendirme |
|---|---|---|
| Presence | 5 dk (`presence/route.ts:52`) | HIGH (B-H1) |
| Koltuk | 90 sn (`voice-room-constants.ts:22`) | MEDIUM |
| Canlı fal `pending` | **yok** | CRITICAL (B-C2) |
| TRTC | Tencent tarafı zaman aşımı (kodda kontrol yok) | BLOCKED |
| SSE | sunucu `abort` ile kapanır | CODE PASS |
