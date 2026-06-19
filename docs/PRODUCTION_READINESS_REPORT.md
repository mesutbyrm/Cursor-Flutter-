# Production Readiness Sprint — Rapor (1.0.291+294)

Tarih: 2026-06-19  
Kapsam: Mevcut sistemleri bozmadan üretim kalitesi + web parity

---

## 1. Genel görüntülü arama sistemi

**Eklenen dosyalar**
- `mobile/lib/features/video_call/domain/video_call_invitation.dart`
- `mobile/lib/features/video_call/data/video_call_invitation_service.dart`
- `mobile/lib/features/video_call/presentation/video_call_provider.dart`
- `mobile/lib/features/video_call/presentation/incoming_video_call_screen.dart`

**Değiştirilen**
- `mobile/lib/app/widgets/main_app_shell.dart` — `VideoCallIncomingHost` overlay
- `mobile/lib/core/push/push_notification_service.dart` — `showLocal()` acil arama bildirimi

**Kazanım:** Tam ekran gelen arama UI, 30 sn timeout, kabul/red/meuşgul, kaçırılan arama bildirimi; mevcut canlı fal TRTC akışıyla uyumlu.

**Kalan risk:** Arka plan tam ekran intent Android OEM farklılıkları; üretimde `SENTRY_DSN` / FCM testi önerilir.

---

## 2. Falcı paneli

**Değiştirilen**
- `mobile/lib/features/home/presentation/providers/teller_dashboard_provider.dart` — SSE + aktif seans sayacı + anlık kazanç
- `mobile/lib/features/home/presentation/pages/teller_dashboard_screen.dart` — dakika ücreti, süre, SSE göstergesi

**Kazanım:** Gerçek zamanlı gelen çağrılar (SSE), bekleyen liste, kazanç göstergesi.

**Kalan risk:** 3 sn yedek poll hâlâ aktif (SSE kesintisinde güvenlik ağı).

---

## 3. SSE altyapısı tekilleştirme

**Eklenen**
- `mobile/lib/core/network/sse/base_sse_service.dart`
- `mobile/lib/features/voice_hub/data/services/notification_sse_service.dart`
- `mobile/lib/features/home/data/services/fal_sse_service.dart`
- `mobile/lib/features/messages/data/services/message_sse_service.dart`

**Değiştirilen**
- `mobile/lib/core/network/sse/sse_reconnect_policy.dart` — 1/2/5/10/20/30 sn
- `mobile/lib/features/voice_hub/data/services/chat_room_sse_service.dart` — `BaseSseService` türevi
- `mobile/lib/features/home/data/services/live_fortune_teller_incoming_sse_service.dart` — yeni politika

**Kazanım:** Ortak auth, reconnect, heartbeat, stream yaşam döngüsü.

**Kalan risk:** `VideoStreamSseService`, `LiveFortuneRoomSseService` henüz tam migrate edilmedi (geriye dönük uyumluluk).

---

## 4. Voice room provider parçalama

**Eklenen**
- `voice_room_provider.dart`, `voice_room_sse_provider.dart`, `voice_room_music_provider.dart`
- `voice_room_dj_provider.dart`, `voice_room_user_provider.dart`, `voice_room_queue_provider.dart`

**Değiştirilen**
- `chat_room_providers.dart` — SSE provider ayrıldı; barrel export yapısı

**Kazanım:** Modüler import, gelecek tam bölme için zemin.

**Kalan risk:** `VoiceRoomLiveController` (~2500 satır) hâlâ `chat_room_providers.dart` içinde — bir sonraki sprintte `part` veya tam taşıma.

---

## 5. Gerçek zamanlı online sayıları

**Eklenen**
- `mobile/lib/features/voice_hub/presentation/providers/voice_rooms_presence_provider.dart`

**Değiştirilen**
- `voice_rooms_body.dart` — 25 sn poll kaldırıldı
- `voice_room_entity.dart` — `copyWith`
- `home_realtime_bridge.dart` — oda listesi poll invalidation kaldırıldı
- `main_app_shell.dart` — presence provider bootstrap

