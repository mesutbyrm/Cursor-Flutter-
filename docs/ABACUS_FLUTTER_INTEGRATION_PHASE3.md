# Abacus Flutter entegrasyon — Aşama 3 raporu

**Sürüm:** `1.0.477+515`  
**Referans (değiştirilmedi):** `backend-reference/canlifal_flutter_paketi/`  
**Tarih:** 2026-09-13

---

## A) Tamamlanan entegrasyonlar

| Alan | Durum |
|------|--------|
| Gift Box REST | `GiftBoxRemoteDataSource` + `api_endpoints` + Riverpod provider |
| Gift Box sync | `GET /api/chat/rooms/{roomId}/sync`, `GET /api/video-streams/{streamId}/sync` |
| Auth sessions | Birincil `GET /api/auth/sessions`; yedek `GET /api/auth/mobile-sessions` |
| Oturum iptali | `DELETE /api/auth/sessions?deviceId=`; yedek `DELETE /api/auth/mobile-sessions/{id}` |
| Logout-all | `POST /api/auth/logout-all` + yerel oturum temizliği; UI: Aktif Cihazlar |
| SSE gift_box | `ChatRoomSseEventType.giftBox` (`type: gift_box`) |

**Değiştirilmedi (zaten doğru — Aşama 1–2 korundu):** canlı yayın uçları, sesli oda presence POST, hediye idempotency, wallet düz alanlar, PK skorunun SSE kaynaklı akışı, `gift_received` SSE.

---

## B) Değiştirilen Flutter dosyaları

