# CanliFal — Performance Report

**Date:** 2026-08-04  
**App version:** `1.0.125+159`  
**APK:** ❌ Derlenmedi (audit aşaması)

---

## Hedef metrikler (kullanıcı gereksinimi)

| Metrik | Hedef | Mevcut durum | Durum |
|--------|-------|--------------|-------|
| Cold start | < 2 s | Ölçüm yok (CI emülatör yok) | ⚠️ Doğrulanmadı |
| Profil yükleme | < 1 s | Cache + `/api/me` | ⚠️ Cihaza bağlı |
| Oda yükleme | < 1 s | TRTC bootstrap + presence | ⚠️ İlk join 1–3 s tipik |
| Canlı yayına katılım | < 2 s | TRTC token + join | ⚠️ Ağa bağlı |
| Hediye animasyonu | 60 FPS | Prefetch gecikmesi düzeltildi | 🟡 İyileşti |
| Kaydırma | 60 FPS | `lazy_screen_section`, shimmer | ⚠️ Ağır ekranlarda risk |
| CPU | Minimal | TRTC + SSE + WebView | 🔴 Oda içi yüksek |
| RAM | Minimal | Video cache, gift preload | 🟡 Orta risk |

---

## Yavaş ekranlar (LOC / karmaşıklık)

| Dosya | LOC | Risk |
|-------|----:|------|
| `chat_room_providers.dart` | 3,920 | Tek notifier — tüm oda state |
| `live_broadcast_room_page.dart` | 2,665 | Monolitik widget |
| `chat_room_remote_datasource.dart` | 2,604 | Senkron API yükü |
| `voice_room_rtc_page.dart` | 1,833 | 15+ `ref.watch` |
| `voice_room_dj_player.dart` | 1,423 | Audio + sync |
| `app_router.dart` | 1,089 | Route tablosu |

---

## Gereksiz rebuild kaynakları

1. **`ref.watch(voiceRoomLiveProvider)`** — tüm oda state değişiminde alt widget rebuild
2. **`VoiceRoomsPresenceNotifier`** — keşifte 12 paralel SSE
3. **Premium 2026 widget ağaçları** — `const` eksikliği (genel)
4. **Çift müzik katmanı** — `VoiceRoomDjPlayer` (just_audio) + `RoomSongMiniPlayer` (IFrame)

---

## Bellek riskleri

| Alan | Dosya | Risk |
|------|-------|------|
| Gift timers | `gift_session_controller.dart` | `_feedExpiryTimers`, `_animationTimer` — dispose var |
| Video controllers | `gift_media_widget.dart`, `youtube_video_background.dart` | Warm cache release |
| SSE hub | `sse_connection_hub.dart` | Ref-count; leak düşük |
| TRTC | `trtc_room_manager.dart` | `dispose` zorunlu — leave flow düzeltildi |

---

## FPS / CPU — sesli oda

- **TRTC** encode/decode — ana CPU tüketicisi
- **YouTube IFrame WebView** — ikinci CPU (müzik video modu)
- **Hediye MP4** — `video_player` + overlay fade
- **Öneri:** Video müzik modunda just_audio devre dışı; yalnızca IFrame sesi

---

## Ağ performansı

| Sorun | Etki |
|-------|------|
| `youtube_explode_dart` fallback | Ekstra istek + yasaklı pattern (prod politikası) |
| `music-stream` resolve | Gereksiz googlevideo proxy |
| Discover 12 SSE | Pil + bant genişliği |
| HTTP cache | `api_http_cache.dart` — home, profile kısmen |

---

## Mevcut optimizasyon araçları

- `core/performance/state_perf.dart`
- `core/performance/voice_room_entry_perf.dart`
- `core/performance/live_entry_perf.dart`
- `core/performance/device_perf_tuning.dart`
- `RepaintBoundary` — mini player, gift overlay
- `SseConnectionHub` — ref-counted bağlantılar

---

## Öncelikli iyileştirmeler

1. **Müzik:** Tek oynatıcı — IFrame-only; `resolveStreamUrl` kaldır
2. **`chat_room_providers` böl** — seat/gift/music/presence ayrı notifier
3. **Discover SSE** — 12 → 4–6 veya hub multiplex
4. **Agora/LiveKit sil** — binary boyutu + karışıklık
5. **Cold start profili** — Firebase/OneSignal lazy init doğrula
6. **Perf benchmark CI** — `integration_test` cold start ölçümü ekle

---

## Sonuç

Performans hedefleri **tam karşılanmıyor**. Kritik yol: sesli oda (TRTC + SSE + müzik + hediye). APK benchmark yapılmadan release önerilmez.
