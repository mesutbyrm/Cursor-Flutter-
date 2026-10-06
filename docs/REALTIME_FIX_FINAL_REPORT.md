# Realtime / Backend Parity — Ara Rapor (FAZ 2–3 devam)

**Dal:** `cursor/flutter-realtime-parity-fix-dfca` → **`main` (1.0.719+772)**  
**PR:** [#446](https://github.com/mesutbyrm/Cursor-Flutter-/pull/446)  
**Tarih:** 2026-10-05 (UTC)

> Faz 6 (duplicate cleanup + E2E TRTC/SSE) merge sonrası devam eder. Bu dosya Faz 2–3 çıktısını özetler.

---

## Değişen dosyalar (özet)

| Alan | Dosyalar |
|------|-----------|
| Join / heartbeat / leave | `chat_room_providers_live_lifecycle.dart`, `chat_room_providers_entry.dart`, `chat_room_providers_presence.dart`, `live_room_remote_datasource.dart`, `live_field_room_lifecycle_api.dart` |
| SSE guard | `voice_room_sse_session_guard.dart`, `chat_room_providers.dart`, `chat_room_providers_sse.dart` |
| Gift jeton | `voice_gift_send_authority.dart`, `chat_room_gifts_remote_datasource.dart`, `live_field_gift_api.dart` |
| PK timer | `pk_battle_provider.dart` (tek `_countdownTimer`) |
| Mapper | `voice_room_live_join_mapper.dart` |
| Audit | `REALTIME_ARCHITECTURE_AUDIT.md` |

## Silinen / birleştirilen

- **Silinen dosya yok** (Faz 6 öncesi politika).
- **Birleştirilen:** `pk_battle_provider` içinde `_tick` + `_endsAtSync` → `_countdownTimer`.

## Düzeltilen davranışlar

- Sesli oda giriş waterfall azaltıldı (`join-room` birleşik snapshot).
- `live/heartbeat` birincil; chat presence heartbeat yedek.
- `live/leave-room` + presence leave.
- Room A SSE → Room B state sızıntısı guard.
- Hediye yanıtında `totalJeton` / `revenue.total` önceliği.
- PK geri sayım: sunucu `endsAt` tek timer yolu.

## Test edilen (birim / contract)

| Spec | Test dosyası |
|------|----------------|
| 1–2, 3–6, 11, 13–19 | `voice_room_realtime_lifecycle_contract_test.dart` |
| PK endsAt | `pk_battle_ends_at_sync_test.dart`, `pk_battle_single_countdown_timer_test.dart` |
| SSE guard | `voice_room_sse_session_guard_test.dart` |
| Gift authority | `voice_gift_send_authority_test.dart` |
| Leave idempotent | `voice_room_live_leave_idempotency_test.dart` |
| Join mapper | `voice_room_live_join_mapper_test.dart` |

**Henüz E2E cihaz:** TRTC, tam SSE connected/joined/left, background recovery (Spec 7–10, 20).

## Endpointler (doğrulanan sözleşme)

- `POST /api/live/join-room` (voice)
- `POST /api/live/heartbeat`
- `POST /api/live/leave-room`
- `POST /api/live/gift/send` (parse alanları)
- `GET /api/chat/rooms/{id}/stream` (SSE — mevcut hub)

## Kalan problemler

- Tam Spec 1–20 integration test paketi (mock server / golden SSE).
- `RoomSessionManager` vs `VoiceRoomLiveController` duplicate canonical (Faz 6 cleanup).
- TRTC / background recovery E2E (Spec 20).

## Faz 4 (P2) — 2026-10-06

- Keşif SSE: aktif oda + alias seti keşif `connectedRooms` dışında; hub `releaseHub: false` ile oturum korunur.
- SSE olay tipi contract: Spec 7–10 (`connected`, join/leave, music/DJ).

## Production backend beklentileri

- `join-room` voice yanıtında eksik alanlar için fallback stratejisi canlı doğrulama.
- Gift SSE `totalJeton` alan adı stabilitesi.
- PK `serverNow` skew tüm uçlarda tutarlı mı?

---

_Audit:_ [`REALTIME_ARCHITECTURE_AUDIT.md`](REALTIME_ARCHITECTURE_AUDIT.md)
