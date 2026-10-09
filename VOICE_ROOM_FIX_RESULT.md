# VOICE ROOM FIX RESULT — 1.0.746+799 (2026-10-09)

Dal: `claude/fortune-teller-bugs-features-1eie7a` · Backend değişikliği **yok** · Yeni paket **yok** · Leave zinciri **değişmedi**

## 1. Kök nedenler

| # | Kök neden | Kanıt |
|---|-----------|-------|
| RC1 | `POST /api/chat/rooms/{id}/voice` backend'de yalnız `type` okuyor (`join`/`leave`, aksi 400 "Invalid type"). Flutter `action`/değişken gövdeler deniyordu → leave **her zaman 400**, join 2 POST | canlifal `full-source` voice route; Flutter eski 3 varyantlı gövde döngüsü |
| RC2 | `voiceRoomSeatSliceProvider` dinleyicisi her presence/SSE tikinde koltuksuz kullanıcı için `setSelfMicPublishEnabled(false)` → koşulsuz `/voice` leave POST (400/403 spam) | `voice_room_rtc_page.dart` dinleyici; koordinatör `_setMicEnabledSafe(false)` |
| RC3 | `/voice` join için tek uçuş ve 403 hafızası yoktu; her mic denemesi yeniden POST | `voice_room_audio_coordinator.dart` join/mic yolları |
| RC4 | `GET /speak-requests` backend'de moderatör-only (`canModerateSpeakRequests`), Flutter herkes için giriş senkronu + 5 sn polling yapıyordu → 403 döngüsü | `chat_room_providers_seat.dart` `_syncSpeakRequestPending`, `voice_speak_request_listener.dart` |
| RC5 | `GET /state` `{success, data:{…}}` döndürüyor; Flutter zarfı açmıyordu → `participants` hep 0 → SSE presence'ı (1) eziyordu = salınım | `chat_room_remote_datasource.dart` `fetchRoomState`, `voice_room_state_snapshot.dart` |
| RC6 | CI `--obfuscate --split-debug-info` ile derliyor ama sembolleri saklamıyordu → `NoSuchMethodError: 'xHc<List<Mya>>' … 'OCh'` çözülemiyor | `.github/workflows/build-apk.yml` |
| RC7 | Async geri çağrılar dispose/rebuild anında `state` okuyunca Riverpod `StateError("Tried to read the state of an uninitialized provider")` | Riverpod 2.6 `Notifier.state` → `requireState` |

## 2. Uygulanan düzeltmeler

- `/voice` gövdesi `{type, action}` — tek istek (RC1).
- Koordinatör `_ensureVoiceSession`: koltuk/mic izni yoksa çağrı yok (`VOICE_JOIN_SKIPPED_NO_SEAT`), aynı oda için tek uçuş, 403 → `VOICE_BLOCKED_403 roomId=… endpoint=/voice` ve aynı oda için retry/timer yok; join sırasında leave/koltuk kaybı → açılan oturum kapatılır (RC3).
- `_leaveVoiceSessionIfJoined`: leave yalnız bu cihaz join ettiyse (RC2).
- RTC ve Basic sayfa koltuk/izin dinleyicileri kenar tetikli (`_lastSelfOnSeat`, `_lastSelfCanSpeak`) (RC2).
- `fetchSpeakRequests`: 403 → `SPEAK_REQUESTS_BLOCKED_403 roomId=…`, oda bloklanır, sonraki çağrılar ağsız `[]`; `_syncSpeakRequestPending` yalnız `canGiveVoice|canManageRoom|isGlobalAdmin|isRoomOwner` ve leave sürmüyorken (RC4).
- `/state` zarfı açılıyor; `me` yalnız `can*` anahtarı içeriyorsa yetki olarak okunuyor; SSE bağlı ve presence doluyken boş snapshot presence'ı ezmiyor (`PRESENCE_SNAPSHOT_EMPTY_IGNORED`) (RC5).
- CI: `canlifal-<sürüm>-symbols` artifact (30 gün) (RC6).
- `VoiceRoomLiveController.state` getter/setter koruması: StateError'da son bilinen durum; dispose sonrası yazım yok sayılır (`provider.state_uninitialized`, `provider.state_after_dispose`) (RC7).
- Leave sonrası: `clearAudioMicPublishGate` → `_mayPublishMic()==false` → `/voice` join yapılamaz; join sürerken `_leaveEpoch` değişirse oturum kapatılır; speak-request senkronu `_leaveInFlight` ile durur. Mevcut `_leaveEpoch`, `_reconnectSuspended`, `_leaveInFlight`, `_liveSessionGeneration` korumaları değiştirilmedi.

## 3. Değişen dosyalar (KANIT → ÇÖZÜM)