**Kazanım:** SSE `presence` / `onlineUsers` ile anlık keşfet sayıları (ilk 12 oda).

**Kalan risk:** 12+ oda için ek bağlantı stratejisi veya global presence uç noktası gerekebilir.

---

## 6. Bellek kaçakları

**Düzeltilen**
- `feed_post_card.dart` — yorum sheet `TextEditingController` dispose (`_FeedCommentsSheet`)

**Raporlanan izleme listesi (manuel QA önerilir)**
- `voice_room_rtc_page.dart` — çoklu Timer/Subscription (mevcut dispose var, odadan çıkışta doğrula)
- `shorts_upload_page.dart` — `VideoPlayerController` preview dispose mevcut
- `youtube_video_background.dart` — `Image.network` thumbnail (ağır oda; ayrı optimizasyon)

**Kalan risk:** Tam statik analiz için cihaz profili (DevTools memory) önerilir.

---

## 7. Crash raporlama

**Eklenen**
- `mobile/lib/core/crash/crash_reporting_bootstrap.dart`
- `mobile/lib/core/crash/sentry_bootstrap.dart`

**Değiştirilen**
- `mobile/lib/main.dart`, `mobile/pubspec.yaml` — `firebase_crashlytics`

**Kazanım:** `FlutterError.onError` + `PlatformDispatcher.onError` + Crashlytics; Sentry DSN hazır stub.

**Kalan risk:** `sentry_flutter` paketi bilinçli stub — `--dart-define=SENTRY_DSN=` ile genişletilebilir.

---

## 8. Offline cache

**Eklenen**
- `mobile/lib/core/offline/cache_first_loader.dart`

**Değiştirilen**
- `notifications_repository_impl.dart` — cache-first TTL

**Kazanım:** Bildirimler offline açılış; stale fallback 7 gün.

**Kalan risk:** Feed, mesajlar, profil repository’lerine aynı desen bir sonraki adımda genişletilmeli.

---

## 9. Image optimizasyonu

**Değiştirilen**
- `feed_post_card.dart`, `feed_story_strip.dart`, `native_feature_hub_page.dart` → `CachedNetworkImage`

**Kalan:** `pf_coffee_page.dart`, `youtube_video_background.dart` (YouTube thumb — bilinçli `Image.network`)

---

## 10. Hero animasyonları

**Eklenen**
- `mobile/lib/core/widgets/hero_tags.dart` — `HeroAvatar`, `HeroPostImage`

**Kullanım:** Feed gönderi görseli, story avatarları.

**Kalan risk:** Profil detay route’larında `Hero` hedef widget eşleşmesi tamamlanmalı.

---

## 11. Tablet / geniş ekran

**Değiştirilen**
- `app_bottom_nav_host.dart` — ≥720px `NavigationRail`, telefon `BottomNavigationBar`

**Kazanım:** Tablet UX web shell’e yaklaştı.

---

## 12. Performans denetimi

**Uygulanan**
- Presence SSE ile gereksiz 25 sn full list refresh kaldırıldı
- SSE provider ayrımı — daha dar rebuild alanı
- `ref.watch(voiceRoomsPresenceProvider)` shell’de tek bootstrap

**Önerilen sonraki adımlar:** `voice_room_rtc_page` `select` ile daraltma; discover hub `ListView` const widget’lar.

---

## Geriye dönük uyumluluk

Korunan sistemler: `!istek`, DJ, müzik kuyruğu, `ChatRoomSseService` event dispatch, TRTC/Agora, `FortuneIncomingInviteHost`.

---

## Özet metrikler

| Alan | Önce | Sonra |
|------|------|-------|
| Oda listesi yenileme | 25 sn HTTP poll | SSE presence (12 oda) |
| SSE reconnect max | 12 sn | 30 sn (kademeli) |
| Crash yakalama | Debug log only | Crashlytics + Sentry hazır |
| Görüntülü davet UI | Yalnızca fal sheet | Genel `IncomingVideoCallScreen` |
