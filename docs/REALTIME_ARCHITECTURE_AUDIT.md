# Realtime / Backend Parity — Mimari Denetim (FAZ 1)

**Tarih:** 2026-10-05 (UTC)  
**Dal hedefi:** `flutter-realtime-parity-fix`  
**Production SoT:** `https://canlifal.com` · `/api` · JWT Bearer · TRTC SDK App ID `20040423` · SSE öncelikli  
**Backend referans:** `backend-docs/` (OpenAPI, `CANLIFAL_REALTIME_SISTEMLER_DOKUMANTASYONU.md`, `full-source` ile uyumlu uç listesi)

> **FAZ 1 kapsamı:** Yalnızca analiz — üretim davranışını değiştiren kod yok. Sonraki fazlar bu belgedeki P0→P2 sırasını takip eder.

---

## 1. Özet (executive)

| Alan | Durum | Not |
|------|--------|-----|
| Auth + `/api` (v1 rewrite kapalı) | 🟢 | `ApiConfig.useApiV1` varsayılan `false` |
| Sesli oda **join** | 🔴 | Üretim: `POST /api/live/join-room`; Flutter: `GET /state` + `POST .../presence` waterfall |
| Sesli oda **heartbeat** | 🔴 | Üretim: `POST /api/live/heartbeat`; Flutter: chat presence heartbeat ~15 sn |
| Sesli oda **leave** | 🟡 | `RoomLeaveCoordinator` + `leaveRoomSession` iyi; backend `leave-room` yerine çoğunlukla `presence leave` |
| SSE hub (oda başına 1 lease) | 🟢 | `SseConnectionHub` refCount |
| Canonical state hedefi | 🟡 | `voiceRoomLiveProvider` geniş monolith; `RoomSessionManager` paralel canonical kopya |
| Gift jeton otoritesi | 🟡 | `LiveFieldApiRemoteDataSource.gifts.sendGift` → `/api/live/gift/send` öncelikli; eski chat uçları yedek |
| PK timer / skor | 🟡 | `pk_battle_provider`, `pk_room_controller` backend `endsAt` kullanıyor; çift timer riski |
| Discover SSE | 🟢 | `maxTrackedRooms = 6` (kullanıcı spec’inde 12 değil) |
| Stale room event | 🟡 | `voiceRoomActiveLiveKeyProvider`, alias set, `_sseReleaseKey`; tam `event.roomId == current` audit gerekli |
| Test 1–20 (spec) | 🔴 | Parity lifecycle regression paketi yok; parça testler var |

**Hedef mimari (kullanıcı spec):**

```
SERVER STATE → voiceRoomLiveProvider (controller) → UI
enter: attachVoiceRoom → 1 SSE → handlers → state
leave: single leave → leave-room → TRTC → SSE release → timers stop
```

---

## 2. Canonical backend contract (üretim)

Kaynak: `backend-docs/openapi.json`, `CANLIFAL_REALTIME_SISTEMLER_DOKUMANTASYONU.md`.

| İş | Method + path | Flutter durumu |
|----|----------------|----------------|
| Odaya katıl (birleşik) | `POST /api/live/join-room` `{ roomId, roomType, nickname, password? }` | 🟡 Model + datasource var (`LiveJoinRoomResult`, `LiveRoomRemoteDataSource`); **sesli oda girişi kullanmıyor** |
| Odadan çık | `POST /api/live/leave-room` | 🟡 Datasource var; voice hub **presence leave** ağırlıklı |
| Heartbeat | `POST /api/live/heartbeat` | 🔴 Voice hub **kullanmıyor** (chat presence interval) |
| Koltuk | `GET/POST /api/live/seats` | 🟡 `LiveFieldApiRemoteDataSource` + `GET /api/chat/rooms/{id}/seats` |
| Hediye türleri | `GET /api/live/gift-types` | 🟢 Field API + gift repo fallback |
| Hediye gönder | `POST /api/live/gift/send` | 🟢 `ChatRoomGiftsRemoteDataSource` önce field API |
| PK | `GET/POST /api/live/pk` | 🟡 `pk_battle_remote_datasource` çoklu yedek path |
| TRTC token | `POST /api/trtc/token` | 🟢 `VoiceTrtcEngine`; join-room `trtc` blob’u state snapshot’tan |
| Voice SSE | `GET /api/chat/rooms/{roomId}/stream` | 🟢 `ChatRoomSseService` |
| Live SSE | `GET /api/video-streams/{streamId}/stream` | 🟢 `VideoStreamSseService` |

