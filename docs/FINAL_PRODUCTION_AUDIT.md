# Canlifal — Final Production Audit (Aşama 12)

**Sürüm:** 1.0.331+367  
**Dal:** `cursor/final-production-audit-5ac6`  
**Tarih:** 2026-08-21  
**Kapsam:** Performance · Memory · API · Real-time · Multi-device readiness

---

## EXECUTIVE SUMMARY

Canlifal Flutter istemcisi **1,569 Dart dosyası**, **112 ekran**, **121 go_router route** ile production ölçeğinde olgun bir codebase. Bu audit **yeni özellik eklemeden** stabilite, memory, API verimliliği ve real-time senkronunu denetledi.

**Sonuç:** Kritik TRTC çoklu-oturum riski (P0) ve logout SSE sızıntısı (P1) **bu dalda düzeltildi**. Tam release için **2-cihaz manuel acceptance** ve 1 pre-existing widget test fail kapatılmalı.

**RELEASE READY: NO** (manuel multi-device gate bekliyor)

---

## PROJECT INVENTORY

| Bileşen | Sayı |
|---------|-----:|
| Dart dosyaları (`lib/`) | 1,569 |
| Ekranlar (pages + screens) | 112 |
| Provider dosyaları | ~162 |
| Repository | 37 |
| Remote datasource | 51 |
| SSE servis sınıfları | 11 aktif |
| `Timer.periodic` dosyaları | 49 (65 kullanım) |
| `StreamSubscription` | 23 dosya |
| `VideoPlayerController` | 20 dosya |
| `AudioPlayer` / just_audio | 14 dosya |
| TRTC referansları | 41 dosya |
| Image cache (CanlifalNetworkImage) | 147 dosya |
| SharedPreferences | 26 · SecureStorage 2 · Hive 2 |
| Push (OneSignal + FCM) | 16 dosya |
| go_router routes | 121 + 1 shell |

---

## DUPLICATE SERVICE RAPORU

| Alan | Durum | Öneri |
|------|-------|-------|
| HTTP (Dio) | 7+ factory | P2 — SSE/psychic/upload ayrı; birleştirme sonraki sprint |
| Auth | AuthService + AuthRemoteDataSource overlap | P2 — repository birleştiriyor |
| Wallet | Profile + Extended datasource | P2 — bilinçli split |
| Image | CanlifalNetworkImage dominant | OK |
| SSE | `NotificationSseService` (presence) vs `NotificationsSseService` | P3 — isim karışıklığı |
| VoiceRoomsMockData production fallback | P1 — API boşsa mock oda gösterir |

Büyük refactor **yapılmadı** — yalnızca blocker fix.

---

## PERFORMANCE

### Startup
- Auth boot: `sessionUserCache` + `/api/me` — tek sefer
- Home: section'lar lazy (`LazyLoadPerf`, skeleton first)
- Shell prefetch: gift catalog arka planda — P2 overlap

### Scroll / FPS
- `RepaintBoundary`, `ListPerf`, horizontal lazy lists — mevcut
- Voice room: geniş state rebuild — gift event'te tüm oda P2 risk
- Shorts: `shorts_video_controller_pool` — max active controller stratejisi mevcut

### Cold start (Cloud VM, debug build proxy)
- Analyze + test: ~80s full suite
- Release APK: CI/local pipeline (signed release gerekli)

---

## MEMORY

### İyi uygulamalar
- Story viewer, chat page, DJ player — dispose OK
- SSE hub ref-count — room leave release

### Riskler
| ID | Seviye | Konu |
|----|--------|------|
| M1 | P2 | `video_cache_service` warm pool logout'ta explicit clear yok |
| M2 | P2 | Shorts 50+ swipe — cihazda RAM eğrisi doğrulanmalı |
| M3 | P1→fix | Logout SSE hub dispose **düzeltildi** |

---

## CPU / BATTERY

| Kaynak | Etki | Not |
|--------|------|-----|
| DM global poll 12s | Orta | Call-signal scan daraltıldı (açık sohbet / unread only) |
| Voice PK poll 4s + SSE | Orta | P2 — SSE varken poll kapatılabilir |
| Presence heartbeat 15s | Düşük | Backend interval korundu |
| Shorts video decode | Yüksek (30dk) | Cihaz testi gerekli |

---

## API

### Duplicate / gereksiz istek
- DM: 12 conv × messages poll → **4 unread veya 1 open** (fix)
- Chat açık: SSE + 15s poll fallback (bilinçli)
- Room refresh + presence recovery overlap — P2

### Widget build içinde API
- Doğrudan HTTP in `build()` **bulunamadı**
- Post-frame connect/listen pattern — notifications realtime P2

### Timeout / 401
- `LoadingTimeout`, refresh coordinator — sonsuz retry yok
- 401 → refresh → logout

---

## CACHE

| Olay | Invalidation |
|------|--------------|
| Login | `invalidateAuthenticatedShellData` |
| Logout | HTTP cache + API cache + **SSE dispose + providers** (fix) |
| Gift send | thread + wallet refresh |
| Message send | conversation + thread key clear |
| Room join/leave | SSE + presence + seat backend |
| Notification read | local prefs + list |

Wallet/room/seat: stale cache kullanılmıyor — canonical backend + SSE.

---

## AUTH

- JWT secure storage + refresh
- Logout: token clear + **teardownRealtimeOnLogout** (yeni)
- Multi-user: hidden conv, deleted msg, notification read prefs per-user clear

**Manuel test gerekli:** A logout → B login cache isolation (2 cihaz).

---

## SSE

- Hub ref-count: voice + video
- Room switch: `releaseVoiceRoom` → attach new
- Logout: `hub.dispose()` (fix)
- PiP return: `ensureActiveSession` duplicate attach guard (fix)

