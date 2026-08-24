# Canlifal — Sesli Sohbet Odaları Performans Analizi

**Tarih:** 2026-08-24  
**Kapsam:** `mobile/lib/features/voice_hub/`, `mobile/lib/features/trtc/`, ilgili gift/PK/SSE katmanları  
**Backend:** `https://canlifal.com` — mevcut API sözleşmesi değiştirilmedi  
**RTC:** Tencent TRTC (Agora yok)

---

## A. Odaya giriş akışı (gerçek kod sırası)

### A.1 Navigasyon (T0−)

| # | Adım | Dosya | Fonksiyon |
|---|------|-------|-----------|
| 1 | Oda tıklama | `voice_rooms_page.dart`, `navigate_to_voice_room.dart` | `openVoiceRoomWithVipGate` / `navigateToVoiceRoom` |
| 2 | Önceki oda temizliği | `voice_room_session_utils.dart` | `prepareVoiceRoomSwitch` → `leaveRoomSession`, gift/PK/audio stop |
| 3 | TRTC token ön-ısıtma | `voice_room_entry_perf.dart` | `prewarmOnRoomTap` → `POST /api/trtc/token` (audience, 3 dk cache) |
| 4 | AudioSession | `voice_room_music_audio_session.dart` | `ensureConfigured()` |
| 5 | Route | `app_router.dart` | `/voice-room/:id` → `buildVoiceRoomPage` |

`VOICE_ROOM_FULL=true` → `VoiceRoomRtcPage`; varsayılan → `VoiceRoomBasicPage`. İkisi de `voiceRoomLiveProvider(liveKey)` paylaşır.

### A.2 Provider oturumu (`voiceRoomLiveProvider.build` → microtask)

**Dosya:** `chat_room_providers_entry.dart` → `_beginRoomSession()`

| Sıra | İşlem | API / kaynak | Paralel? |
|------|--------|--------------|----------|
| 1 | Oturum kaydı, faz `joining` | — | — |
| 2 | Optimistic presence | — | — |
| 3 | **Presence join** | `POST /api/chat/rooms/{id}/presence` `{action:"join"}` | ∥ permissions |
| 4 | **İzinler** | `GET .../messages?limit=1` → `fetchMyPermissions` | ∥ presence |
| 5 | Oda kataloğu (kısa key) | `voiceRoomsProvider` | sıralı |
| 6 | **SSE başlat** | `GET /api/chat/rooms/{id}/stream` | async, bloklamaz |
| 7 | Poll timer | 8s (SSE yok) / 90–180s (SSE var) | — |
| 8 | **State + seats** | `GET .../state` ∥ `GET .../seats` | paralel |
| 9 | `backendSyncReady=true`, `roomTrtc` set | — | — |
| 10 | Mesajlar ∥ PK ∥ gift catalog | `GET messages`, `GET .../pk`, gift types | paralel |
| 11 | Bootstrap | `refresh(DJ)`, leaderboard, backgrounds | kısmen paralel |
| 12 | Faz `connected` | — | — |

**Heartbeat:** `PATCH/POST presence` `{action:"heartbeat"}` — **15s** timer; SSE son 45s içinde event geldiyse **atlanır** (`chat_room_providers_presence.dart`).

### A.3 Sayfa tarafı (RTC/Basic `initState` post-frame, provider ile paralel)

| Sıra | İşlem | API / SDK |
|------|--------|-----------|
| 1 | `ensureActiveSession()` | PiP dönüşü |
| 2 | Gift REST poll başlat | `GET .../gifts?since=` her **6s** (SSE aktif olunca durur) |
| 3 | `_joinAudioBackground()` | Auth bekle → `backendSyncReady` ≤1.5s → TRTC join |
| 4 | TRTC token | Cache / `state.roomTrtc` / `POST /api/trtc/token` |
| 5 | SDK join | `TrtcRoomManager.join(audioOnly: true)` |
| 6 | PK yeniden yükle | `GET .../pk` |

**Not:** Girişte `POST .../voice` (mikrofon API) **çağrılmaz** — `enableMic: false`.

### A.4 SSE `onConnected` yan etkileri

- Gift REST poll kapatılır
- Gerekirse presence re-join
- `GET .../seats` refresh

---

## B. Gereksiz / tekrarlayan API çağrıları

| Endpoint / iş | Tekrar nedeni | Öneri / durum |
|---------------|---------------|---------------|
| `GET state` + `GET seats` | Giriş + SSE seat_update + poll | SSE varken poll DJ dışı minimize (90–180s) ✓ |
| `GET .../pk` | `_preloadPkStatus` + `_connectPkBattle` | İkinci çağrı gereksiz olabilir — cache ile birleştirilebilir |
| `GET messages` | Poll (SSE yok, 8s) + SSE `onMessage` | SSE kopunca yedek — kabul edilebilir |
| `presence heartbeat` 15s | SSE aktifken skip (45s pencere) ✓ | — |
| Gift poll 6s | SSE yokken | SSE bağlanınca durur ✓ |
| `refresh(includeDj:true)` | Poll + SSE dj event | `_lastDjPlaybackSignature` ile dedup kısmen var |
| `GET /api/pk/me/invites` | Global 4s (PK listener) | SSE yedek — gerekli |
| TRTC token | Tap prewarm + join | Cache TTL 3 dk ✓ |

