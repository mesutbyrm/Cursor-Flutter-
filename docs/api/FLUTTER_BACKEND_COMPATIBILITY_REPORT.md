# CanlıFal — Flutter Backend Uyumluluk Raporu

> **Oluşturulma:** 16 Temmuz 2026  
> **Backend:** Next.js 14 API Routes (`https://canlifal.com`)  
> **Toplam endpoint:** ~431 (Admin ~130, Kullanıcı ~301)  
> **Dual auth:** 238 endpoint (Bearer JWT + NextAuth Session)  
> **SSE:** 5 endpoint  
> **Mobil referans:** [`FLUTTER_ENTegrasyon_KILAVUZU.md`](../FLUTTER_ENTegrasyon_KILAVUZU.md) (öncelikli)

---

## Özet

Backend büyük ölçüde Flutter uyumlu. Mobil istemci:

- JWT `Authorization: Bearer` ile tüm korumalı uçlara bağlanır
- Yeni `{ success, data, error }` zarfını **ve** eski düz JSON / `{ error: "..." }` formatını parse eder (`ServiceUtils`, `LiveFieldApiUtil`, `ApiResponse`)
- Gerçek zamanlı için **SSE** kullanır (kılavuz §5); HTTP polling yalnızca yedek
- Saha canlı API: `/api/live/*` + `/api/trtc/token` — bkz. [`FLUTTER_API_REFERENCE_LIVE_FIELD.md`](FLUTTER_API_REFERENCE_LIVE_FIELD.md)
- Birleşik mobil uçlar: `/api/mobile/home`, `/api/mobile/fortune-menu`, `/api/mobile/user-profile/{id}`

---

## 1. Kimlik doğrulama

| Endpoint | Durum |
|----------|--------|
| `POST /api/auth/mobile-login` | ✅ |
| `POST /api/auth/mobile-register` | ✅ |
| `POST /api/auth/mobile-refresh` | ✅ |
| `POST /api/auth/mobile-google` | ✅ |
| `POST /api/auth/mobile-apple` | ✅ |
| `POST /api/auth/mobile-tiktok` | ✅ |
| `POST /api/auth/change-password` | ✅ dual auth |
| Token blacklist / cihaz oturumu | ❌ yok (düşük öncelik) |

**Token:** Access 7 gün, Refresh 30 gün. Payload: `userId`, `email`, `role`, `type`.

---

## 2. Standart API yanıt formatı

```json
{ "success": true, "data": { ... }, "pagination": { ... } }
{ "success": false, "error": { "code": "...", "message": "..." } }
```

**Flutter:** `mobile/lib/core/api_response.dart`, `service_utils.dart`, `live_field_api_util.dart`

Eski formatlar hâlâ üretimde; kademeli geçiş devam ediyor.

---

## 3. SSE kataloğu

| Endpoint | Olaylar |
|----------|---------|
| `GET /api/chat/rooms/{id}/stream` | message, presence, typing, system, gift, pk |
| `GET /api/video-streams/{id}/stream` | streamMessage, viewerCount, streamEnded, gift |
| `GET /api/room/{sessionId}/stream` | message, timer_started, session_ended, … |
| `GET /api/fortune-tellers/sessions/stream` | session_request, session_cancelled |
| `GET /api/notifications/stream` | notification |

---

## 4. Saha canlı API (`/api/live/*`)

Tam referans: [`FLUTTER_API_REFERENCE_LIVE_FIELD.md`](FLUTTER_API_REFERENCE_LIVE_FIELD.md)

| Modül | Mobil dosya |
|-------|-------------|
| Oda yaşam döngüsü | `live_field_room_lifecycle_api.dart` |
| Oda keşif | `live_field_room_discovery_api.dart` |
| Koltuk | `live_field_seats_api.dart` (`take/leave/swap/force`) |
| Mesaj | `live_field_message_api.dart` |
| Hediye | `live_field_gift_api.dart` |
| PK | `live_field_pk_api.dart` |
| Çevrimiçi | `live_field_online_users_api.dart` |
| TRTC | `trtc_remote_datasource.dart` → `POST /api/trtc/token` |

---

## 5. Mobil birleşik endpoint'ler

| Endpoint | Mobil entegrasyon |
|----------|-------------------|
| `GET /api/mobile/config` | `ConfigService` + `MobileConfigGate` |
| `GET /api/mobile/home` | `MobileCompoundService` → ana sayfa (canlı, sesli, fal kartları, falcılar) |
| `GET /api/mobile/fortune-menu` | `MobileCompoundService` + `fortuneMenuTypesProvider` |
| `GET /api/mobile/user-profile/{id}` | `MobileCompoundService` → `ProfileRemoteDataSource.user` |

---

## 6. Kritik eksikler (backend) — durum

| Öğe | Durum |
|-----|--------|
| Apple Sign-In | ✅ `/api/auth/mobile-apple` |
| Mobile config | ✅ `/api/mobile/config` |
| User block / report | ✅ eklendi |
| Standart response geçişi | 🟡 kademeli |
| Token blacklist | ❌ |

---

## 7. Web-only (mobil kullanmaz)

- `GET /api/share-card` (HTML)
- `GET /api/docs/download`
- `GET /api/settings/themes`

---

## 8. Öncelik — mobil taraf

1. Birleşik `/api/mobile/home` ile ana sayfa (tek istek) — **uygulandı**
2. `/api/live/join-room` compound katılım — **uygulandı**
3. SSE birincil, polling yedek — **uygulandı**
4. Yeni + eski response parse — **uygulandı**
5. Fal menüsü API (`/api/mobile/fortune-menu`) — **uygulandı**

---

## İlgili dosyalar

- `mobile/lib/services/mobile_compound_service.dart`
- `mobile/lib/services/models/mobile_compound_models.dart`
- `docs/api/CANLIFALTV_FLUTTER_API.md` — geniş API indeksi
- `docs/api/CANLIFALTV_FLUTTER_PARITY.md` — CanlifalTV parite haritası
