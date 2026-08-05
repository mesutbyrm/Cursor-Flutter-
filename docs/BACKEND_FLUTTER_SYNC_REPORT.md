# Backend ↔ Flutter Senkronizasyon Raporu

> **Tarih:** 5 Ağustos 2026  
> **Tek kaynak:** `https://canlifal.com` + `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` + `api/` mirror  
> **Sürüm:** `1.0.140+174` (SSE poll azaltma P1)

## Özet

| Alan | Backend durumu | Flutter durumu | Öncelik |
|------|----------------|----------------|---------|
| Müzik `!istek` | `song_*` SSE + `musicUrl` | ✅ 1.0.138 düzeltildi | Tamam |
| Fal otomatik paylaşım | `POST /api/social/posts/auto-fortune` | ✅ 1.0.139 düzeltildi | Tamam |
| Canlı yayın | `POST /api/video-streams`, SSE `streamEnded` | ✅ Host `streamEnded` UI (1.0.139) | Doğrula |
| Canlı falcı | SSE + `/api/room/*` | ✅ 1.0.140 SSE-primary poll | Tamam |
| Sesli oda koltuk | `POST .../seats` `{action:take}` | ✅ `_tryAutoPrivilegedSeat` | Doğrula |
| Oda ayarları | `PATCH .../settings` | ⚠️ 2 ölü sheet `@Deprecated` + aktif panel | P2 |
| Jeton | Sunucu hesaplar | ✅ `wallet`/`credits` okuma | İzle |
| Performans | SSE tercih | ⚠️ `voice_room_rtc_page` mega-widget | P1 |

---

## 1) Backend endpoint envanteri (kılavuz §9)

Üretim: **384** API, **149** Prisma model. Mobil referans: `mobile/lib/core/network/api_endpoints.dart` (~200+ sabit path).

### Canlı yayın (`LiveStreamRepository`)

| Metot | HTTP | Path | Flutter |
|-------|------|------|---------|
| createStream | POST | `/api/video-streams` | `live_remote_datasource.createVideoStream` |
| live-started | POST | `/api/video-streams/{id}/live-started` | `notifyLiveStarted` |
| join | POST | `/api/video-streams/{id}/join` | `joinVideoStream` |
| end | POST | `/api/video-streams/{id}/end` | `endVideoStream` |
| signal | POST | `/api/video-streams/{id}/signal` | heartbeat `type:ping` |
| SSE | GET | `/api/video-streams/{id}/stream` | `video_stream_sse_service` |

**İş kuralı (mirror `api/src/routes/video_streams.ts`):** Yayın `POST /` ile oluşturulur; `status: live`. İzleyici `join` yalnızca `live` iken. `end` yalnızca yayıncı. SSE `streamEnded` tüm istemcilere gider.

**Flutter sapması:** ~~yalnızca izleyici~~ → 1.0.139'da host `streamEnded` eklendi. 1.0.140'da SSE bağlıyken poll aralıkları yavaşlatıldı.

### Fal otomatik paylaşım

| Metot | HTTP | Body (backend `autoFortuneSchema`) |
|-------|------|-------------------------------------|
| auto-fortune | POST | `fortuneSlug`, `summary`, `fortuneType?`, `detail?`, `imageUrl?`, `fortuneId?`, `visualAnalysis?` |

**Kaynak:** `api/src/routes/socialPosts.ts` — sunucu `SocialPost` oluşturur, `isAutoShare: true`, takipçilere `fortune_share` bildirimi.

**Flutter:** 1.0.139'da `FortuneShareHandler` → `POST auto-fortune` + feed prepend.

### Sesli oda koltuk (kılavuz §9.3)

| Metot | HTTP | Body |
|-------|------|------|
| takeSeat | POST | `/api/chat/rooms/{id}/seats` `{action:"take", seatIndex}` |

Flutter: `joinSeat` → önce `join-seat` (404 toleranslı), sonra `seats`. Oda sahibi: `chat_room_providers_seat._tryAutoPrivilegedSeat`.