**Waterfall (iyileştirildi):** presence ∥ permissions; state ∥ seats; messages ∥ PK ∥ gifts.

---

## C. Gereksiz rebuild tespiti

### C.1 P0 — Tam ekran rebuild

**Dosya:** `voice_room_rtc_page.dart` (~1092–1094)

```dart
ref.watch(voiceRoomLiveProvider(_liveRoomKey).select(_RtcLiveShell.fromState));
```

`_RtcLiveShell` içinde `presence`, `dj`, `realtimeEvents` var. **Her presence/speaking güncellemesi** tüm `Scaffold` → `Stack` → `Column` ağacını yeniden build eder (~1900 satır subtree).

**Hedef:** Bu watch kaldırılmalı; alt bileşenler `room_fragment_providers.dart` slice'ları ile izole edilmeli.

### C.2 P0 — Sticky `isSpeaking`

**Dosyalar:** `chat_room_providers_presence.dart:268`, `presence_canonical.dart:47`

```dart
isSpeaking: p.isSpeaking || prev.isSpeaking,
```

Sunucu `false` gönderse bile bir kez `true` olduktan sonra **asla temizlenmiyor** → sürekli pulse animasyonu → CPU/GPU.

### C.3 P1 — Koltuk grid

`VoiceWebOwnerStageSeat` koltuk başına `select(VoiceSeatSnapshot.fromLive)` kullanıyor ✓ — ancak üst sayfa rebuild olunca tüm stage yeniden layout alıyor.

### C.4 P1 — Gift çift izleme

`voice_room_rtc_page.dart`: `GiftEngineOverlay` Consumer + `VoiceGiftHudOverlays` (feed + seat effects) — ikisi de `activeAnimation` izliyor.

### C.5 P2 — `ref.listen` tam state

`ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(...))` — her presence tick'te listener callback çalışır (exit/toast/music sheet). Select ile daraltılmalı.

### C.6 P2 — Chat `shrinkWrap: true`

`voice_web_chat_overlay.dart` — `embedded: true` iken `ListView.builder` shrinkWrap; 40 mesaj cap var ✓.

### C.7 P2 — BackdropFilter

`voice_room_bottom_action_bar.dart` — `sigma: 20` blur; Android'de GPU maliyeti yüksek.

### C.8 P2 — TRTC volume evaluation

`trtc_room_manager.dart` — `enableAudioVolumeEvaluation(300ms)` ama **handler yok**; speaking UI sunucu SSE'den geliyor → gereksiz CPU.

---

## D. Mimari hedef (widget ayrımı)

Mevcut kısmi altyapı: `room_fragment_providers.dart` (`voiceRoomChatSliceProvider`, `voiceRoomSeatSliceProvider`, …).

```
VoiceRoomRtcPage (ince kabuk)
├── VoiceRoomHeader          → select: room meta
├── VoiceRoomSeatStage       → select: speaking signature + seat slice
│    └── VoiceWebOwnerStageSeat (per-seat select) ✓
├── VoiceRoomChatPanel       → voiceRoomChatSliceProvider ✓
├── GiftEngineOverlay        → giftSessionProvider.select ✓
├── VoiceGiftHudOverlays     → feed + seat effects
├── VoiceRoomMusicDock       → music slice
├── PK strip / listener      → pk providers
└── VoiceRoomControls        → ui provider select ✓
```

---

## E. Tencent RTC lifecycle

| Aşama | Dosya | Not |
|-------|-------|-----|
| init | `voice_room_audio_coordinator.dart` | Singleton coordinator |
| join guard | `voice_room_rtc_page.dart` | `_audioJoinInFlight`, `_audioReady` |
| token | `voice_room_entry_perf.dart`, `trtc_remote_datasource.dart` | Prefetch + cache |
| join | `voice_trtc_engine.dart` → `TrtcRoomManager.join` | `audioOnly: true`, `voiceChatRoom` scene |
| leave | `chat_room_providers.dart` onDispose | SSE release, timers cancel |
| duplicate önleme | `_entryBegun`, `_presenceJoined`, `_voiceJoined` | ✓ |

**Risk:** `voiceRoomsProvider` listener ikinci kez `_joinAudioBackground` schedule edebilir (düşük olasılık race).

---

## F. Timer / polling envanteri

