# Sesli Sohbet Odası — Performans Kontrol Listesi

**Sürüm:** `1.0.354+392`  
**Tarih:** 2026-08-24  
**Detay rapor:** [`PERFORMANCE_VOICE_ROOM_ANALIZ.md`](PERFORMANCE_VOICE_ROOM_ANALIZ.md)

---

## Odaya giriş

- [x] `prepareVoiceRoomSwitch` — önceki odanın RTC/SSE/timer/gift/PK kaynakları temizlenir
- [x] Presence join ∥ permissions (paralel)
- [x] State ∥ seats (paralel)
- [x] TRTC token prewarm (oda tıklanınca, 3 dk cache)
- [x] Duplicate join guard: `_entryBegun`, `_presenceJoined`, `_audioJoinInFlight`, `_audioReady`
- [x] `backendSyncReady` gate ≤1.5s sonra RTC join

## Rebuild izolasyonu

- [x] `_RtcLiveShell` tam-sayfa watch kaldırıldı (`voice_room_rtc_page.dart`)
- [x] `_VoiceRoomRtcSeatStage` — speaking + seat slice ile izole stage
- [x] `VoiceWebOwnerStageSeat` — koltuk başına `VoiceSeatSnapshot` select
- [x] Chat / gift / banner — ayrı `Consumer` + `select`
- [ ] `VoiceRoomBasicPage` — aynı stage izolasyonu (sonraki faz)
- [ ] `ref.listen` tam `VoiceRoomLiveState` → selective slices (sonraki faz)

## Speaking / RTC

- [x] Sticky `isSpeaking` OR kaldırıldı (`presence_canonical`, `chat_room_providers_presence`)
- [x] `voiceRoomSpeakingSignatureProvider` — yalnızca konuşan id seti değişince stage rebuild
- [x] TRTC `enableAudioVolumeEvaluation` — `audioOnly` modda kapalı (handler yoktu)

## Polling / heartbeat

- [x] Heartbeat 15s — SSE son 45s event varsa atlanır
- [x] Room poll 8s (SSE yok) / 90–180s (SSE var)
- [x] Gift REST poll 6s — SSE bağlanınca durur
- [x] PK global poll 4s — SSE yedek
- [x] Timer dispose: `_cancelSessionTimers` on provider dispose

## UI / GPU

- [x] Android alt bar: solid panel (blur kapalı)
- [x] iOS alt bar: BackdropFilter blur korundu
- [ ] Duyuru ticker 100ms `setState` → `AnimationController` (sonraki faz)

## Memory / lifecycle

- [x] SSE hub refCount + `releaseVoiceRoom`
- [x] Gift poll `stop()` on leave
- [x] TRTC listener register/unregister on leave
- [x] `WidgetsBindingObserver` — foreground lifecycle provider

## Test (otomatik)

- [x] `flutter analyze` — 0 error
- [x] `presence_canonical_test` — sticky speaking regression
- [x] `flutter test test/features/voice_hub/` — 115+ pass (3 load fail önceden `pk_invite_page` import; düzeltildi)

## Kabul testi (cihaz — manuel)

| # | Senaryo | Beklenti | Durum |
|---|---------|----------|-------|
| 1 | Oda A giriş | UI <2s | APK ile doğrulanmalı |
| 2 | A + B aynı oda | Sayı eşit | APK ile doğrulanmalı |
| 3 | A leave | B'de hızlı kaybolma | APK ile doğrulanmalı |
| 4 | A→B geçiş | A state B'ye taşınmaz | APK ile doğrulanmalı |
| 5 | Speaking | Yalnızca ilgili koltuk pulse | Kod + cihaz |
| 6 | Gift | Anında, kasma yok | Cihaz |
| 7 | 20+ kullanıcı | Akıcı UI | Cihaz |
| 8 | 10 dk odada | Memory sabit | DevTools |
| 9 | 20× gir/çık | Timer/listener birikmez | DevTools |

## DevTools profil noktaları

1. **Timeline** — speaking SSE tick sırasında `VoiceRoomRtcPage.build` çağrı sayısı (hedef: düşük)
2. **Rebuild Stats** — `_VoiceRoomRtcSeatStage` vs parent
3. **Memory** — 10 dk odada `AnimationController` sayısı
4. **Network** — girişte REST sayısı (~8–12 + SSE)
5. **CPU** — Android blur kapalı sonrası raster thread

---

*Her performans PR'ında bu liste güncellenir.*
