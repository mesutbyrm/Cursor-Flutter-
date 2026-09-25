# Canlifal — tam sistem düzeltme ilerlemesi

Güncelleme: 2026-09-25 · APK hedefi: `1.0.599+648`

## Aşama 1 — Sesli oda bağlantı / presence (tamamlandı — kod + test)

### Kök nedenler

| Sorun | Kök neden |
|--------|-----------|
| Ana sayfada “odadayım” / yanlış PK hedefi | `registerVoiceRoomLiveSession` join **başlamadan** çağrılıyordu |
| Hiç join olmadan listede görünme | `_ensureSelfInPresenceList` backend onayı olmadan self ekliyordu |
| Koltuktan düşüp tekrar oturma | Heartbeat fail → tam `joinPresence` + `peekJoinSeatIndex` / auto-seat |
| Çift join / yarış | `RoomSessionManager.join` + `_joinPresence` paralel; manager ikinci heartbeat |
| Leave sonrası hayalet oda | Aktif oda registry leave sonrası temizlenmiyordu |

### Değişen dosyalar

- `room_session_manager.dart` — `delegateLifecycleToHost`, `syncHostJoined` / `syncHostLeft`
- `chat_room_providers_entry.dart` — tek join yolu `_joinPresence()`
- `chat_room_providers_presence.dart` — join/leave/sync, rejoin, registry zamanlaması
- `chat_room_providers_sse.dart` — SSE reconnect join, `selfInRoom` kuralları
- `voice_room_presence_self_sync.dart` + test

### Backend

Değişiklik yok (mevcut `POST .../presence` `{action: join|leave}` sözleşmesi).

### Testler

- `voice_room_presence_self_sync_test.dart` — 3/3 PASS
- `voice_room_manager_integration_test.dart` — PASS
- `pk_session_integration_test.dart` — PASS

### Aşama 1 — cihaz / üretim

- TRTC + gerçek oda sahibi kopması: cihaz P0 gerekli
- Uygulama açılışında sunucuda kalan presence: backend’de “aktif oda” tek uç yok; leave yalnızca dispose/leave akışında

## Aşama 2–5 — bekleyen (sıradaki)

- PK davet teslimi / takım PK (poll + SSE zinciri doğrulama)
- Canlı fal seans süresi / mesaj (psychic modül)
- Oturum özeti / Gold / hediye kutusu / sezon — backend rapor uçları ile eşleme
- Performans profili (startup route observer mevcut)