**Not (backend doküman):** Sesli odada `user_joined` / `user_left` hâlâ `POST/DELETE .../presence` ile tetiklenir; **join-room** bileşik snapshot + TRTC + koltuk/ranking için önerilen giriş. Flutter’ın yalnızca presence kullanması işlevsel kalabilir ancak **waterfall**, **heartbeat sözleşmesi** ve **tek jeton/gift otoritesi** ile çelişki yaratır.

---

## 3. Mevcut Flutter mimarisi (sesli oda)

### 3.1 Veri akışı (bugün)

```
UI (voice_room_rtc_page, widgets)
  ↓ read/watch
voiceRoomLiveProvider(roomKey)  ← NotifierProvider.autoDispose.family
  ↓ VoiceRoomLiveController (~4k satır + part extensions)
  ├─ entry: _beginRoomSession()
  │     _leaveStalePreviousRoom() → registerVoiceRoomLiveSession
  │     _fetchAndApplyRoomState()     [GET /chat/rooms/{id}/state]
  │     _joinPresence()               [POST .../presence action:join]
  │     _startSse()                   [SseConnectionHub.attachVoiceRoom]
  │     _loadInitialMessages, _preloadPkStatus, _preloadGiftCatalog
  │     _fetchAndApplySeats()         [GET .../seats]
  │     _bootstrapRoomData()
  ├─ presence: _startPresenceHeartbeat() [15s Timer → presence heartbeat API]
  ├─ poll: _schedulePoll() [8s, yalnızca SSE kapalıyken]
  ├─ RoomSessionManager (delegateLifecycleToHost: true) — canonical kopya + events
  ├─ voiceRoomAudioCoordinator → VoiceTrtcEngine → POST /api/trtc/token
  └─ leave: leaveRoomSession() → RoomLeaveCoordinator steps
```

**Waterfall:** state → presence ∥ permissions → SSE → messages/PK/gifts → seats → bootstrap.  
**Spec hedefi:** `join-room` → (paralel) TRTC + SSE → UI; fallback yalnızca eksik alanlar.

### 3.2 Oda anahtarı (room id)

- `_presenceApiKey`, `_roomKey`, `_roomKeyAliases`, `apiRoomKey`, slug, `trtcRoomId` — kısmen merkezi (`registerVoiceRoomLiveSession` alias set).
- Risk: SSE release / gift routing farklı alias ile (`leaveRoomSession` içinde `_sseReleaseKey` düzeltmesi yapılmış).
- **Öneri (P0):** `VoiceRoomSessionKey` tipi — canonical `room.id` + `aliases` readonly; tüm provider family key’leri canonical id.

### 3.3 Session registry

`voice_room_session_registry.dart` — 🟢 KEEP (lifecycle only): active key, alias set, gift cache temizliği; **oda state tutmuyor**.

### 3.4 SSE

| Bileşen | Rol | Sınıf |
|---------|-----|--------|
| `SseConnectionHub` | Oda başına tek `ChatRoomSseService`, refCount | 🟢 KEEP |
| `chat_room_providers_sse.dart` | attach/release, event → controller | 🟡 MERGE (handler’ları tek dispatch) |
| `voice_rooms_presence_provider.dart` | Discover: max 6 SSE | 🟢 KEEP (limit var) |
| `voice_room_gift_realtime_service.dart` | Socket tercih + REST poll fallback | 🟡 MERGE (SSE primary netleştir) |

