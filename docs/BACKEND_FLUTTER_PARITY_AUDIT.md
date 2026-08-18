# FAZ 0 — Backend ↔ Flutter Parity Audit

**Tarih:** 2026-08-18  
**Kaynak önceliği:** (1) Backend canlı kod *(erişim yok)* → (2) OpenAPI/index *(repoda yok)* → (3) `FLUTTER_ENTegrasyon_KILAVUZU.md` → (4) `API_ENDPOINT_MATRIX.md` → (5) Flutter kodu

---

## 1. Envanter özeti

| Kaynak | Sayı |
|--------|-----:|
| Backend handler (doküman) | 690 |
| Backend benzersiz path (doküman) | 438 |
| Matrix satırı | 873 |
| Flutter `api_endpoints.dart` sabit | ~471 |
| Matrix ↔ Flutter bağlı (önceki audit) | 256 |
| Flutter-only path (önceki audit) | 180 |

> **Not:** Güncel sayılar backend MCP veya OpenAPI olmadan tam doğrulanamaz. Aşağıdaki tablolar mevcut doküman + kod taramasına dayanır.

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
| Müzik istek | `POST .../music-request-by-query` | `requestMusicByQuery` | ✅ API / ⚠️ ANR P0 |
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

## 4. MCP parity (kritik bulgu)

| Özellik | Backend MCP (yüklediğiniz README) | Flutter repo MCP (`mcp-server/index.mjs`) |
|---------|-----------------------------------|-------------------------------------------|
| `list_endpoints` | OpenAPI + `endpoints_index.json` | Yalnızca `API_ENDPOINT_MATRIX.md` |
| `get_endpoint` | route.ts kaynak kodu | Matrix satırı |
| `list_models` / `get_model` | `prisma/schema.prisma` | ❌ Yok |
| `read_source` / `search_source` | `nextjs_space/`, `lib/` | ❌ Yok |
| Resources | `openapi://`, `schema://prisma` | Audit MD dosyaları |

**Sonuç:** Flutter reposundaki MCP, backend MCP'nin **%30 stub** versiyonu. Tam parity için backend MCP paketi + kaynak dosyalar gerekli.

---

## 5. Bilinen sapmalar (endpoint icat etmeden)

| # | Konu | Flutter | Backend beklentisi | Öncelik |
|---|------|---------|-------------------|---------|
| 1 | Games API | `api_backend_router.dart` → ayrı origin | PK/games path'leri | P1 — dokümante |
| 2 | Legacy auth path | Sabitlerde eski path | Kullanılmamalı | P2 |
| 3 | Socket.IO gifts | Live gift realtime | SSE mi? | P1 — backend onayı |
| 4 | Müzik ANR | `!istek` donma | Çalışmalı | **P0** |
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

**Genel FAZ 0 parity:** **INCOMPLETE** — backend kaynak/OpenAPI/SSE şemaları eksik; Voice müzik P0 açık.

---

## 7. FAZ 0 çıktısı

- Kod değiştirilmedi ✅
- Parity haritası oluşturuldu ✅
- Eksik backend dosyaları `BACKEND_REQUIREMENTS_TO_REQUEST.md`'de listelendi ✅
- FAZ 1'e geçiş: **Backend eksikleri tamamlanana ve P0 müzik ANR doğrulanana kadar beklenmeli**
