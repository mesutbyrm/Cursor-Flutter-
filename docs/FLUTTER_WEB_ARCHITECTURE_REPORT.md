# Flutter Web Parite & Performans Raporu

**Sürüm:** 1.0.121+154  
**Tarih:** 2026-08-03  
**Referans:** canlifal.com web uygulaması + `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`

---

## Özet

Bu oturumda sesli oda yaşam döngüsü (TRTC/SSE/hediye) için P0 mimari düzeltmeler uygulandı. Backend değiştirilmedi; tüm değişiklikler mevcut API/SSE sözleşmesine uyumludur.

---

## 1. Web vs Flutter — API & Gerçek Zamanlı

| Alan | Web | Flutter (önce) | Flutter (sonra) |
|------|-----|----------------|-----------------|
| Oda SSE | Tek `GET /api/chat/rooms/{id}/stream` | `forceRelease` keşif SSE'sini öldürüyordu | `releaseVoiceRoom` ref-count |
| Gift Engine SSE | `gift_received`, `gift_queue_updated`, `gift_finished` | Eksik / legacy çift | `GiftEngineSseRouter` + `dispatchGiftSsePayloadRef` |
| Gift Socket.IO | Yedek | SSE ile çift teslimat | SSE aktifken socket kapatılır |
| Presence heartbeat | Arka plan timer | `build()` içinde timer | Oturum başında tek timer |
| TRTC exit | Senkron leave | `exitRoom()` fire-and-forget | `onExitRoom` completer, ≤500ms await |

---

## 2. Bulunan Sorunlar ve Çözümler

### P0 — TRTC yaşam döngüsü

**Sorun:** `TrtcRoomManager.leave()` `exitRoom()` çağırıp beklemeden devam ediyordu; hızlı oda değişiminde SDK "enter before exit" hatası ve bağlantı kopması.

**Çözüm:** `_exitRoomCompleter` + `onExitRoom` callback; `leave()` 500ms timeout ile tamamlanmayı bekler.

**Dosya:** `mobile/lib/features/trtc/presentation/trtc_room_manager.dart`

### P0 — SSE ref-count / keşif presence

**Sorun:** Oda çıkışında `forceReleaseVoiceRoom` tüm SSE'yi kesiyordu; `VoiceRoomsPresenceNotifier` ölü aboneliği yeniden açmıyordu ("internet kesilmiş gibi").

**Çözüm:** `releaseVoiceRoom` kullanımı; presence notifier `isLiveForRoom` kontrolü ile ölü bağlantıyı yeniden kurar.

**Dosyalar:** `chat_room_providers.dart`, `voice_rooms_presence_provider.dart`

### P0 — Gift çift teslimat

**Sorun:** SSE + Socket.IO + sayfa düzeyi `_giftSub` aynı hediyeyi 2–3 kez işliyordu (geç gelme, eksik kuyruk, kısa animasyon).

**Çözüm:**
- Gift Engine SSE router (motor olayları)
- SSE `onConnected` → gift socket disconnect
- `_startGiftSocket` SSE aktifken atlanır
- Tek dinleyici: `GiftEventListener` (combo/leaderboard/marquee merkezi)

**Dosyalar:** `gift_engine_sse_router.dart`, `gift_sse_dispatch.dart`, `gift_event_listener.dart`, `chat_room_providers_gift.dart`

### P0 — Join storm (gereksiz GET)

**Sorun:** `_loadBackendSnapshot`, `_parallelEntryLoad`, `_bootstrapRoomData` paralel çalışıyordu → duplicate state/messages/presence istekleri.

**Çözüm:** Sıralı bootstrap: presence → SSE → snapshot → messages/pk/catalog → bootstrap.

**Dosya:** `chat_room_providers.dart` — `_beginRoomSession`

### P1 — Presence snapshot flicker

**Sorun:** `_applyStateSnapshot` presence listesini doğrudan değiştiriyordu (koltuk/avatar kaybı).

**Çözüm:** `_mergePresenceStable(..., source: 'state_snapshot')`.

**Dosya:** `chat_room_providers_room_sync.dart`

### P1 — RTC duplicate listeners