Duplicate SSE riski: discover SSE + aktif oda SSE **aynı hub lease** — refCount doğru kullanılırsa OK; discover disconnect room leave ile yarış audit (P2).

### 3.5 Presence / heartbeat

| Kaynak | Aralık | Koşul |
|--------|--------|--------|
| `_presenceHeartbeat` | 15 sn | `ChatRoomRemoteDataSource.presenceHeartbeatInterval` |
| `RoomSessionManager._heartbeatTimer` | host delegate true iken **kapalı** | 🟢 |
| `TrtcLiveRoomCoordinator` | 10 sn | **canlı yayın** (`/api/live/*`), sesli oda değil |
| `_schedulePoll` | 8 sn | SSE **kapalı** |

**Mismatch:** Spec `POST /api/live/heartbeat` — voice hub’da **hiç çağrılmıyor**.

### 3.6 Leave flow

`leaveRoomSession` — 🟢 güçlü taraflar:

- `_leaveInFlight` + `RoomLeaveCoordinator.isLeaving`
- Timer iptali `_cancelSessionTimers`
- SSE key yakalama (`sseReleaseKey`)
- TRTC `voiceRoomAudioCoordinator.leave()`
- Optimistic presence + backend leave

**Gap (P0):** Backend adımı `_leavePresenceWithSeatClear` (chat presence) — `LiveRoomRemoteDataSource.leaveRoom(roomType: voice)` ile **birleştirilmeli** (idempotent, timeout + local cleanup spec ile uyumlu).

### 3.7 TRTC

- 🟢 Tencent only; `VoiceTrtcEngine` → `/api/trtc/token`
- `roomTrtc` state snapshot / join-room modelinden gelebilir; şu an **state fetch** sonrası set
- Agora: yalnızca yorum/deprecated typedef — 🟢 yeni kullanım yok
- LiveKit: yorum (audio session) — runtime yok

### 3.8 Seats

- Canonical UI state: `VoiceRoomLiveState.seatSlots` + presence seat index sync
- REST: chat seats + live field seats API
- SSE: `room_event` / seat handlers (`chat_room_providers_room_sync.dart`)
- Risk: REST fetch + SSE aynı değişikliği iki kez uygulayabilir — `shouldApplyCanonicalSeats` var; genişletilmeli (event id dedupe)

### 3.9 Gifts

- Send: `LiveFieldApiRemoteDataSource.gifts.sendGift` → `/api/live/gift/send` 🟢
- Fallback: chat room gift POST 🟡
- Lucky gift ayrı path 🟢
- **Bug sınıfı (🔴 FIX):** UI’da “0 jeton” — `_mapSendResponse` / SSE gift parse / optimistic UI; P1’de response `amount`, `quantity`, `newBalance` zorunlu alan audit

### 3.10 PK (sesli oda)

- State: `pkBattleRemoteProvider`, `pk_battle_provider`, `pk_room_controller`
- Timer: `PkEndsAtCountdown`, `_endsAtSync` — backend `endsAt` 🟢 yönde
- Risk: `_tick` + `_endsAtSync` çift 1 sn timer 🟡 MERGE
- PK REST poll: `pk_battle_remote_provider` SSE bağlıyken seyreltme — 🟢

### 3.11 Canlı yayın (ayrı hat)

- `TrtcLiveRoomCoordinator` — join-room + live heartbeat 🟢 (video/stream)
- `VideoStreamSseService` — SSE 🟢
- PK video: `live_video_pk_provider` — son birleşmede `livePkBattleFinished` 🟢

---

## 4. Duplicate / paralel sistemler

