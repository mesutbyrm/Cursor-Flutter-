# CanliFal Flutter — `mobile/lib/` Audit

**Date:** 2026-08-04  
**Scope:** `/workspace/mobile/lib/` (1,441 Dart source files excl. `.freezed.dart` / `.g.dart`; ~236k LOC)  
**App version:** `1.0.125+159` (`mobile/pubspec.yaml`)  
**Integration reference:** [`docs/FLUTTER_ENTegrasyon_KILAVUZU.md`](FLUTTER_ENTegrasyon_KILAVUZU.md) (27 Jun 2026)  
**Production target:** `https://canlifal.com` (~384 API, 149 Prisma models)

> **Durum:** Bu rapor tamamlanmadan kod yazımı durduruldu. APK derlenmedi. Bkz. [`RELEASE_REPORT.md`](RELEASE_REPORT.md).

---

## Master checklist (zorunlu denetim özeti)

| Kategori | Durum | Özet |
|----------|-------|------|
| ✔ **Mevcut özellikler** | 🟢 Geniş | 35 feature modülü; voice, live, fortune, gifts, social, auth, shorts, psychics, wallet |
| ✔ **Eksik özellikler** | 🟡 Orta | SongQueue tam IFrame geçişi kısmi; 5 guide endpoint sabiti yok; Agora temizliği; LiveKit kaldırılmadı |
| ✔ **Bozuk özellikler** | 🟡 Az | `fortuneTellerIncomingSessions` (prod 405 riski); çift müzik yolu (just_audio + IFrame); `socialPublicStats` deprecated |
| ✔ **Bağlanmamış API** | 🟡 | `/api/broadcast-images`, `/api/football`, `/api/online-fal`, `/api/translations`, `/api/user/likers` |
| ✔ **Kullanılmayan widget** | 🟡 | `lib/services/*`, Agora modülü, LiveKit, deprecated feed UI |
| ✔ **Ölü kod** | 🟡 | 9 dosya `lib/services/`; `voice_agora_engine.dart`; `Env.preferLiveKit` okunmuyor |
| ✔ **Tekrarlayan kod** | 🔴 | `chat_room_providers` monolith; çift PK sayfaları; çift gift provider |
| ✔ **Yavaş ekranlar** | 🔴 | `voice_room_rtc_page`, `live_broadcast_room_page`, `voice_discover_hub_2026` |
| ✔ **Bellek sızıntısı riski** | 🟡 | 12 paralel SSE discover; video controller lifecycle; gift timer maps |
| ✔ **FPS sorunları** | 🟡 | Hediye prefetch (düzeltildi); geniş `ref.watch`; premium_2026 ağaçları |
| ✔ **CPU sorunları** | 🟡 | Çoklu SSE + TRTC + YouTube WebView aynı odada |
| ✔ **Build sorunları** | 🟢 | 0 analyzer ERROR; CI yeşil (PR #306) |
| ✔ **Ağ sorunları** | 🟡 | `youtube_explode` hâlâ stream fallback; çift müzik resolve |
| ✔ **Auth sorunları** | 🟡 | Çift auth stack; cookie jar + JWT birlikte |
| ✔ **State management** | 🟡 | Riverpod monolith; yalnızca müzikte Bloc |
| ✔ **Görsel sorunları** | 🟢 | `CanlifalNetworkImage`, cache manager mevcut |
| ✔ **Video sorunları** | 🟡 | TRTC prod; Agora legacy; LiveKit unwired |
| ✔ **Ses sorunları** | 🟡 | DJ player + IFrame çift ses riski; hoparlör gate var |
| ✔ **SSE sorunları** | 🟢 | 5/5 kılavuz endpoint; reconnect backoff max 20 |
| ✔ **Cache sorunları** | 🟢 | `api_http_cache`, video/gift cache servisleri |
| ✔ **Veritabanı** | N/A mobil | Yerel: Hive/SharedPreferences; sunucu Prisma |
| ✔ **Flutter hataları** | 🟢 | 0 ERROR, 111 WARNING, 157 INFO |
| ✔ **Üretim riskleri** | 🟡 | Prod ≠ api mirror; endpoint drift; deprecated çağrılar |

**Çalışan / çalışmayan ayrımı:** [`FIXES_DONE.md`](FIXES_DONE.md) §1–2

---

## Executive summary

| Area | Status |
|------|--------|
| Architecture | Clean-ish feature modules + `core/`; Riverpod primary (~431 `*Provider` declarations, ~565 files touch Riverpod) |
| Largest risk | God files: `chat_room_providers.dart` (3,920 LOC), `live_broadcast_room_page.dart` (2,665), `chat_room_remote_datasource.dart` (2,604) |
| RTC | **TRTC is production path** for voice + live; Agora deprecated; LiveKit module exists but **not wired** into audio coordinator |
| SSE | All 5 kılavuz §5 endpoints implemented + several extras (DM, PK, admin, fortune LLM stream, room music) |
| Analyzer | **0 errors**, 111 warnings, 157 info (268 total) |
| Dead code | `lib/services/` (9 model files, test-only), deprecated Agora/LiveKit paths, legacy auth endpoints |

---

## 1. Feature modules (`lib/features/`)

**35 top-level features.** Status: **implemented** = screens + datasource/repo + providers; **partial** = subset or legacy overlap; **stub** = minimal / deprecated / unwired.

| Feature | Dart files | Pages/Screens | Status | Notes |
|---------|-----------:|--------------:|--------|-------|
| `voice_hub` | 289 | 12 | **Implemented** | Largest module: RTC page, basic/premium UI, PK, music (Bloc), gifts, moderation sheets |
| `live` | 148 | 11 | **Implemented** | Broadcast, PK, discover, TRTC live field API, gift engine |
| `fortune` | 107 | 9 | **Implemented** | Menu, AI streaming (Fortune SSE), share, access gates |
| `gifts` | 100 | 8 | **Implemented** | Catalog, battles, insights, admin editor, sync engine |
| `profile` | 96 | 22 | **Implemented** | Hub, CFC/jeton checkout, visitors, broadcast history |
| `shorts` | 63 | 8 | **Implemented** | Feed, studio publish, playback pool |
| `live_psychics` | 56 | 8 | **Implemented** | TRTC video sessions, incoming SSE, teller dashboard |
| `home` | 54 | 1 | **Implemented** | Compound home, section widgets, realtime bridge |
| `feed` | 36 | 1 | **Partial** | `FeedNotifier` **@Deprecated** → use `socialNotifierProvider` |
| `messages` | 32 | 3 | **Implemented** | DM list, chat, SSE listener |
| `auth` | 31 | 5 | **Implemented** | Login/register/OTP/reset; dual `AuthService` + repository |
| `social` | 27 | 3 | **Implemented** | Instagram-style feed; primary social surface |
| `admin` | 22 | 4 | **Partial** | Staff hub, gifts, voice backgrounds; role-gated |
| `games` | 20 | 7 | **Implemented** | Game center + local Okey101 engine |
| `cosmetics` | 20 | 1 | **Implemented** | Catalog, equip, 17 providers |
| `vip_gold` | 16 | 1 | **Implemented** | VIP hub, room password gate |
| `membership` | 13 | 2 | **Implemented** | Premium packages |
| `notifications` | 11 | 1 | **Implemented** | List + `NotificationsSseService` |
| `wallet` | 10 | 2 | **Implemented** | Balances, withdrawal |
| `trtc` | 9 | 0 | **Implemented** | `TrtcRoomManager`, bootstrap, live room coordinator (no UI) |
| `shell` | 8 | 1 | **Implemented** | App shell / role panels |
| `search` | 7 | 1 | **Implemented** | Global user search |
| `moderation` | 7 | 1 | **Implemented** | Report flow |
| `platform` | 6 | 0 | **Implemented** | Popups, ads, fortune request types (data only) |
| `favorites` | 6 | 1 | **Implemented** | User favorites |
| `content_hub` | 6 | 2 | **Partial** | Native feature hub; some placeholder tiles |
| `legal` | 5 | 1 | **Implemented** | Site pages CMS |
| `agora` | 5 | 0 | **Stub** | **@Deprecated** — "Tencent TRTC kullanın" |
| `video_call` | 4 | 1 | **Partial** | Invitation service + incoming screen |
| `agency` | 4 | 1 | **Partial** | Agency dashboard only |
| `admin_web` | 4 | 1 | **Partial** | WebView SSO admin panel |
| `livekit` | 3 | 0 | **Stub** | Token datasource + manager; **not used** by `VoiceRoomAudioCoordinator` |
| `system` | 2 | 2 | **Implemented** | Maintenance + force-update gates |
| `debug` | 1 | 1 | **Stub** | `api_monitor_page.dart` only |
| `canlifal_web` | 1 | 1 | **Partial** | Single WebView page |

**Also outside `features/`:**

| Path | Files | Status |
|------|------:|--------|
| `lib/core/` | 199 | Shared network, SSE, auth, theme, perf, router hooks |
| `lib/app/` | ~15 | `app.dart`, `go_router` (`app_router.dart` 1,089 LOC) |
| `lib/services/` | 9 | **Dead** — duplicate auth models; only referenced from `mobile/test/` |

---

## 2. State management

### Riverpod (primary)

- **Package:** `flutter_riverpod: ^2.6.1`
- **~431** `final …Provider` declarations across **~565** files
- **Patterns:** `Provider`, `FutureProvider`, `StreamProvider`, `Notifier` / `AsyncNotifier`, `family`, `autoDispose`
- **Core hubs:** `dio_provider.dart`, `sse_hub_provider.dart`, `token_storage.dart`, `auth_providers.dart`

### Bloc (minimal)

- **Package:** `flutter_bloc: ^9.1.1`
- **Only real Bloc:** `RoomSongBloc` (`voice_hub/music/presentation/bloc/`) — room song playback state
- **Consumers:** `room_song_mini_player.dart`, `voice_room_rtc_page.dart`
- No app-wide Bloc architecture; Riverpod owns global state

### Notable provider clusters

| Domain | Key files | Provider count (approx.) |
|--------|-----------|-------------------------|
| Voice room | `chat_room_providers.dart` (+ 6 partials) | Monolith + split files |
| Live | `live_providers.dart`, `pk_room_providers.dart` (19), `live_room_providers.dart` | ~40+ files |
| Profile | `profile_providers.dart` | 37 declarations in one file |
| Gifts | `gift_providers.dart`, `gift_insights_providers.dart` (17) | ~35 files |
| Shorts | `shorts_providers.dart` | 21 declarations |
| Home | `home_providers.dart` | 23 declarations |

### Duplicate / overlapping provider patterns

| Pattern | Locations |
|---------|-----------|
| Voice vs live gift totals | `voice_seat_gift_totals_provider.dart` (canonical) + `live/.../live_seat_gift_totals_provider.dart` (wraps voice) |
| Voice vs live gift providers | `voice_gift_providers.dart` vs `live/gifts/providers/live_gift_providers.dart` |
| Discover voice rooms | `live/presentation/providers/discover_voice_rooms.dart` (canonical); consumed by `voice_hub`, `home` |
| Discover live streams | `live/presentation/providers/discover_live_streams.dart` |
| Feed vs social | `feed_providers.dart` deprecated; `social_providers.dart` is source of truth |
| Auth user | `auth_providers.dart` + `core/providers/auth_selectors.dart` + `session_user_cache.dart` |

---

## 3. Dead code

### Unused / orphan files

| Path | Evidence |
|------|----------|
| `lib/services/models/*` (9 files) | No imports from `lib/`; only `mobile/test/*` |
| `lib/features/agora/*` | `@Deprecated`; TRTC replaced |
| `lib/features/voice_hub/presentation/audio/voice_agora_engine.dart` | `@Deprecated` |
| `lib/features/livekit/*` | No runtime imports from voice/live coordinators |
| `lib/features/voice_hub/data/services/voice_room_sse_service.dart` | Re-export alias only → `chat_room_sse_service.dart` |

### Deprecated API constants (still in codebase)

| Constant | File | Still used? |
|----------|------|-------------|
| `meGiftsReceived` | `api_endpoints.dart` | Alias only |
| `socialPublicStats` | `api_endpoints.dart` | **Yes** — `platform_stats_remote_datasource.dart` |
| `authLogin/Register/Refresh/Me` | `api_endpoints.dart` | **Yes** — fallback when `Env.useMobileAuth == false` |
| `messagesConversations` | `api_endpoints.dart` | **Yes** — DM fallback chain |
| `fortuneTellerIncomingSessions` | `api_endpoints.dart` | **Yes** — `live_psychics_remote_datasource.dart` (prod may 405) |
| `musicSearch` (deprecated comment) | `api_endpoints.dart` | Check callers |

### Deprecated Dart APIs

- `FeedNotifier` / `feedNotifierProvider` → use `socialNotifierProvider`
- `AgoraRoomManager`, `VoiceAgoraEngine`
- `AuthFlowApp` wrapper → `AuthGatewayHost`
- `createFortunePost` on social repository → `SocialFortuneFeedSync`

### Commented / legacy blocks

- No widespread `// TODO` / `// FIXME` in `lib/` (0 matches)
- Legacy self-hosted auth block in `api_endpoints.dart` lines 54–60
- `Env.preferLiveKit` defined but **never read** outside `env.dart`

---

## 4. Duplicate code

### Repositories (35 domain/data pairs)

Standard `domain/repositories/*` + `data/repositories/*_impl.dart` for: auth, feed, favorites, fortune, games, home, live, messages, moderation, notifications, profile, search, shorts, social, voice discover, room music.

**Non-repository data access:** many features use `*_remote_datasource.dart` directly from providers (gifts, wallet, admin, agency, cosmetics).

### Duplicate page / flow names

| Name | Paths |
|------|-------|
| PK battle page | `live/presentation/pages/live_pk_battle_page.dart`, `voice_hub/presentation/pages/voice_pk_battle_page.dart` |
| PK invite page | `live/.../live_pk_invite_page.dart`, `voice_hub/.../pk_invite_page.dart` |
| Gift leaderboard | gifts hub + voice/live overlays |

### Duplicate models

| Canonical | Duplicate / legacy |
|-----------|-------------------|
| `features/auth/data/models/*` | `lib/services/models/auth_*.dart` (unused) |
| `features/home/data/models/mobile_compound_models.dart` | `lib/services/models/mobile_compound_models.dart` |

### Name-pattern duplicates

- `*_remote_datasource.dart` — 40+ files
- `*_providers.dart` — 125 files
- `premium_2026/` UI duplicated under `voice_hub`, `live`, `fortune`, `profile`, `gifts`

---

## 5. Auth (JWT, refresh, login)

### Key files

| Layer | Path |
|-------|------|
| Service (canonical) | `features/auth/data/datasources/auth_service.dart` |
| Legacy datasource | `features/auth/data/datasources/auth_remote_datasource.dart` |
| Native OAuth | `features/auth/data/datasources/native_auth_datasource.dart` |
| Repository | `features/auth/data/repositories/auth_repository_impl.dart` |
| State | `features/auth/presentation/providers/auth_providers.dart` (`AuthController`) |
| Token storage | `core/network/token_storage.dart` (`flutter_secure_storage`) |
| Refresh coordinator | `core/network/auth_token_refresh_coordinator.dart` |
| Dio interceptors | `core/network/dio_provider.dart` |
| Bootstrap | `core/bootstrap/auth_redirect.dart`, `session_data_refresh.dart` |
| UI | `features/auth/presentation/pages/{login,register,otp_verify,forgot_password,reset_password}_page.dart` |

### Implemented flows

- Email/username + password → `POST /api/auth/mobile-login`
- Register → `POST /api/auth/mobile-register` (birth date/time required on production)
- Google / Apple / TikTok → `mobile-google`, `mobile-apple`, `mobile-tiktok`
- Refresh → `POST /api/auth/mobile-refresh` (7d access / 30d refresh per kılavuz)
- Profile → `GET /api/me`
- Sessions → list + revoke (`mobile-sessions`)
- Password reset, email verification, device token, logout

### Gaps / risks

| Gap | Detail |
|-----|--------|
| **Dual auth stack** | `AuthService` + `AuthRepository` + `AuthRemoteDataSource` overlap; repository still wires cookie jar |
| **Legacy fallback** | `Env.useMobileAuth` false → old `/api/auth/login`, `/api/auth/me` (local API only) |
| **Cookie session marker** | `TokenStorage.sessionCookieMarker` for NextAuth-era paths |
| **Device verify** | `authVerifyDevice` / `authReclaimDevice` — kılavuz notes GET vs POST conflict; unclear mobile usage |
| **TRTC bootstrap on login** | `auth_providers.dart` imports `trtc_bootstrap_service.dart` — side effect on auth boot |
| **No `// TODO` markers** | Gaps not documented in code |

---

## 6. Voice rooms

### Key files (by layer)

| Layer | Paths |
|-------|-------|
| **Entry UI** | `voice_room_rtc_page.dart` (1,833 LOC), `voice_room_basic_page.dart`, `voice_rooms_page.dart`, `voice_room_route_page.dart` |
| **State** | `chat_room_providers.dart` (3,920 LOC) + partials: `_presence`, `_music`, `_room_sync`, `_gift`, `_seat`, `_moderation` |
| **API** | `chat_room_remote_datasource.dart` (2,604 LOC) |
| **SSE** | `chat_room_sse_service.dart` |
| **Audio** | `voice_room_audio_coordinator.dart`, `voice_trtc_engine.dart`, `voice_room_dj_player.dart` (1,423 LOC) |
| **Music** | `voice_hub/music/` — Bloc + `room_music_providers.dart`, `room_music_remote_datasource.dart` |
| **Gifts** | `voice_gift_providers.dart`, `gift_session_controller.dart`, `voice_room_gift_sheet.dart` |
| **PK** | `pk_battle_remote_datasource.dart`, `pk_battle_provider.dart`, `voice_pk_battle_page.dart` |
| **Discover** | `voice_rooms_discover_providers.dart`, `voice_rooms_presence_provider.dart` |
| **Video bg** | `video/presentation/` — YouTube embed, room video overlay |

### Integrations

| System | Implementation |
|--------|----------------|
| **SSE** | `GET /api/chat/rooms/{id}/stream` via `ChatRoomSseService` + `SseConnectionHub` ref-counting |
| **TRTC** | `VoiceRoomAudioCoordinator` → `VoiceTrtcEngine` → `TrtcRoomManager`; voice API `POST …/voice` `{action: join}` |
| **Music** | REST + `GET /api/chat/rooms/{id}/music/stream` SSE; `RoomSongBloc`; DJ player |
| **Gifts** | SSE `gift` events → `gift_engine_sse_router.dart` → `GiftSessionController` |
| **Presence** | `VoiceRoomsPresenceNotifier` — up to 12 room SSE connections on discover |

---

## 7. Live / RTC (Agora vs TRTC vs LiveKit)

### Grep summary (meaningful references)

| Engine | Files (approx.) | Role |
|--------|----------------:|------|
| **TRTC** | ~55 files | **Primary** — voice rooms, live broadcast, psychics, PK |
| **Agora** | ~18 files | **Deprecated** — managers/engines marked obsolete; comments in live quality provider |
| **LiveKit** | ~9 files | **Dormant** — `livekit_room_manager.dart`, token API; `Env.preferLiveKit` unused |

### TRTC entry points

- `features/trtc/presentation/trtc_room_manager.dart`
- `features/trtc/presentation/trtc_live_room_coordinator.dart`
- `features/trtc/presentation/trtc_bootstrap_service.dart`
- `features/voice_hub/presentation/audio/voice_trtc_engine.dart`
- `features/live/presentation/pages/live_broadcast_room_page.dart`
- `features/live_psychics/presentation/controllers/psychic_video_controller.dart`

### Token endpoints (`api_endpoints.dart`)

- TRTC: `/api/trtc/*` (token, live join)
- Agora: `/api/agora/token` (legacy comments)
- LiveKit: `/api/livekit/token`

### `Env.voiceEngine`

`auto` | `livekit` | `trtc` | `agora` — default `auto`; coordinator **hardcodes TRTC** regardless.

---

## 8. SSE services and endpoints

### Kılavuz §5 (5 required) — all implemented

| Endpoint | Service | File |
|----------|---------|------|
| `GET /api/chat/rooms/{roomId}/stream` | `ChatRoomSseService` | `voice_hub/data/services/chat_room_sse_service.dart` |
| `GET /api/video-streams/{streamId}/stream` | `VideoStreamSseService` | `live/data/services/video_stream_sse_service.dart` |
| `GET /api/room/{sessionId}/stream` | `PsychicRoomSseService` | `live_psychics/data/services/psychic_room_sse_service.dart` |
| `GET /api/fortune-tellers/sessions/stream` | `PsychicIncomingSseService` | `live_psychics/data/services/psychic_incoming_sse_service.dart` |
| `GET /api/notifications/stream` | `NotificationsSseService` | `notifications/data/services/notifications_sse_service.dart` |

### Additional SSE (beyond kılavuz §5)

| Endpoint | Service | File |
|----------|---------|------|
| `GET /api/messages/conversations/{id}/stream` | `MessageSseService` | `messages/data/services/message_sse_service.dart` |
| `GET /api/pk/{matchId}/stream` | `PkMatchSseService` | `live/data/pk/pk_match_sse_service.dart` |
| `GET /api/admin/payments/stream` | `AdminPaymentsSseService` | `admin/data/services/admin_payments_sse_service.dart` |
| `GET /api/chat/rooms/{id}/music/stream` | via `room_music_remote_datasource.dart` | Music queue sync |
| Fortune LLM `POST` streams | `FortuneSseService` | `fortune/data/services/fortune_sse_service.dart` |
| Misnamed `NotificationSseService` | Uses chat room stream for presence-only | `voice_hub/data/services/notification_sse_service.dart` |

### Infrastructure

| File | Role |
|------|------|
| `core/network/sse/base_sse_service.dart` | Base class, parse, reconnect hooks |
| `core/network/sse/sse_connection_hub.dart` | Ref-counted voice + video stream leases |
| `core/network/sse/sse_reconnect_policy.dart` | 1→30s backoff, max 20 attempts (kılavuz §6) |
| `core/network/sse/sse_hub_provider.dart` | Riverpod provider |
| `core/sse_client.dart` | Lower-level client (fortune teller stream) |
| `core/network/auth_token_refresh_coordinator.dart` | 401 → refresh → reconnect |

---

## 9. Performance risks

### Oversized files (>800 LOC)

| LOC | File | Risk |
|----:|------|------|
| 3,920 | `voice_hub/.../chat_room_providers.dart` | Single notifier file; rebuild blast radius |
| 2,665 | `live/.../live_broadcast_room_page.dart` | Monolithic widget tree |
| 2,604 | `voice_hub/.../chat_room_remote_datasource.dart` | Hard to test/maintain |
| 1,833 | `voice_hub/.../voice_room_rtc_page.dart` | Many `ref.watch` calls (15+) |
| 1,423 | `voice_hub/.../voice_room_dj_player.dart` | Audio + state complexity |
| 1,348 | `voice_hub/.../voice_discover_hub_2026.dart` | Heavy discover UI |
| 1,089 | `app/router/app_router.dart` | Route table maintenance |

### Rebuild / state patterns

- **Broad `ref.watch`** on large providers (`chat_room_providers`, `profile_providers`, `home_providers`)
- **`VoiceRoomsPresenceNotifier`** — up to **12 parallel SSE** subscriptions on discover
- **Split providers exist but monolith remains** — partial `chat_room_providers_*.dart` files are extensions, not full extraction
- **Performance tooling present:** `core/performance/` (`state_perf.dart`, `voice_room_entry_perf.dart`, `live_entry_perf.dart`, `device_perf_tuning.dart`)

### `const` / widget optimization

- No project-wide audit run; large premium_2026 widget trees likely missing `const` constructors
- `lazy_screen_section.dart` exists for deferred home sections

### Network

- `api_cache_policy.dart`, `api_http_cache.dart` — caching for read-heavy endpoints
- Split games API host (`gamesApiBaseUrl`) — separate origin for game rooms

---

## 10. Known broken / technical debt

### Analyzer (`dart analyze lib`)

| Severity | Count |
|----------|------:|
| Error | 0 |
| Warning | 111 |
| Info | 157 |

**Notable warnings (functional risk):**

- `gifts/.../admin_gift_management_page.dart` — invalid `onError` return types (`List<dynamic>` vs typed lists)
- `gifts/domain/gift_engine_sse_router.dart` — invalid null-aware operator
- `core/network/lazy_cookie_jar.dart` — bogus `@override`
- Many `unused_import` / `unused_element` across gifts, auth, home

**Notable info (runtime hygiene):**

- Widespread `use_build_context_synchronously` in voice room sheets/flows
- Riverpod `parent` deprecated parameter in voice room sheets (Riverpod 3 migration)
- `Share` → `SharePlus` deprecation in voice room basic premium

### TODO / FIXME

- **0** `// TODO` or `// FIXME` in `lib/` (debt not tracked in comments)

### Production parity risks

| Item | Risk |
|------|------|
| `fortuneTellerIncomingSessions` | Documented as 405 on production; still called from psychics datasource |
| `socialPublicStats` | Deprecated endpoint still used for platform stats |
| LiveKit / Agora env flags | Misleading — TRTC only in coordinator |
| Feed module | Deprecated but routes may still reference feed providers |
| `lib/services/` | Stale duplicate of auth models |

### `api_endpoints.dart` structure (962 LOC)

Grouped sections: **mobile JWT auth**, **user/me**, **legacy self-hosted auth**, **messages**, **social/feed**, **gifts**, **fortune/live-fal**, **games**, **chat/voice rooms**, **PK**, **music**, **admin**, **video streams**, **shorts**, **wallet/credits**, **TRTC/LiveKit/Agora tokens**, **notifications**, **search**, **cosmetics**, **agency**, etc.

---

## Appendix: `core/` layout (199 files)

| Subdir | Purpose |
|--------|---------|
| `network/` | Dio, endpoints, SSE, token refresh, connectivity |
| `bootstrap/` | Startup, mobile config gate, prefetch, session refresh |
| `auth/` | Session user cache |
| `performance/` | Entry perf, lazy sections, device tuning |
| `theme/` | Theme mode, AMOLED, user sync |
| `push/` | FCM / OneSignal registrars |
| `widgets/` | Shared shell widgets, avatars, offline banner |
| `navigation/` | Wallet navigation helpers |
| `images/` | CDN URL helpers, cached images |

---

## Recommended follow-ups (priority)

1. **Split `chat_room_providers.dart`** into domain notifiers (seat, gift, music, presence already partial — finish extraction).
2. **Remove or gate** `lib/services/`, deprecated Agora module, unwired LiveKit path.
3. **Migrate** `socialPublicStats` → `publicStats`; audit `fortuneTellerIncomingSessions` on production.
4. **Fix** gift admin `onError` warnings before next major Flutter SDK bump.
5. **Document** auth single-path (`AuthService` only) and drop cookie jar from mobile JWT flow when safe.