| Dosya | KANIT → LOG | ÇÖZÜM → KOD |
|-------|-------------|-------------|
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart` | `/voice` 400 "Invalid type"; `/speak-requests` 403 tekrarları; `/state` participants=0 | `voiceBody(type)`; `_speakRequestsBlockedKeys` + `SPEAK_REQUESTS_BLOCKED_403`; `fetchRoomState` `_unwrapMap` |
| `mobile/lib/features/voice_hub/presentation/audio/voice_room_audio_coordinator.dart` | Koltuksuz kullanıcıda `/voice` join/leave 403/400 tekrarları | `_ensureVoiceSession` (gate + tek uçuş + 403 blok), `_leaveVoiceSessionIfJoined`, `resetVoiceApiBlock` |
| `mobile/lib/features/voice_hub/presentation/voice_room_rtc_page.dart` | Her tikte mic=false → `/voice` leave | `_lastSelfOnSeat` kenar tetiği |
| `mobile/lib/features/voice_hub/presentation/basic/voice_room_basic_page.dart` | Aynı desen (selfCanSpeak) | `_lastSelfCanSpeak` kenar tetiği |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart` | "Tried to read the state of an uninitialized provider" | `state` getter/setter koruması; `joinVoiceSession` koltuk/leave kapısı |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_seat.dart` | Moderatör olmayan kullanıcıda speak-requests 403 | `_syncSpeakRequestPending` yetki + leave kapısı |
| `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_room_sync.dart` | state_snapshot 0 ↔ SSE 1 salınımı | `PRESENCE_SNAPSHOT_EMPTY_IGNORED` koruması |
| `mobile/lib/features/voice_hub/domain/entities/voice_room_state_snapshot.dart` | Zarf açılmıyor; katılımcı `me` yetki sanılabilir | Zarf açma + `can*` kontrolü |
| `mobile/lib/features/voice_hub/data/services/voice_room_debug_log.dart` | Yeni fazlar release'de görünmüyordu | `_alwaysLogPhases` += 4 faz |
| `.github/workflows/build-apk.yml` | Obfuscated stack trace çözülemiyor | Sembol artifact yükleme adımı |
| `mobile/test/features/voice_hub/voice_room_voice_gate_test.dart` | — | 7 yeni birim testi |

Loglarda token/JWT/secret/userSig/e-posta yok; yalnız `roomId` ve `endpoint`.

## 4. Testler

| Test | Sonuç |
|------|-------|
| `dart analyze lib` | 0 error; 435 info/warning — değişiklik öncesi temel çizgiyle aynı (yeni uyarı yok) |
| `flutter test test/features/voice_hub/voice_room_voice_gate_test.dart` | PASS 7/7 |
| `flutter test` (tam) | PASS — 2219 geçti, 2 atlandı, 0 hata |
| Yeni testler | `/voice` gövdesi tek istek · koltuksuz join yok · eşzamanlı join tek POST · 403 sonrası retry yok · leave yalnız join edilmişse · speak-requests 403 bloğu · `/state` zarf açma + `me` yetki sayılmaz |
| APK derleme | Bu ortamda yerel derleme yapılmadı → CI `build-apk.yml` (merge sonrası) |

## 5. Gerçek cihaz kabulü

Bu ortamda cihaz/emülatör yok. **Hiçbiri PASS değildir.**

| # | Senaryo | Durum |
|---|---------|-------|
| A | Koltuksuz kullanıcı odaya girer → `/voice` POST yok, yalnız dinleyici TRTC | BLOCKED |
| B | Koltuk al → izin → tek `/voice` join → publish | BLOCKED |
| C | Koltuktan in → publish stop → mic false → tek `/voice` leave | BLOCKED |
| D | Yetkisiz kullanıcı 403 → tek log, retry/polling yok | BLOCKED |
| E | Moderatör olmayan → speak-requests isteği yok / 403 sonrası durur | BLOCKED |
| F | Online sayısı SSE 1 ↔ snapshot 0 salınımı yok | BLOCKED |
| G | Oda→Ana sayfa leave zinciri tam (LEAVE_COMPLETE), sonra istek yok | BLOCKED |
| H | Oda→Oda geçişi aynı teardown, tek SSE | BLOCKED |
| I | "uninitialized provider" / `NoSuchMethodError` crash tekrar etmiyor | BLOCKED |

## 6. Kalan BLOCKED maddeler

- A–I gerçek cihaz testleri (kullanıcı).
- `NoSuchMethodError: Class 'xHc<List<Mya>>' has no instance getter 'OCh'` — statik olarak kaynak bulunamadı. Yeni CI derlemesinin `canlifal-<sürüm>-symbols` artifact'ı ile `flutter symbolize -i <stack.txt> -d <symbols>/app.android-arm64.symbols` çalıştırılıp çözülmüş trace gerekli.
- Referans verilen log dosyası ("Yapıştırılan metin(4).txt") konuşmaya eklenmedi; log bazlı doğrulama yapılamadı.
- Backend (öneri, zorunlu değil): `/voice` `action` alanını da kabul edebilir; `/state` `me` alanı yetki objesiyle karıştırılmamalı.
