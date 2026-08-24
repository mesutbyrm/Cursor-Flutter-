# FAZ 0 — Backend ↔ Flutter Parity Audit

**Tarih:** 2026-08-18 (güncelleme: B1.12 + canlı probe)  
**Kaynak önceliği:** (1) `backend-docs/` (OpenAPI, endpoints_index, B1.12) → (2) Canlı HTTP probe → (3) `FLUTTER_ENTegrasyon_KILAVUZU.md` → (4) Flutter kodu

---

## 0. B1.12 özet (11 Ağustos 2026 — `backend-docs/B1_12_API_MCP_FLUTTER_PARITY.md`)

| Ölçüm | Değer |
|--------|-----:|
| ANA backend method-endpoint | **704** |
| Flutter benzersiz endpoint | **296** |
| ✅ MATCH (ANA) | **194** |
| ✅ MATCH (İKİNCİ games API) | **16** |
| ⚠️ WRONG_HOST | **12** (`/api/gifts/insights/*`, `/api/gifts/missions*`) |
| ⚠️ MISSING_BACKEND_ENDPOINT | **68** |
| ➖ LEGACY_UNUSED | **6** |

**En kritik WRONG_HOST:** Router `api_backend_router.dart` yalnızca `gifts/battles` ve `gifts/goals` için İKİNCİ API'ye yönlendiriyor; insights/missions ANA'da 404.

**Müzik (B1.12):** `/api/chat/music/popular`, `/api/chat/youtube-audio` listede eksik. **Canlı probe (18 Ağu 2026):** `youtube-audio?videoId=` **var**; `?url=` **400**; `music-request-by-query` **404**.

---

## 1. Envanter özeti

| Kaynak | Sayı |
|--------|-----:|
| Backend handler (`backend-docs/openapi.json`) | ~690 |
| Backend benzersiz path (`endpoints_index.json`) | ~438 |
| Matrix satırı (`API_ENDPOINT_MATRIX.md`) | 873 |
| Flutter `api_endpoints.dart` sabit | ~471 |
| B1.12 Flutter çağrıları | 296 |
| B1.12 doğru eşleşme | 210 |

---

## 2. Alan bazlı parity

### 2.1 Auth

| Konu | Backend (kılavuz) | Flutter | Parity |
|------|-------------------|---------|--------|
| Login | `POST /api/auth/mobile-login` | `auth_remote_datasource.dart` | ✅ |
| Register | `POST /api/auth/mobile-register` | ✅ | ✅ |
| Refresh | `POST /api/auth/mobile-refresh` | `auth_token_refresh_coordinator.dart` | ✅ |
| Me | `GET /api/me` | ✅ | ✅ |
| Token depolama | JWT Bearer | `flutter_secure_storage` | ✅ |
| `sub` ≠ user key | `realCid` / `gcid` | Kılavuz uyarısı mevcut | ⚠️ Doğrulanmalı |

### 2.2 Sesli oda (Voice Hub)

| Konu | Backend (kılavuz §9.3) | Flutter | Parity |
|------|------------------------|---------|--------|
| Oda listesi | `GET /api/chat/rooms` | `voice_rooms_discover_*` | ✅ |
| Presence | `POST .../presence` `{action: join\|leave}` | `chat_room_remote_datasource.dart` | ✅ |
| SSE | `GET .../stream` | `chat_room_sse_service.dart` | ✅ |
| Koltuk | `POST .../seats` | `chat_room_providers_seat.dart` | ✅ |
| Voice session | `POST .../voice` | `joinVoiceSession` | ✅ |
| Müzik istek | `POST .../song-request` (üretim) | `requestMusic` / fallback | ✅ / ⚠️ `music-request-by-query` **404** üretimde |
| Şarkı kuyruğu | `POST .../song-request` | `enqueueSongUseCase` | ✅ |
| Stream resolve | `GET /api/chat/youtube-stream` | `resolveStreamUseCase` | ✅ |
| TRTC token | `/api/trtc/token` | `trtc_remote_datasource.dart` | ✅ |
| PK | `/api/pk/*` | `pk_battle_remote_*` | ⚠️ E2E doğrulanmalı |

### 2.3 Canlı yayın (Live)

| Konu | Flutter | Parity |
|------|---------|--------|
| Oda keşfi | `live_field_room_discovery_api.dart` | ✅ |
| Broadcast | `live_broadcast_room_page.dart` + TRTC | ✅ |
| SSE video | `video_stream_sse_service.dart` | ✅ |
| PK | `live_pk_*`, `pk_match_sse_service.dart` | ⚠️ |
| Gift realtime | Socket.IO + SSE | ⚠️ Dual path |

### 2.4 Hediye + Jeton