| Timer | Aralık | Dosya | Dispose |
|-------|--------|-------|---------|
| Room poll | 8–180s | `chat_room_providers.dart` | `_cancelSessionTimers` ✓ |
| Presence heartbeat | 15s | `chat_room_providers_presence.dart` | ✓ |
| Gift REST | 6s | `voice_room_gift_realtime_service.dart` | ✓ |
| PK global poll | 4s | `voice_pk_invite_listener.dart` | ✓ |
| Speak request | 5s | `voice_speak_request_listener.dart` | ✓ |
| Music PiP sync | 18s | `chat_room_providers.dart` | ✓ |
| Duyuru progress | **100ms** | `voice_room_persistent_duyuru.dart` | ⚠️ setState |
| Room song drift | 2s | `room_song_mini_player.dart` | ✓ |

---

## G. Memory leak riskleri

| Kaynak | Durum |
|--------|--------|
| `VoiceRoomLiveController` timers | `_cancelSessionTimers` on dispose ✓ |
| SSE hub refCount | `releaseVoiceRoom` ✓ |
| Gift poll | `stop()` on leave ✓ |
| TRTC listener | `registerListener` / leave ✓ |
| `ref.listen` in build | Riverpod auto-dispose on rebuild ✓ |
| AnimationController (seat pulse) | Sticky speaking → **süresiz animasyon** ✗ |

---

## H. Ölçüm (baseline — Cloud Agent ortamı)

| Metrik | Yöntem | Baseline (tahmini / kod analizi) |
|--------|--------|----------------------------------|
| Oda UI ilk frame | `VoiceRoomEntryPerf.entryBudget` = 1s | Optimistic presence anında; tam sync 1.5–4s (ağ) |
| API giriş sayısı | Kod sayımı | ~8–12 REST + 1 SSE + 0–1 TRTC token |
| RTC join | `_joinAudioBackground` | `backendSyncReady` gate ≤1.5s + SDK enter ≤20s |
| Rebuild (speaking tick) | Kod analizi | **Tüm RTC sayfası** (P0) |
| Memory 10 dk | Profil gerekli | Sticky speaking → animasyon birikimi riski |
| FPS | DevTools gerekli | Blur + pulse + cosmic background bileşik |

**Not:** Production cihazda Flutter DevTools Timeline + Memory şart. Bu rapor kod analizi + mevcut `PERFORMANCE_BASELINE.md` / `docs/PERFORMANCE_REPORT.md` ile hizalıdır.

---

## I. Yapılan optimizasyonlar (bu oturum)

| # | Problem | Dosya | Değişiklik |
|---|---------|-------|------------|
| 1 | Sticky speaking | `presence_canonical.dart`, `chat_room_providers_presence.dart` | `isSpeaking` sunucu değeri kullanılır |
| 2 | Tam sayfa rebuild | `voice_room_rtc_page.dart` | `_RtcLiveShell` dead watch kaldırıldı |
| 3 | Speaking izolasyonu | `room_fragment_providers.dart`, `voice_room_rtc_page.dart` | `voiceRoomSpeakingSignatureProvider` + `Consumer` stage |
| 4 | TRTC CPU | `trtc_room_manager.dart` | `audioOnly` modda volume evaluation kapalı |
| 5 | Android blur | `voice_room_bottom_action_bar.dart` | Android'de solid panel, iOS'ta blur |

---

## J. Test sonuçları

| Test | Beklenti | Sonuç |
|------|----------|-------|
| `flutter analyze` | 0 error | **Pass** (408 info/warning, 0 error) |
| `presence_canonical_test` | sticky speaking yok | **Pass** (8 test) |
| `flutter test test/features/voice_hub/` | pass | **115 pass** (`pk_invite_page` `unawaited` import düzeltildi) |
| Manuel TEST 1–9 | Kullanıcı cihazı | APK `1.0.354+392` ile doğrulanmalı |

### Ölçüm notu (Cloud Agent)

Bu oturumda fiziksel cihaz/DevTools ölçümü yapılamadı. Kod analizi ile beklenen etki:

| Metrik | Önce | Sonra (beklenen) |
|--------|------|------------------|
| Speaking tick → tam sayfa rebuild | Her SSE/poll tick | Yalnızca `_VoiceRoomRtcSeatStage` + ilgili `VoiceWebOwnerStageSeat` |
| Sticky pulse animasyon | Sürekli CPU | Sunucu `false` ile durur |
| TRTC volume eval (audioOnly) | 300ms SDK callback | Kapalı |
| Android alt bar blur | Her frame GPU | Solid panel |

Cihaz baseline için: `docs/PERFORMANCE_AFTER.md` protokolü + Flutter DevTools Timeline.

---

## K. Kalan işler (sonraki faz)

1. `ref.listen` → selective slices (exit, error, music search)
2. PK preload + connect tekilleştirme
3. `ChatRoomDjState` value equality veya dar shell
4. Duyuru 100ms timer → `AnimationController`
5. `VoiceRoomBasicPage` aynı rebuild izolasyonu
6. Seat layout cache provider
7. DevTools baseline cihazda ölçüm → `PERFORMANCE_AFTER.md` güncelle

---

*Bu dosya optimizasyon fazlarında güncellenir.*
