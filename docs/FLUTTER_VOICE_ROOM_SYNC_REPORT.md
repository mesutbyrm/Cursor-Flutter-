# Flutter Sesli Oda Backend Senkronizasyon Raporu

**Sürüm:** 1.0.67+94  
**Tarih:** 2026-07-21  
**Referans:** `SESLI_ODA_SENKRONIZASYON_RAPORU_4dd9.md`

## Özet

Flutter sesli oda istemcisi backend tek doğruluk kaynağı olacak şekilde güncellendi. İstemci artık TRTC oda kimliği, numeric UID, token, owner, koltuk haritası veya katılımcı listesi üretmiyor; yalnızca backend yanıtlarını ve SSE `room_event` olaylarını uyguluyor.

## Değiştirilen dosyalar

| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/core/network/api_endpoints.dart` | `chatRoomState()` eklendi |
| `mobile/lib/features/voice_hub/domain/entities/voice_room_seat_slot.dart` | **Yeni** — 15 koltuk modeli |
| `mobile/lib/features/voice_hub/domain/entities/voice_room_state_snapshot.dart` | **Yeni** — GET /state modeli |
| `mobile/lib/features/voice_hub/domain/entities/chat_room_presence.dart` | `micOn` backend alanı |
| `mobile/lib/features/voice_hub/domain/entities/chat_room_sse_event.dart` | `roomEvent` SSE tipi |
| `mobile/lib/features/trtc/domain/entities/trtc_credentials.dart` | `trtcRoomId`, `numericUid`, `effectiveStrRoomId` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart` | `fetchRoomState`, `fetchSeats` |
| `mobile/lib/features/voice_hub/data/services/chat_room_sse_service.dart` | `onRoomEvent` callback |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` | Oda akışı, state alanları, leave temizliği |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_room_sync.dart` | **Yeni** — state/seats yükleme + room_event işleyicileri |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_presence.dart` | Otomatik koltuk kaldırıldı |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_seat.dart` | Optimistic koltuk kaldırıldı; boş koltuk backend haritasından |
| `mobile/lib/features/voice_hub/presentation/audio/voice_trtc_engine.dart` | Backend TRTC kimlikleri |
| `mobile/lib/features/voice_hub/presentation/audio/voice_room_audio_coordinator.dart` | `backendTrtc` parametresi |
| `mobile/lib/features/voice_hub/presentation/voice_room_rtc_page.dart` | TRTC, `backendSyncReady` sonrası |
| `mobile/lib/features/voice_hub/presentation/basic/voice_room_basic_page.dart` | Aynı TRTC sırası |
| `mobile/lib/features/trtc/presentation/trtc_room_manager.dart` | `effectiveStrRoomId` kullanımı |
| `mobile/test/voice_room_backend_sync_test.dart` | **Yeni** — parse testleri |

## Güncellenen servisler

- **ChatRoomRemoteDataSource** — `fetchRoomState`, `fetchSeats`
- **ChatRoomSseService** — `room_event` dispatch
- **VoiceRoomLiveController** — sıralı giriş, SSE patch, çıkış temizliği
- **VoiceRoomAudioCoordinator / VoiceTrtcEngine** — backend TRTC credentials

## Kullanılan endpoint'ler

| Amaç | Endpoint |
|------|----------|
| Odaya katılma | `POST /api/chat/rooms/{id}/presence` |
| Tam durum (giriş) | `GET /api/chat/rooms/{id}/state` |
| Koltuk haritası | `GET /api/chat/rooms/{id}/seats` |
| Mikrofon | `POST /api/chat/rooms/{id}/voice` |
| Koltuk değiştir | `PATCH /api/chat/rooms/{id}/seats` |
| Odadan ayrıl | `DELETE /api/chat/rooms/{id}/presence` |
| TRTC token | `POST /api/trtc/token` (state içinde de gelebilir) |
| SSE | `GET /api/chat/rooms/{id}/stream` |

## Dinlenen SSE eventleri

**`room_event` alt tipleri (ek API yok):**

- `user_joined` — katılımcı ekleme
- `user_left` — katılımcı silme + koltuk temizleme
- `mic_changed` — `micOn` güncelleme
- `seat_changed` — koltuk haritası + presence `seatIndex`
- `owner_changed` — `ownerId` güncelleme
- `room_closed` — oda kapatma, state sıfırlama

Mevcut tipler (`presence`, `gift`, `message`, DJ vb.) korunur.

## Oda akışı

```
1. POST presence (join)
2. GET /state
3. GET /seats
4. TRTC connect (roomTrtc from state)
5. SSE connect
6. UI render
```

**Çıkış:** Leave API → TRTC leave → SSE disconnect → state dispose

## Performans

- `GET /state` yalnızca odaya ilk girişte
- Sonraki değişiklikler SSE `room_event` ile (gereksiz presence poll azaltıldı)
- SSE varken poll aralığı 60–120 sn (DJ aktif değilse)

## Testler

| Test | Sonuç |
|------|-------|
| `voice_room_backend_sync_test.dart` — koltuk parse, state snapshot | Geçti |
| `dart analyze` (voice_hub + trtc credentials) | Hata yok |

## Manuel test checklist (üretim)

- [ ] Web kullanıcı girişi → Flutter anında görür
- [ ] Flutter girişi → Web anında görür
- [ ] Koltuk değişimi iki yönlü
- [ ] Mic aç/kapat senkron
- [ ] Çıkışta her iki platformdan düşme
- [ ] Aynı kullanıcı iki odada görünmez
- [ ] Owner iki platformda aynı
- [ ] TRTC `voice_room_<id>` backend ile aynı

## Kalan eksikler

- Canlı iki cihaz (web + Flutter) uçtan uca ses testi CI'da otomatik değil
- Bazı legacy `presence` SSE tam listeleri hâlâ `_mergePresenceStable` ile birleştirilebilir (geriye dönük uyumluluk)
- `voice_room_rtc_page` koltuk UI'si hâlâ presence `seatIndex` üzerinden; `seatSlots` doğrudan widget'a bağlanabilir (iyileştirme)