### Canlı falcı

| Metot | HTTP | Flutter |
|-------|------|---------|
| createSession | POST | `/api/fortune-tellers/{id}/session` |
| updateSession | PATCH | `/api/fortune-tellers/sessions/{id}` |
| room | GET/PATCH | `/api/room/{sessionId}` |
| SSE incoming | GET | `/api/fortune-tellers/sessions/stream` |
| SSE room | GET | `/api/room/{id}/stream` |

**Durum (1.0.140):** SSE bağlıyken sinyal poll 30 sn; oda/sohbet poll 20 sn. Falcı paneli event bus + 20 sn yedek HTTP.

---

## 2) Düzeltilenler

| Dosya | Değişiklik |
|-------|------------|
| `fortune_share_handler.dart` | `POST /api/social/posts/auto-fortune` + anında feed prepend (1.0.139) |
| `social_*_datasource/repository` | `@Deprecated` kaldırıldı — backend sözleşmesi geçerli |
| `live_broadcast_room_page.dart` | Host `streamEnded` UI (1.0.139); SSE-aware poll (1.0.140) |
| `psychic_video_controller.dart` | SSE bağlıyken sinyal poll 30 sn (1.0.140) |
| `psychic_teller_dashboard_screen.dart` | Event bus + 20 sn yedek poll (1.0.140) |
| `psychic_incoming_host.dart` | SSE istek → event bus yayını (1.0.140) |
| `voice_room_sheets.dart` / `voice_room_hub_settings.dart` | Ölü sheet'ler `@Deprecated` (1.0.140) |
| `docs/BACKEND_FLUTTER_SYNC_REPORT.md` | Bu rapor |

---

## 3) Kalan işler (öncelik sırası)

### P0 — Kritik
- [ ] Canlı yayın açılmama: TRTC token / `createVideoStream` yanıt parse — sahada log topla
- [ ] Fal paylaşım: bu oturum fix'i cihazda doğrula

### P1 — Senkron + performans
- [x] `psychic_video_controller.dart` — SSE-primary, poll azalt (1.0.140)
- [x] `psychic_teller_dashboard_screen.dart` — event bus + yavaş yedek poll (1.0.140)
- [x] `live_broadcast_room_page.dart` — SSE bağlıyken poll yavaşlat (1.0.140)
- [ ] `voice_room_rtc_page.dart` — selective `ref.watch` / widget bölme
- [x] Ölü `voice_room_sheets.dart` / `voice_room_hub_settings.dart` → `@Deprecated`

### P2 — Tam parity
- [ ] `FEATURE_PARITY_REPORT.md` maddeleri tek tek kapat
- [ ] Jeton animasyonları — yalnızca backend event'lerinden
- [ ] Eksik admin/moderasyon ekranları
- [ ] Oda ayarları tek sayfa (`voice_room_management_panel` canonical)

---

## 4) Performans hedefleri vs mevcut

| Metrik | Hedef | Mevcut risk |
|--------|-------|-------------|
| Sayfa açılışı | <1s | Home feed + çoklu provider |
| Oda girişi | <1s | SSE + presence + seat retry |
| Canlı yayın | <2s | TRTC + createVideoStream sıralı |

**Hızlı kazanımlar:** SSE varken poll iptal, `const`/`RepaintBoundary`, `CachedNetworkImage` (çoğu yerde var), duplicate `refresh()` azaltma.

---

## 5) Test kontrol listesi

- [ ] `!istek` ses + video (1.0.138)
- [ ] Fal sonrası sosyal akışta anında gönderi (auto-fortune)
- [ ] Canlı yayın başlat / bitir / izleyici join
- [ ] Backend `streamEnded` → host + izleyici UI
- [ ] Oda sahibi otomatik koltuk
- [ ] Falcı istek kabul/red jeton

---

*Son güncelleme: agent oturumu — backend-first analiz sonrası ilk düzeltme dalı.*
