# FAZ 6 — Voice chat parity

**Durum:** HAZIRLIK — P0/P1 kod ✅ (`1.0.291+327`); M5 manuel bekliyor

| Kılavuz §9.3 | Durum |
|--------------|--------|
| Presence, seats, voice, DJ | ✅ |
| Koltuk ↔ ses (canSpeak, seatIndex) | ✅ P0 |
| Moderasyon popup / self-seat / giriş SSE | ✅ P1 |
| Kullanıcı sheet birleşik + VIP giriş şeridi | ✅ P2 |
| Music queue + song-request | ✅ (jeton gerekli) |
| SSE stream | ✅ M10–M12 |
| ChatRoomRepository tek arayüz | 🔄 datasource dağılımı |

**Testler:** 93+ case (`test/features/voice_hub/`)
