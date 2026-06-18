# Flutter — Canlifal Backend Entegrasyon Raporu

**Sürüm:** `1.0.266+269`  
**Backend:** https://canlifal.com  
**Tarih:** 2026-06-18

## Özet

Sohbet odaları gerçek zamanlı katmanı **SSE** (`eventsource`) üzerine taşındı; sesli oda hediye/DJ/şarkı olayları Socket.IO yerine SSE ile dinleniyor. Canlı falcı modülü **repository pattern** + merkezi **ErrorHandler** ile yapılandırıldı. Odadan çıkışta müzik/SSE temizliği güçlendirildi.

---

## 1. Düzeltilen / eklenen dosyalar

### SSE & sohbet odası
| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/features/voice_hub/data/services/chat_room_sse_service.dart` | **Yeni** — `GET /api/chat/rooms/{roomId}/stream`, otomatik yeniden bağlan, olay ayrıştırma |
| `mobile/lib/features/voice_hub/domain/entities/chat_room_sse_event.dart` | **Yeni** — message, dj, song, music, user_join/leave, room_update, moderation, announcement, gift |
| `mobile/lib/features/voice_hub/data/services/voice_room_sse_service.dart` | Export alias |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` | SSE hediye/şarkı/DJ; Socket.IO gift kaldırıldı; SSE varken mesaj poll atlanır; `leaveRoomSession` müzik kapatır |
| `mobile/lib/features/voice_hub/presentation/voice_room_rtc_page.dart` | Geri tuşu / çıkışta tam temizlik (`leaveRoomSession`) |

### Canlı falcı modülü
| Dosya | Değişiklik |
|-------|------------|
| `mobile/lib/core/network/error_handler.dart` | **Yeni** — merkezi hata mesajı |
| `mobile/lib/features/home/data/datasources/live_fortune_remote_datasource.dart` | **Yeni** — tüm üretim uçları |
| `mobile/lib/features/home/domain/repositories/live_fortune_repository.dart` | **Yeni** — arayüz |
| `mobile/lib/features/home/data/repositories/live_fortune_repository_impl.dart` | **Yeni** — uygulama |
| `mobile/lib/features/home/domain/entities/live_teller_review_entity.dart` | **Yeni** — yorum, ödül, hediye, sinyal modelleri |
| `mobile/lib/features/home/data/services/live_fortune_room_signal_service.dart` | **Yeni** — HTTP WebRTC sinyal poll |
| `mobile/lib/core/network/api_endpoints.dart` | apply, reviews, awards, gifts, room/signal query |
| `mobile/lib/features/home/presentation/providers/home_providers.dart` | `liveFortuneRepositoryProvider`, signal service |
| `live_fortune_flow.dart`, `live_fortune_session_page.dart`, `live_fortune_waiting_page.dart`, `fortune_incoming_invite_host.dart`, `push_lifecycle_listener.dart` | Repository kullanımı |

### Bağımlılıklar
| Dosya | Değişiklik |
|-------|------------|
| `mobile/pubspec.yaml` | `eventsource`, `http`, `flutter_webrtc`; sürüm `1.0.266+269` |

---

## 2. Eklenen servisler

| Servis | Görev |
|--------|--------|
| `ChatRoomSseService` | Sohbet odası SSE — mesaj, presence, DJ, şarkı, hediye, moderasyon |
| `LiveFortuneRepository` | Canlı falcı API katmanı (repository) |
| `LiveFortuneRemoteDataSource` | Dio + üretim uçları |
| `LiveFortuneRoomSignalService` | `POST/GET/DELETE /api/room/signal` poll |
| `ErrorHandler` | `ApiException` → kullanıcı mesajı |
| `LiveFortuneRoomSseService` | *(önceki sürüm)* seans SSE |
| `LiveFortuneTellerIncomingSseService` | *(önceki sürüm)* falcı davet SSE |

---

## 3. Kullanılan endpointler

### Sohbet odası (SSE)
- `GET /api/chat/rooms/{roomId}/stream` — Bearer JWT
- `POST /api/chat/rooms/{roomId}/song-request` — !istek
- Presence heartbeat: mevcut presence API (20 sn)

### Canlı falcı
- `GET /api/fortune-tellers`
- `POST /api/fortune-tellers/apply`
- `GET /api/fortune-tellers/my-profile`
- `POST /api/fortune-tellers/toggle-online`
- `POST /api/fortune-tellers/session`
- `PATCH /api/fortune-tellers/sessions/{id}`
- `GET /api/fortune-tellers/sessions/stream` (SSE)
- `GET /api/user/active-sessions`
- `GET /api/room/{sessionId}`
- `PATCH /api/room/{sessionId}` — timer, ping, extend, end
- `GET/POST /api/room/{sessionId}/messages`
- `GET /api/room/{sessionId}/stream` (SSE)
- `POST/GET/DELETE /api/room/signal`
- `GET /api/fortune-tellers/{id}/reviews`
- `GET /api/fortune-tellers/awards?tellerId=`
- `GET /api/fortune-tellers/gifts?tellerId=`
- `POST /api/teller/gifts` — bahşiş

---

## 4. Bilinen sınırlar / çalışmayan alanlar

| Alan | Durum | Not |
|------|--------|-----|
| Canlı fal video | **TRTC** birincil | Üretim prompt WebRTC + `/api/room/signal` tanımlar; sinyal servisi hazır, tam `flutter_webrtc` peer bağlantısı seans sayfasına henüz bağlanmadı |
| Canlı yayın / PK | **Socket.IO** | Kullanıcı talebi sohbet odası için Socket.IO kaldırımı; yayın odası hâlâ Socket.IO |
| Seans yorumu gönderme | **Endpoint belirsiz** | Prompt yalnızca `GET .../reviews` listeler; POST yorum ucu dokümanda yok |
| `VoiceRoomGlobalMusicBar` | Devre dışı UI | Mini player oda içi `VoiceRoomDjPlayer` + video modu ile çalışır |
| Yerel `api/` mirror | Kısmi | Üretim `https://canlifal.com` varsayılan |

---

## 5. Eksik backend endpointi

Üretim prompt’ta **seans sonrası yorum gönderme (POST)** açıkça tanımlı değil; yalnızca `GET /api/fortune-tellers/{tellerId}/reviews`. Web arayüzünde farklı bir uç varsa mobilde eşleme gerekir.

---

## 6. Mock / TODO

- Canlı falcı ve sohbet akışlarında **mock data yok**.
- Bu entegrasyon paketinde bilinçli **TODO** bırakılmadı.

---

## 7. Derleme

Cloud ortamında Flutter SDK PATH dışında olabilir; CI `dart analyze` çalıştırır. Push sonrası APK: [build-apk workflow](https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml).
