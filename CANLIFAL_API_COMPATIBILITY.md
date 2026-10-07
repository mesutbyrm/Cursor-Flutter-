# CANLIFAL — API Uyumluluk Denetimi

**Base URL:** `https://canlifal.com`  
**Tek kaynak:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`  
**Bu oturum:** Canlı endpoint probe **yapılmadı** (production’a gereksiz yük / kullanıcı talimatı). Aşağıdaki tablo **kod envanteri + Telefon A log** ile sınırlıdır.

---

## 1. Doğrulama yöntemi

| Yöntem | Durum |
|--------|--------|
| Gerçek cihaz + Dio log | **Kısmi** — Telefon A diagnostic |
| Otomatik acceptance (`run-acceptance-tests.sh`) | **BLOCKED** — VM’de Flutter yok |
| Statik `api_endpoints.dart` vs kılavuz | **Kısmi** |

---

## 2. Logda görülen uçlar (Telefon A — gerçek trafik)

| Method | Endpoint | HTTP | Not |
|--------|----------|------|-----|
| GET | `/api/warmup` | — | Açılış |
| DELETE | `/api/chat/rooms/{id}/presence?leave=1` | — | Ghost presence temizliği |
| GET | `/api/me` | — | Auth |
| GET | `/api/fortune-tellers` | — | Canlı Falcılar listesi |
| GET | `/api/fortune-tellers/my-profile` | — | Falcı rolü |
| GET | `/api/fortune-tellers/sessions?status=pending` | — | **Duplicate çağrı riski (P2)** |
| GET | `/api/fortune-tellers/session?sessionId=` | — | Canlı fal durum |
| GET | `/api/chat/rooms/{id}/messages` | — | Sesli oda |
| POST | `/api/chat/rooms/{id}/presence` | — | Sesli oda |
| PATCH | `/api/chat/rooms/{id}/seats` | — | Koltuk |
| GET | `/api/chat/rooms/{id}/gifts` | — | Hediye |
| GET | `/api/upload/get-url?path=…` | **401** | **P1** — görsel katmanı JWT göndermez |

**Auth header:** Diagnostic REQUEST logları `Authorization` içeriğini yazmaz; 401 get-url, Bearer’sız GET ile uyumlu.

---

## 3. SSE uçları (kod — `api_endpoints.dart`)

| SSE | Path (özet) | Flutter kullanım |
|-----|-------------|------------------|
| Sesli oda | `/api/chat/rooms/{roomId}/stream` | Voice hub |
| Canlı fal oda | `liveFortuneRoom(sessionId)/stream` | Psychic room SSE |
| Falcı gelen | `/api/fortune-tellers/sessions/stream` | Incoming host |
| Bildirim | `/api/notifications/stream` | Global |
| DM | `/api/messages/{userId}/stream` | Messages |
| Video yayın | `/api/video-streams/{id}/stream` | Live |
| PK | `/api/pk/{matchId}/stream` | PK |

**Uyumluluk testi:** **BLOCKED** — event parse / reconnect yalnızca cihazda doğrulanır.

---

## 4. Bilinen uyumsuzluk / risk (kanıt veya kod)

### P1 — Hediye / avatar URL şekli

- **Backend/katalog:** Tam URL olarak `…/api/upload/get-url?path=gift/…`  
- **Flutter beklentisi:** Doğrudan CDN veya oturumlu POST `uploadGetUrl` (`cloud_upload_service.dart` ~122–130)  
- **Sonuç:** Parse başarılı, **HTTP 401** — UI boş logo  
- **Dosya:** `canlifal_image_urls.dart`, `gift_entity.dart` (`CloudMediaUrl.resolve`)

### P2 — `GET` vs `POST` upload get-url

- Kılavuz: `POST /api/upload/get-url` body `{ cloud_storage_path, isPublic }`  
- Log: **GET** query `path=` — 401  
- **Öneri:** Katalog yalnızca cloud path döndürmeli veya mobil unwrap (731+)

### BLOCKED — POST `/api/live/join-room`

Canlı fal / yayın join-room body alanları bu oturumda **canlı probe edilmedi**.  
Kod: `chat_room_remote_datasource.dart` / live modülleri — retest gerekli.

---

## 5. Error response / timeout

- **Dio:** `dio_provider.dart` — 401 refresh queue (kılavuz §7)  
- **400** kayıtlı (Telefon A errors) — endpoint bazında retest ile eşleştirilmeli  
- **Timeout:** Voice TRTC leave 3–4 s (`voice_room_audio_coordinator.dart` ~314)

---

## 6. Sonraki adım (production-safe)

1. Acceptance secrets ile CI acceptance (read-only senaryolar)  
2. Cihazda Diagnostics Network sekmesi → endpoint + status export  
3. Kılavuz §9 repository tablosu ile `grep api_endpoints` diff (statik PR checklist)

**Bu dosya “tüm 384 API uyumlu” demez.**