**Sorun:** RTC sayfasında `_giftSub` + `GiftEventListener` çift hediye akışı.

**Çözüm:** Sayfa yalnızca poll başlatır; dinleme `GiftEventListener`'da. Leave/dispose TRTC+session await.

**Dosya:** `voice_room_rtc_page.dart`

### P1 — Heartbeat timer leak

**Sorun:** Heartbeat `build()` içinde her provider rebuild'de yeni timer riski.

**Çözüm:** `_beginRoomSession` başında tek timer; `_cancelSessionTimers` ile iptal.

---

## 3. Hediye Motoru (Queue)

- **FIFO kuyruk:** `GiftSessionController._enqueueAnimation` + `_pumpAnimationQueue`
- **Motor dedupe:** `giftHistoryId` / `queueItemId` ile legacy engelleme
- **Medya:** MP4/WebM/Lottie/PNG — mevcut `GiftEnginePreloader` + `CachedNetworkImage` disk cache
- **50 eşzamanlı hediye:** Kuyruk sıralı oynatma; feed/jeton anında, animasyon tek aktif

---

## 4. Bellek / CPU (kod incelemesi)

| Kaynak | Risk | Durum |
|--------|------|-------|
| AnimationController | Gift overlay | Mevcut dispose zinciri |
| Timer | Heartbeat, poll, SSE watchdog | Oturum scoped cancel |
| StreamSubscription | RTC duplicate | Kaldırıldı |
| EventSource/SSE | Hub ref-count | Düzeltildi |
| TRTC listener | leave sonrası | unRegister + null |

**DevTools profiling:** Fiziksel cihaz/emülatör gerekir — CI ortamında Flutter SDK yok; yerel doğrulama önerilir.

---

## 5. Doğrulama Durumu

| Test | Otomatik | Manuel |
|------|----------|--------|
| Voice join/leave/rejoin | Unit (SSE hub, gift router) | Cihaz gerekli |
| Gift Engine SSE | `gift_engine_sse_router_test` | Çoklu cihaz |
| SSE reconnect | `sse_connection_hub_test` | 3G simülasyon |
| TRTC exit await | Kod review | Hızlı oda geçişi |
| 100 hediye FPS | — | Stress test |
| JWT refresh | Mevcut auth testleri | 401 senaryosu |
| Image/video cache | Preloader mevcut | Network tab |

---

## 6. Kalan İşler (P2)

1. `voice_room_basic_page.dart` / `voice_pk_battle_page.dart` — duplicate `_giftSub` kaldırma (RTC ile aynı pattern)
2. `VideoStreamSseService` → tam `BaseSseService` JWT refresh hizalaması
3. Büyük JSON için isolate parse (presence snapshot >64KB)
4. `flutter test` + DevTools timeline cihazda
5. `basic_page` gift listener → yalnızca `GiftEventListener`

---

## 7. Değişen Dosyalar (1.0.121+154)

- `trtc_room_manager.dart` — exit await
- `chat_room_providers.dart` — bootstrap, heartbeat, SSE/socket
- `chat_room_providers_room_sync.dart` — presence merge
- `chat_room_providers_gift.dart` — socket gate
- `voice_rooms_presence_provider.dart` — SSE reconnect
- `voice_room_rtc_page.dart` — duplicate listener, await leave
- `gift_event_listener.dart` — merkezi combo/leaderboard/marquee
- `gift_engine_sse_router.dart`, `gift_sse_dispatch.dart` (cherry-pick #299)

## 8. Oturum 1.0.123+156 — Oda çıkışı + hediye süresi

### Odadan çıkış (P0)
- `leaveRoomSession(awaitBackend: false)` — TRTC/SSE/state anında; backend arka planda
- RTC/basic sayfa: pop önce, özet sheet kaldırıldı (anında çıkış)
- `ensureActiveSession()` — PiP müzik sonrası tekrar girişte eski presence yok

### Hediye süresi (P0)
- Backend `engineDurationMs` birebir kullanılır (12s zorlama kaldırıldı)
- Video: `max(backendDuration, videoLength)` — erken kapanmaz
- SFX: fade-in ile video senkron başlar

---

*Backend dokunulmadı. API: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`*