| Sistem A | Sistem B | Sorun | Öneri |
|----------|----------|--------|--------|
| `VoiceRoomLiveController` state | `RoomSessionManager` canonical presence/seats | İki kaynak | 🟡 MERGE: Manager yalnızca lock/idempotency veya tamamen ince facade |
| Chat `presence join` | `POST /api/live/join-room` | Waterfall vs bileşik | 🔴 FIX P0: join-room primary |
| Presence heartbeat 15s | `live/heartbeat` | Contract | 🔴 FIX P0 |
| SSE presence | 8s poll refresh | Gereksiz yük SSE açıkken kapalı 🟢 | KEEP |
| `voice_rooms_presence_provider` SSE | Aktif oda SSE | refCount | 🟡 audit leave/disconnect |
| Gift Socket.IO preference | SSE gift events | Çift event | 🟡 dedupe + SSE primary |
| `pk_battle_provider` timers | `pk_room_controller` ticker | Çift timer | 🟡 MERGE P1 |
| Fragment providers (`room_fragment_providers.dart`) | Monolith state | Parçalı rebuild | 🟢 KEEP (perf) — tek writer kuralı |

---

## 5. Race condition & stale session

| Senaryo | Mevcut koruma | Boşluk |
|---------|---------------|--------|
| Room A → leave → Room B | `_leaveStalePreviousRoom`, `voiceRoomActiveLiveKeyProvider` | Async leave vs join sırası — kısmen |
| Room A SSE → Room B state | Alias + active key; handler’larda tutarlı `roomId` filtresi **garanti değil** | 🔴 P0: her SSE/REST callback’te `assertEventRoomMatchesSession` |
| Eski HTTP yanıtı yeni odayı ezer | `_sessionActive`, `_entryBegun` | `_fetchAndApplyRoomState` generation token yok | 🟡 P0 |
| Dispose sonrası ref | try/catch clearVoiceRoomLiveSession | 🟢 |

Dosyalar: `voice_room_stale_session_guard.dart` (auth açılış temizliği), `voice_room_route_presence_guard.dart`, `voice_room_session_lifecycle_host.dart`.

---

## 6. Memory leak riskleri (audit checklist)

| Kaynak | Dosya / pattern | Dispose |
|--------|------------------|---------|
| `StreamSubscription` | SSE, connectivity, gift realtime | `_cancelSessionTimers`, hub release — 🟡 audit tüm part’lar |
| `Timer.periodic` | presence, poll, PK, speak queue poll | leave’de iptal 🟢; widget listener’lar 🟡 |
| `ref.keepAlive()` | `_roomKeepAliveLink` | leave’de release 🟡 doğrula |
| TRTC callbacks | `VoiceTrtcEngine`, coordinator | leave 🟢 |
| Discover `_subs` | `voice_rooms_presence_provider` | `_disposeAll` onDispose 🟢 |

---

## 7. Static audit özeti (2026-10-05)

Komut: `rg` over `mobile/lib/**/*.dart`

| Aranan | Bulgu |
|--------|--------|
| `/api/v1` | Dio interceptor + `api_path_v1.dart`; **production default kapalı** (`USE_API_V1=false`). Invidious harici URL’de `/api/v1/videos` |
| `Agora` | ~10 eşleşme — çoğu yorum/deprecated/LiveKit session yorumu |
| `LiveKit` | Yorum düzeyi (ses oturumu) |
| `Socket.IO` | Gift realtime servis yorumu + `setSocketPreferred` |
| `Timer.periodic` | 60+ dosya — voice hub: presence 15s, poll 8s, PK 1s, speak/pk invite poll 4–6s, ranking refresh host |
| `join-room` | TRTC live coordinator + field API; **voice entry yok** |
| `leave-room` | `LiveRoomRemoteDataSource`; voice leave ağırlıkla presence |
| `voiceRoomLiveProvider` | 100+ UI/provider referans — **canonical hedef doğru** |
| `SseConnectionHub` | Hub + testler |
| `EventSource` | `BaseSseService` altında |

---

## 8. Dosya sınıflandırması (özet tablo)

### 8.1 Core network / SSE