- `mobile/lib/core/network/api_endpoints.dart`
- `mobile/lib/features/gift_box/data/datasources/gift_box_remote_datasource.dart` *(yeni)*
- `mobile/lib/features/gift_box/presentation/providers/gift_box_providers.dart` *(yeni)*
- `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `mobile/lib/features/auth/data/repositories/auth_repository_impl.dart`
- `mobile/lib/features/auth/domain/repositories/auth_repository.dart`
- `mobile/lib/features/auth/domain/entities/active_session_entity.dart`
- `mobile/lib/features/profile/presentation/pages/active_devices_page.dart`
- `mobile/lib/features/voice_hub/domain/entities/chat_room_sse_event.dart`
- `mobile/test/core/network/api_endpoint_canonical_contract_test.dart`
- `mobile/test/features/gift_box/gift_box_contract_test.dart` *(yeni)*
- `mobile/test/features/auth/active_session_entity_test.dart` *(yeni)*
- `mobile/pubspec.yaml`, `mobile/CHANGELOG.md`

---

## C) Kullanılan gerçek backend endpointleri

### Gift Box
| Metot | Yol | Auth (OpenAPI) |
|-------|-----|----------------|
| GET | `/api/gift-box?roomId=&streamId=` | mobileJwt |
| POST | `/api/gift-box` (+ query roomId/streamId; body OpenAPI + BÖLÜM 22 `action`) | mobileJwt |
| GET | `/api/gift-box/{boxId}` | public |
| POST | `/api/gift-box/{boxId}/join` | mobileJwt |
| POST | `/api/gift-box/share` | mobileJwt |
| GET | `/api/chat/rooms/{roomId}/sync` | (sync — OpenAPI) |
| GET | `/api/video-streams/{streamId}/sync` | (sync — OpenAPI) |

### Session
| Metot | Yol | Gövde / query |
|-------|-----|----------------|
| POST | `/api/auth/logout-all` | `{ removeDevices?: boolean }` (`authentication.md`) |
| GET | `/api/auth/sessions` | optional `deviceId` |
| DELETE | `/api/auth/sessions` | `deviceId` query |

Yedek: `GET/DELETE /api/auth/mobile-sessions` (mevcut).

---

## D) Authentication durumu

- Tüm yeni çağrılar mevcut `dio_provider` Bearer JWT ile yapılır.
- `logout-all` sonrası `AuthRepository.logoutAllDevices` → API + yerel token/cookie temizliği (mevcut `logout()` akışı).

---

## E) Wallet / Coin durumu

Aşama 2 ile uyumlu; bu aşamada değişiklik yok:

- Birincil `GET /api/wallet` — `jetonBalance`, `cfcBalance`, `credits`, `coins`
- Yedek `GET /api/user/wallet`

---

## F) Gift durumu

- Idempotency başlıkları (Aşama 2) korundu.
- Gift Box **ayrı** ekonomi akışı (emanet / katılma); mevcut `POST /api/gifts/send` ve motor SSE değiştirilmedi.

---

## G) Gift Box durumu

- **API katmanı hazır**; tam ekran UI bağlanmadı (mevcut `_GiftBoxButton` / `VoiceOnlineGiftBox` dekoratif; backend kutusu değil).
- Yanıt şemaları OpenAPI’de `MISSING` — istemci ham `Map` döndürür; UI eklenirken BÖLÜM 22 alanları kullanılmalı.
- SSE: `gift_box_*` olayları `ChatRoomSseEventType.giftBox` ile sınıflandırılır; iş mantığı UI katmanında henüz bağlanmadı.

---

## H) Live Stream durumu

Doğrulama (değişiklik gerekmedi):

- `video-streams` create/join/leave/end/live-started/media-heartbeat/stream/gifts — `api_endpoints` + `live_remote_datasource`
- **Yeni:** `videoStreamSync` sabiti + `GiftBoxRemoteDataSource.fetchStreamSync` (yeniden bağlanma senkronu için hazır)

---

## I) Voice Room durumu

Doğrulama (değişiklik gerekmedi):

- room/members/seats/presence heartbeat POST/join/leave/gift/SSE — mevcut `chat_room_remote_datasource`
- **Yeni:** `chatRoomSync` + `fetchRoomSync`; SSE `gift_box` tipi

---

## J) PK durumu

- Client-side skor POST **eklenmedi** (kural).
- Mevcut PK SSE / battle uçları korundu; Aşama 3’te PK kodu değiştirilmedi.

---

## K) Realtime / SSE durumu

- `gift_received` (Aşama 2) + `gift_box` tipi (Aşama 3).
- `websocket_events.md` / BÖLÜM 22 olay adları uydurulmadı; yalnızca `gift_box` kök tipi eklendi.
- Reconnect sonrası `sync` çağrısı için datasource metotları var; otomatik reconnect hook’u bu aşamada eklenmedi (mevcut SSE backoff korundu).

---

## L) Session / Logout durumu

- Aktif cihazlar: Abacus `GET /api/auth/sessions` birincil.
- Tek cihaz: `DELETE ?deviceId=` (entity `deviceId` desteği).
- Tüm cihazlar: `POST /api/auth/logout-all` + UI onay diyaloğu.

---

## M) Test sonuçları

*(CI/agent çıktısı — `flutter analyze`, `api_endpoint_canonical_contract_test`, `economy_integration_test`, gift_box + active_session testleri)*

---

## N) Hâlâ doğrulanamayan endpointler / şemalar

| Konu | Not |
|------|-----|
| `POST /api/user/fortunes` | OpenAPI: yalnız GET + PATCH — **uygulanmadı** |
| `PATCH /api/payments/requests` (iptal) | OpenAPI: GET + POST — **uygulanmadı** |
| Burç `zodiacSign` query | OpenAPI: `lang` — **uygulanmadı** |
| Gift Box response JSON | OpenAPI `MISSING` |
| `POST /api/gift-box/share` body | OpenAPI body yok; BÖLÜM 22 `scope/targetId/channel` |
| `GET /api/auth/sessions` response | OpenAPI `MISSING` |

---

## O) Backend’den alınması gereken eksik bilgiler

1. Gift Box OpenAPI request/response şemalarının kaynak TS ile tam eşleşmesi.
2. `GET /api/auth/sessions` örnek JSON (devices vs sessions dizisi, `lastGlobalLogoutAt`).
3. Gift Box UI için ürün kararı: canlı / sesli oda hangi ekranda açılır.

---

## P) Flutter tarafında kalan işler

1. Gift Box tam UI (oluştur / katıl / iptal / paylaşım görevi) — provider hazır.
2. SSE `giftBox` olaylarını oda/yayın state’ine bağlama + `sync` sonrası state replace (BÖLÜM 22 §6).
3. İsteğe bağlı: yayın SSE tarafında `gift_box` tipi (video stream parser).
4. Cihaz P0 testleri (`Psychic P0`) — release gate değişmedi.

---

*Aşama 1–2 raporları: `docs/ABACUS_FLUTTER_INTEGRATION_REPORT.md`, `docs/ABACUS_FLUTTER_INTEGRATION_PHASE2.md`*
