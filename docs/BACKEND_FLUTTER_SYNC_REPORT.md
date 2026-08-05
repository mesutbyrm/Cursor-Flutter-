# Backend ↔ Flutter Senkronizasyon Raporu

> **Tarih:** 5 Ağustos 2026  
> **Tek kaynak:** `https://canlifal.com` + `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` + `api/` mirror  
> **Sürüm:** `1.0.138+172` (müzik düzeltmesi sonrası)

## Özet

| Alan | Backend durumu | Flutter durumu | Öncelik |
|------|----------------|----------------|---------|
| Müzik `!istek` | `song_*` SSE + `musicUrl` | ✅ 1.0.138 düzeltildi | Tamam |
| Fal otomatik paylaşım | `POST /api/social/posts/auto-fortune` | ⚠️ Poll-only (bu oturumda düzeltiliyor) | P0 |
| Canlı yayın | `POST /api/video-streams`, SSE `streamEnded` | ⚠️ Host sonlandırma UI eksik | P0 |
| Canlı falcı | SSE + `/api/room/*` | ⚠️ Gereksiz HTTP poll | P1 |
| Sesli oda koltuk | `POST .../seats` `{action:take}` | ✅ `_tryAutoPrivilegedSeat` | Doğrula |
| Oda ayarları | `PATCH .../settings` | ⚠️ 2 ölü sheet + 1 aktif panel | P2 |
| Jeton | Sunucu hesaplar | ✅ `wallet`/`credits` okuma | İzle |
| Performans | SSE tercih | ⚠️ Çoklu poll + mega-widget | P1 |

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

**Flutter sapması:** `live_broadcast_room_page.dart` yalnızca **izleyici** için `streamEnded` dinliyor; yayıncı backend otomatik kapattığında özet ekranı yok.

### Fal otomatik paylaşım

| Metot | HTTP | Body (backend `autoFortuneSchema`) |
|-------|------|-------------------------------------|
| auto-fortune | POST | `fortuneSlug`, `summary`, `fortuneType?`, `detail?`, `imageUrl?`, `fortuneId?`, `visualAnalysis?` |

**Kaynak:** `api/src/routes/socialPosts.ts` — sunucu `SocialPost` oluşturur, `isAutoShare: true`, takipçilere `fortune_share` bildirimi.

**Flutter sapması (P0):** `FortuneShareHandler` yalnızca `GET /api/social/posts` poll yapıyor; web'in çağırdığı `POST auto-fortune` devre dışı bırakılmış (`@Deprecated`). Bu yüzden paylaşım gecikmeli veya hiç görünmüyor.

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

**Sapma:** `psychic_video_controller.dart` SSE varken 3–20 sn HTTP poll sürdürüyor.

---

## 2) Bu oturumda düzeltilenler

| Dosya | Değişiklik |
|-------|------------|
| `fortune_share_handler.dart` | `POST /api/social/posts/auto-fortune` + anında feed prepend |
| `social_*_datasource/repository` | `@Deprecated` kaldırıldı — backend sözleşmesi geçerli |
| `live_broadcast_room_page.dart` | Host için `streamEnded` → yayın sonu ekranı |
| `docs/BACKEND_FLUTTER_SYNC_REPORT.md` | Bu rapor |

---

## 3) Kalan işler (öncelik sırası)

### P0 — Kritik
- [ ] Canlı yayın açılmama: TRTC token / `createVideoStream` yanıt parse — sahada log topla
- [ ] Fal paylaşım: bu oturum fix'i cihazda doğrula

### P1 — Senkron + performans
- [ ] `psychic_video_controller.dart` — SSE-primary, poll azalt
- [ ] `psychic_teller_dashboard_screen.dart` — 3s poll → incoming SSE
- [ ] `live_broadcast_room_page.dart` — host poll'ları SSE bağlıyken durdur
- [ ] `voice_room_rtc_page.dart` — selective `ref.watch` / widget bölme
- [ ] Ölü `voice_room_sheets.dart` / `voice_room_hub_settings.dart` kaldır veya birleştir

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