| Dosya | Sınıf | Gerekçe |
|-------|--------|---------|
| `core/network/sse/sse_connection_hub.dart` | 🟢 KEEP | Tek SSE lease |
| `core/network/sse/sse_hub_provider.dart` | 🟢 KEEP | Riverpod DI |
| `core/network/sse/sse_hub_lifecycle.dart` | 🟢 KEEP | App lifecycle |
| `core/config/api_config.dart` | 🟢 KEEP | `/api` default |
| `core/network/interceptors/api_version_interceptor.dart` | 🟡 MERGE | v1 rewrite net dokümante |

### 8.2 Voice hub — state & lifecycle

| Dosya | Sınıf | Gerekçe |
|-------|--------|---------|
| `presentation/providers/chat_room_providers.dart` | 🟡 MERGE | Canonical controller; join/leave refactor P0 |
| `chat_room_providers_entry.dart` | 🔴 FIX | join-room’a geçiş |
| `chat_room_providers_presence.dart` | 🔴 FIX | live heartbeat + tek timer |
| `chat_room_providers_sse.dart` | 🟡 MERGE | room guard + dedupe |
| `chat_room_providers_room_sync.dart` | 🟡 MERGE | join-room snapshot apply |
| `voice_room_session_registry.dart` | 🟢 KEEP | lifecycle-only registry |
| `coordinators/room_leave_coordinator.dart` | 🟢 KEEP | idempotent leave |
| `coordinators/room_session_manager.dart` | 🟡 MERGE | duplicate canonical |
| `utils/voice_room_leave_flow.dart` | 🟢 KEEP | UI leave entry |
| `utils/voice_room_stale_session_guard.dart` | 🟢 KEEP | cold start cleanup |
| `widgets/voice_room/voice_room_route_presence_guard.dart` | 🟡 MERGE | route vs controller leave |
| `presentation/voice_room_rtc_page.dart` | 🟢 KEEP | ana shell |

### 8.3 Data / API

| Dosya | Sınıf | Gerekçe |
|-------|--------|---------|
| `data/datasources/chat_room_remote_datasource.dart` | 🟡 MERGE | presence; join-room delegate ekle |
| `trtc/data/datasources/live_room_remote_datasource.dart` | 🟢 KEEP | join/leave/heartbeat contract |
| `live/data/datasources/live_field/*` | 🟢 KEEP | `/api/live/*` parity |
| `data/datasources/chat_room_gifts_remote_datasource.dart` | 🟡 MERGE | gift response mapping FIX |
| `data/services/chat_room_sse_service.dart` | 🟢 KEEP | SSE transport |
| `data/services/voice_room_gift_realtime_service.dart` | 🟡 MERGE | poll/socket vs SSE |

### 8.4 PK / gifts / discover

| Dosya | Sınıf | Gerekçe |
|-------|--------|---------|
| `providers/pk_battle_provider.dart` | 🔴 FIX | timer merge, authoritative score |
| `providers/pk_battle_remote_provider.dart` | 🟡 MERGE | poll vs SSE |
| `pk_room/pk_room_controller.dart` | 🟢 KEEP | endsAt ticker pattern |
| `providers/voice_rooms_presence_provider.dart` | 🟢 KEEP | discover SSE cap 6 |
| `presentation/pages/voice_pk_battle_page.dart` | 🟡 MERGE | chat alanı spec |

### 8.5 Live (video)

| Dosya | Sınıf | Gerekçe |
|-------|--------|---------|
| `trtc/presentation/trtc_live_room_coordinator.dart` | 🟢 KEEP | join-room reference impl |
| `live/data/services/video_stream_sse_service.dart` | 🟢 KEEP | live SSE |

### 8.6 Eklenecek (➕ ADD)

| Öğe | Faz |
|-----|-----|
| `VoiceRoomSessionKey` + event room guard | P0 |
| `join-room` bootstrap use-case (voice) | P0 |
| Unified `VoiceRoomLeavePipeline` (live leave-room + presence) | P0 |
| Lifecycle regression tests (spec 1–20) | P5 |
| `docs/REALTIME_FIX_FINAL_REPORT.md` | Faz 6 |

### 8.7 Silme adayları (🗑️ DELETE — **FAZ 6 only**)