Event duplication: gift dispatch tek hub; PK SSE + poll P2.

---

## HEARTBEAT

- Presence 15s (`chat_room_providers_presence.dart`)
- Room join start, leave stop, logout hub dispose
- TRTC coordinator heartbeat cancel before restart — OK

---

## TENCENT RTC

### P0 (FIXED)
Birden fazla `TrtcRoomManager()` instance (`voice_trtc_engine`, `live_broadcast_room_page`, `dm_voice_call_page`, `trtcRoomManagerProvider`) aynı `TRTCCloud.sharedInstance()` üzerinde bağımsız `_inRoom` tutuyordu.

**Fix:** `TrtcRoomManager._activeSession` — yeni join önce eski manager'ı leave eder.

### Token
Backend `/api/trtc/token` — Flutter token üretmiyor ✓

---

## VOICE / LIVE / SEAT / GIFT / PK / MUSIC

| Alan | Real-time | Audit |
|------|-----------|-------|
| Voice room | SSE + presence | PiP SSE guard ✓ |
| Live | Video SSE + TRTC | Active session guard ✓ |
| Seat | Backend + SSE | Manuel 2-device |
| Gift | SSE + REST confirm | Canonical wallet refresh |
| PK | SSE + 4s poll | Poll overlap P2 |
| Music | SSE dj + player | Leave → stop ✓ |

---

## SOCIAL / SHORTS / FORTUNE / WALLET / PROFILE / DM / NOTIFICATIONS / GAMES

Tümü gerçek backend repository pattern — fake production UI **yok** (VoiceRoomsMockData fallback hariç P1).

---

## NAVIGATION

- go_router 121 route — broken route scan: bilinen typo yok
- AuthRedirect tek kaynak
- Back: shell + modal mevcut mimari

---

## MULTI DEVICE

Cloud agent **emülatör/cihaz çifti çalıştıramadı**. Senaryolar RELEASE_CHECKLIST'te listelendi — release öncesi **Device A + B zorunlu**.

---

## TEST RESULTS

| Suite | Sonuç |
|-------|-------|
| `dart analyze` | **PASS** (0 error) |
| `flutter test` | **907 pass, 1 fail, 2 skip** |
| Fail | `bana_ozel_hub_section_test` — layout overflow (pre-existing P2) |
| `flutter build apk --release` | Pipeline / local |

---

## RELEASE BLOCKERS

### P0 — RELEASE BLOCKER (fixed this branch)
1. ~~TRTC multi-manager same cloud instance~~ → `_activeSession` guard

### P1 — HIGH
1. ~~Logout SSE hub not disposed~~ → **fixed**
2. ~~PiP ensureActiveSession duplicate SSE attach~~ → **fixed**
3. **VoiceRoomsMockData** in production discover fallback — backend empty → mock rooms (document; remove fallback ayrı task)
4. **2-device acceptance** not executed in CI

### P2 — MEDIUM
1. DM chat SSE + 15s poll double traffic
2. PK invite 4s poll while SSE active
3. 7+ Dio factory inconsistency
4. `bana_ozel_hub_section_test` fail
5. Home discover 6 parallel room SSE

### P3 — LOW
1. SSE service naming confusion
2. Unused celebrity/blog endpoints in dart
3. Debug `debugPrint` in TRTC (kDebugMode gated)

---

## RECOMMENDATIONS

1. Merge audit branch → run **2-phone acceptance** script
2. Remove or gate `VoiceRoomsMockData` behind debug flag
3. Disable PK/DM polls when SSE connected
4. Unify TRTC through `trtcRoomManagerProvider` only (follow-up refactor)
5. Fix `bana_ozel_hub_section_test` overflow

---

## FAKE / HARDCODE DATA

Production `lib/` taraması: `testUser`, `dummy`, `fakeUser` **yok**.  
**VoiceRoomsMockData** — API fallback (P1).  
Jeton catalog fallback when API fails — documented offline resilience.

---

## BACKEND PROBLEMS

1. `/api/notifications/unread` intermittent 404
2. Privacy settings no REST sync
3. Room discover empty vs mock ambiguity

---

## CHANGED FILES (Aşama 12 fixes)

- `mobile/lib/core/bootstrap/user_session_cleanup.dart` (new)
- `mobile/lib/features/auth/presentation/providers/auth_providers.dart`
- `mobile/lib/features/trtc/presentation/trtc_room_manager.dart`
- `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers.dart`
- `mobile/lib/features/messages/presentation/widgets/dm_realtime_listener.dart`
- `mobile/lib/features/messages/data/hidden_conversations_store.dart`
- `mobile/lib/features/messages/data/deleted_messages_store.dart`
- `mobile/lib/features/notifications/data/repositories/notifications_repository_impl.dart`
- `docs/FINAL_PRODUCTION_AUDIT.md`
- `docs/FLUTTER_API_AUDIT.md`
- `docs/RELEASE_CHECKLIST.md`

---

## SONUÇ ÖZETİ

```
TOTAL TESTS:     910 (907 pass + 2 skip + 1 fail)
PASSED:          907
FAILED:          1
BLOCKERS:        4 (1 fixed P0, 2 fixed P1, 1 open P1 manual)
P0:              1 (fixed — TRTC)
P1:              4 (2 fixed, 2 open)
P2:              5
P3:              3
MEMORY LEAK:      Logout SSE (fixed); Shorts long-session (verify device)
PERFORMANCE:      DM poll reduced; PK poll overlap remains P2
API PROBLEM:      Duplicate poll patterns P2
REAL-TIME:        SSE logout + PiP guard fixed
BACKEND PROBLEM:  unread 404, privacy REST, mock room fallback
RELEASE READY:    NO
```