| Konu | Backend | Flutter | Parity |
|------|---------|---------|--------|
| Gift catalog | `/api/gifts/types` | `gifts/` modülü | ✅ |
| Send gift | Kılavuz §9.9 | `gift_providers.dart` | ✅ |
| Jeton wallet | `/api/wallet/*` | `wallet/` | ✅ |
| Bakiye hesabı | Backend authoritative | Flutter gösterir | ✅ (doğru model) |
| Global gift SSE | SSE event adları | `gift_sse_dispatch.dart` | ⚠️ Event şeması doğrulanmalı |

### 2.5 Profil + Sosyal

| Konu | Flutter | Parity |
|------|---------|--------|
| Profil hub | `profile_hub/` | ✅ Geniş |
| Sosyal feed | `social/` Instagram-style | ✅ |
| Stories | `story_viewer_page.dart` | ✅ |
| Shorts | `shorts/` | ⚠️ Performans E2E |

### 2.6 Fal + Tarot

| Konu | Flutter | Parity |
|------|---------|--------|
| Fal türleri | `fortune/` (~107 dosya) | ✅ Geniş |
| SSE streaming | `fortune_sse_service.dart` | ✅ |
| Falcı oturumu | `live_psychics/` | ✅ |

### 2.7 Bildirim + Mesaj

| Konu | Flutter | Parity |
|------|---------|--------|
| Notification list | `notifications/` | ✅ |
| Notification SSE | `notifications_sse_service.dart` | ✅ |
| DM | `messages/` + SSE | ✅ |

---

## 3. SSE event parity (doğrulanması gereken)

Backend'den **event adı + JSON şema** dosyası olmadan tam parity iddia edilemez.

| Stream | Flutter parser | Backend şema |
|--------|----------------|--------------|
| Chat room | `chat_room_sse_event.dart`, `voice_sse_dj_payload.dart` | ❌ Repoda yok |
| Live video | `video_stream_sse_service.dart` | ❌ |
| Notifications | `notifications_sse_service.dart` | ❌ |
| Fortune | `fortune_sse_service.dart` | ❌ |
| PK | `pk_match_sse_service.dart` | ❌ |

---

## 4. MCP parity

| Özellik | Backend MCP (hedef) | Flutter repo MCP (`mcp-server/index.mjs`) |
|---------|---------------------|-------------------------------------------|
| `list_endpoints` | `backend-docs/endpoints_index.json` | ✅ Dosya repoda; MCP stub henüz okumuyor |
| `get_endpoint` | route.ts kaynak kodu | Matrix satırı |
| `list_models` / `get_model` | `backend-docs/schema.prisma` | ❌ Stub yok |
| `read_source` | `nextjs_space/` | ❌ Yok |
| OpenAPI resource | `backend-docs/openapi.json` | ❌ Stub yok |

**Sonuç:** `backend-docs/` **SAĞLANDI** (18 Ağu 2026). Tam MCP `index.mjs` hâlâ eksik.

---

## 5. Bilinen sapmalar (endpoint icat etmeden)

| # | Konu | Flutter | Backend beklentisi | Öncelik |
|---|------|---------|-------------------|---------|
| 1 | Games API | `api_backend_router.dart` → ayrı origin | PK/games path'leri | P1 — dokümante |
| 2 | Legacy auth path | Sabitlerde eski path | Kullanılmamalı | P2 |
| 3 | Socket.IO gifts | Live gift realtime | SSE mi? | P1 — backend onayı |
| 4 | Müzik ANR / !istek | `music-request-by-query` 404 → `song-request` yedeği eklendi; proxy düzeltildi | **P0** — Android E2E bekliyor |
| 5 | `api/` mirror | Express JWT API | Üretim değil | Bilgi |

---

## 6. Parity skoru (tahmini)

| Alan | API | SSE | RTC | UI | Android E2E |
|------|-----|-----|-----|----|----|
| Auth | PASS | N/A | N/A | PASS | ⚠️ |
| Voice | PASS | ⚠️ | PASS | FAIL (ANR) | FAIL |
| Live | PASS | ⚠️ | PASS | ⚠️ | ⚠️ |
| Gifts | PASS | ⚠️ | N/A | PASS | ⚠️ |
| Profile | PASS | N/A | N/A | PASS | ⚠️ |
| Social | PASS | N/A | N/A | PASS | ⚠️ |
| Fortune | PASS | ⚠️ | PASS | PASS | ⚠️ |
| Shorts | ⚠️ | N/A | N/A | ⚠️ | ⚠️ |

**Genel FAZ 0 parity:** **INCOMPLETE** — tam MCP + route.ts kaynağı + SSE şeması eksik; Voice müzik fix kodlandı, cihaz doğrulaması bekliyor.

---

## 7. FAZ 0 çıktısı

- Parity haritası oluşturuldu ✅
- `backend-docs/` entegre edildi ✅ (18 Ağu 2026)
- B1.12 raporu repoda ✅
- `music-request-by-query` üretim 404 tespit edildi; Flutter yedeği eklendi ✅
- FAZ 1'e geçiş: **Tam MCP + P0 müzik Android PASS**
