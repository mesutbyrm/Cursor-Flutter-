# FAZ 6 — Voice chat parity

**Durum:** HAZIRLIK — P0 kod ✅; M5 manuel bekliyor (`1.0.287+323`)

| Kılavuz §9.3 | Durum |
|--------------|--------|
| Presence, seats, voice, DJ | ✅ |
| Music queue + song-request | ✅ (jeton gerekli) |
| SSE stream | ✅ M10–M12 |
| ChatRoomRepository tek arayüz | 🔄 datasource dağılımı |

**Testler:** 93 case (`test/features/voice_hub/`)