Henüz **silme yok**. Adaylar kullanım zinciri doğrulandıktan sonra:

- Kullanılmayan duplicate poll listener’lar (SSE always-on modda)
- Deprecated Agora typedef-only dosyalar (zaten minimal)
- Ölü Socket path (SSE kanıtlandıktan sonra)

---

## 9. Önerilen uygulama fazları

### PHASE 2 — P0

1. **Auth:** Mevcut refresh coordinator — single-flight doğrula (`auth_token_refresh_coordinator.dart`).
2. **join-room:** `_beginRoomSession` → `LiveRoomRemoteDataSource.joinRoom(roomType: voice)`; response → state (participants, seats, trtc, giftRanking, pkStatus); presence/join yalnızca backend gerektiriyorsa.
3. **leave-room:** `leaveRoomSession` adımına `liveLeaveRoom` ekle (presence ile idempotent).
4. **heartbeat:** Tek timer → `POST /api/live/heartbeat`; presence heartbeat kaldır veya birleştir (backend doc ile doğrula).
5. **TRTC:** `roomTrtc` join-room’dan; ayrı token fetch yalnız fallback.
6. **SSE:** attach/release değişmez; handler’larda `roomId` guard.
7. **Stale session:** request generation + event filter.

### PHASE 3 — P1

Seats REST/SSE dedupe; gift send/parse; PK timer birleştirme; PK team UI.

### PHASE 4 — P2

Music/DJ; discover SSE prioritization; performance (paralel join-room + SSE + TRTC).

### PHASE 5 — Test

| # | Spec | Mevcut |
|---|------|--------|
| 1 | JWT login | 🟢 auth tests |
| 2 | join-room | 🟡 parse test (`trtc_live_room_test`) — voice integration yok |
| 3–6 | join payload alanları | 🔴 eklenecek |
| 7–10 | SSE events | 🟡 `sse_client_test`, hub test — room integration yok |
| 11 | gift jeton | 🔴 |
| 12–13 | PK | 🟡 `pk_battle_ends_at_sync_test`, `live_pk_battle_finished_test` |
| 14–17 | leave pipeline | 🔴 |
| 18–20 | cross-room / resume | 🔴 |

### PHASE 6

Deprecated duplicate cleanup + `REALTIME_FIX_FINAL_REPORT.md`.

---

## 10. Git / dal

- Çalışma dalı: **`flutter-realtime-parity-fix`** (FAZ 1: yalnızca bu belge).
- Commit önerisi: `docs: REALTIME architecture audit (phase 1)`.
- Sonraki commit’ler kullanıcı spec §29 örnek mesajlarına uygun **mantıksal parçalar**.

---

## 11. Backend’den hâlâ beklenenler (Flutter tarafı doğrulama)

- `join-room` voice yanıtında **her zaman** dolu `trtc`, `seats`, `participants` mı? (Eksik alan fallback stratejisi.)
- Heartbeat yanıtında koltuk/presence güncellemesi var mı?
- Gift SSE payload’ında `totalJeton` / `amount` alan adları sabit mi?
- PK: `startAt`, `endAt`, `serverTime` skew header veya body?

Canlı probe / OpenAPI diff: `scripts/backend-route-parity.py`, `docs/BACKEND_FLUTTER_PARITY_AUDIT.md`.

---

## 12. Referanslar (repo içi)

- `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` §5–6 SSE, §9 ChatRoom
- `backend-docs/abacus-current/priority2/CANLIFAL_REALTIME_SISTEMLER_DOKUMANTASYONU.md`
- `mobile/lib/features/voice_hub/presentation/providers/chat_room_providers_entry.dart` — mevcut giriş sırası
- `mobile/lib/features/trtc/data/datasources/live_room_remote_datasource.dart` — join/leave/heartbeat
- `mobile/test/core/network/api_version_contract_test.dart` — `/api/v1` rewrite guard

---

_Bu belge FAZ 1 çıktısıdır; kod değişikliği FAZ 2+ ile başlar._
