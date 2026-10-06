# Realtime / Backend Parity — FINAL Rapor (Faz 1–6)

**Dal:** `main` · **Sürüm:** `1.0.724+777` (Faz 6)  
**Tarih:** 2026-10-06 (UTC)

---

## Özet

Flutter sesli oda realtime katmanı üretim sözleşmesine (`join-room`, `live/heartbeat`, `live/leave-room`, SSE) hizalandı. Keşif SSE, test paketi ve arka plan recovery sözleşmeleri tamamlandı. **Cihaz E2E TRTC** Psychic P0 sonrası manuel doğrulama maddesi olarak kalır.

---

## Faz özeti

| Faz | Kapsam | Durum |
|-----|--------|--------|
| 1 | Mimari audit | ✅ `REALTIME_ARCHITECTURE_AUDIT.md` |
| 2–3 | P0/P1 join, heartbeat, leave, SSE guard, gift, PK timer | ✅ `main` |
| 4 | Keşif SSE aktif oda hariç | ✅ |
| 5 | Spec 1, 7–10, 14–17 integration/contract testleri | ✅ |
| 6 | Spec 20 sözleşme, session ownership doc, SSE lifecycle test | ✅ |

---

## Davranış değişiklikleri (prod)

- `POST /api/live/join-room` birincil voice bootstrap
- `POST /api/live/heartbeat` + `POST /api/live/leave-room`
- SSE oda guard, hediye jeton otoritesi, PK tek countdown
- Keşif SSE aktif odayı izlemez (hub refCount korunur)
- Arka plan: 45 sn sonra `app_background` leave; SSE hub pause/resume debounce 450 ms

---

## Test matrisi (Spec 1–20)

| Spec | Konu | Test / kanıt |
|------|------|----------------|
| 1 | JWT refresh single-flight | `auth_token_refresh_coordinator_single_flight_test.dart` |
| 2–6 | join-room endpoint & alanlar | `voice_room_realtime_lifecycle_contract_test.dart`, join mapper |
| 7–10 | SSE tipleri + hub/keşif | contract + `voice_room_sse_hub_discover_integration_test.dart` |
| 11 | Gift jeton | `voice_gift_send_authority_test.dart` |
| 12–13 | PK timer | `pk_battle_*_test.dart` |
| 14–17 | Leave pipeline | `voice_room_leave_pipeline_spec.dart` + spec test |
| 18–19 | Cross-room SSE | `voice_room_sse_session_guard_test.dart` |
| 20 | Background / resume | `voice_room_background_recovery_spec.dart`, `sse_hub_lifecycle_binding_test.dart` |

**Manuel (cihaz):** TRTC ses yolu, uzun arka plan + geri dönüş uçtan uca.

---

## Mimari sahiplik (Faz 6)

Bkz. [`REALTIME_ROOM_SESSION_OWNERSHIP.md`](REALTIME_ROOM_SESSION_OWNERSHIP.md) — `RoomSessionManager` + `delegateLifecycleToHost`; **silinen dosya yok**.

---

## Bilinen kalanlar

- Mock-server golden SSE integration (tam Spec 7–10 stream replay)
- Opsiyonel manager/controller birleştirme refactor (P0 cihaz sonrası)
- Backend: `join-room` voice yanıt alanları canlı doğrulama

---

_Audit:_ [`REALTIME_ARCHITECTURE_AUDIT.md`](REALTIME_ARCHITECTURE_AUDIT.md)
