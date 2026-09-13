# Abacus ↔ Flutter entegrasyon audit (FAZ 1)

> **Üretim:** `scripts/generate_abacus_integration_audit.py` · Kaynak: `endpoint_classification.json`

## Özet

| Metrik | Değer |
|--------|------:|
| `FLUTTER_READY` path | 306 |
| `DATASOURCE` (path + datasource/repository izi) | 53 |
| `ENDPOINT_TRACE` (yalnızca const/grep izi) | 253 |
| `MISSING` | 0 |

## Çelişki / BLOCKED (öncelik listesine göre çözülmeden tahmin yasak)

| # | Konu | Kaynak A | Kaynak B | Etki |
|---|------|----------|----------|------|
| 1 | **BÖLÜM 22 kimlik** | `BOLUM22_MULTIGUEST_PK_GIFTBOX.md` §1: Cookie; Bearer **çalışmaz** | `AUTHENTICATION.md`, `docs/FLUTTER_ENTegrasyon_KILAVUZU.md`: mobil **JWT Bearer** | Multi-guest, gift-box, B22 PK uçları — üretimde hangi auth geçerli doğrulanmalı |
| 2 | **SSE kanal sayısı** | Kılavuz §5: **5** SSE endpoint | `REALTIME.md`: PK `GET /api/pk/{matchId}/stream` + fal POST-SSE | PK SSE kılavuzda yok; mobil `pk_match_sse_service` Abacus REALTIME ile hizalı |
| 3 | **E-posta doğrulama yolu** | Abacus: `POST /api/auth/email/send-verification` | Repoda ayrıca: `/api/auth/mobile-send-verification` (parity dokümanları) | İki path; Abacus FLUTTER_READY yalnız ilki — hangisi üretimde canonical netleştirilmeli |

**Kural:** Yukarıdaki #1 çözülmeden BÖLÜM 22 davranışı için yeni auth varsayımı yapılmaz.

## Yeni Abacus katmanları (henüz UI/repository bağlı değil)

| Sınıf | Durum |
|-------|--------|
| `AbacusAuthRemoteDataSource` | Provider var; `AuthRemoteDataSource` / ekranlara **bağlı değil** |
| `MeEntitlementsRemoteDataSource` | Yalnız `meMembershipPackageProvider` |
| `UserAbacusRemoteDataSource` | Provider **yok**; kullanım **yok** |
| `DreamsAbacusRemoteDataSource` | Provider **yok**; kullanım **yok** |
| `SocialDiscoveryRemoteDataSource` (genişletme) | Tanış Kaynaş UI; hashtag/takım/share **UI yok** |
| `GiftBoxRemoteDataSource` | Datasource var; tam UI **kısmi** |

## Contract test envanteri

| Alan | Dosya |
|------|--------|
| Auth/VIP/Dreams/Social path | `test/core/abacus/abacus_zip_contract_test.dart` |
| Tanış Kaynaş | `test/features/social/social_discovery_contract_test.dart` |
| Gift box | `test/features/gift_box/gift_box_contract_test.dart` |
| Endpoint canonical | `test/core/network/api_endpoint_canonical_contract_test.dart` |
| Live / Voice / PK / Guest / Wallet / Payment / Messaging / Games / CMS | **Dedicated contract test yok** (genel unit/widget testler var) |

## Entegrasyon matrisi (örnek — tam liste aşağıda)

| FEATURE | BACKEND ENDPOINT | HTTP | AUTH | FLUTTER | DURUM | TEST |
|---------|------------------|------|------|---------|-------|------|
| Login | `/api/auth/mobile-login` | POST | Bearer | `auth_remote_datasource.dart` | WIRED | implicit |
| Refresh | `/api/auth/mobile-refresh` | POST | — | `dio_provider` + auth | WIRED | implicit |
| Sessions | `/api/auth/sessions` | GET/DELETE | Bearer | `auth_remote_datasource.dart` | WIRED | partial |
| Email verify (Abacus) | `/api/auth/email/send-verification` | POST | JWT | `abacus_auth_remote_datasource.dart` | **DATASOURCE ONLY** | path const |
| Phone OTP | `/api/auth/phone/send-otp` | POST | — | `abacus_auth_remote_datasource.dart` | **DATASOURCE ONLY** | path const |
| Verification KYC | `/api/verification` | GET/POST | — | `abacus_auth_remote_datasource.dart` | **DATASOURCE ONLY** | path const |
| Membership | `/api/me/membership` | GET | Bearer | `me_entitlements_remote_datasource.dart` | **DATASOURCE ONLY** | path const |
| Live guest list | `/api/live/guest/list` | GET | **BLOCKED #1** | `live_api_remote_datasource.dart` | WIRED (Bearer) | — |
| Live guest actions | `/api/live/guest` | POST | **BLOCKED #1** | `live_stream_extras_datasource.dart` (grep) | PARTIAL | — |
| Chat room SSE | `/api/chat/rooms/{id}/stream` | GET SSE | Bearer | `chat_room_sse_service.dart` | WIRED | sse tests |
| Video stream SSE | `/api/video-streams/{id}/stream` | GET SSE | Bearer | live stream SSE | WIRED | partial |
| PK match SSE | `/api/pk/{id}/stream` | GET SSE | Bearer | `pk_match_sse_service.dart` | WIRED | — |
| Gift box | `/api/gift-box` | GET/POST | **BLOCKED #1** | `gift_box_remote_datasource.dart` | DATASOURCE | contract |

## Tam path matrisi

| Path | Methods | Durum | Datasource/Repo izi | Contract test |
|------|---------|-------|----------------------|---------------|
| `/api/activities` | GET | ENDPOINT_TRACE | — | contract |
| `/api/ads/placement` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/ads/reward` | POST | ENDPOINT_TRACE | — | contract |
| `/api/agency/applicant-score/[userId]` | GET | ENDPOINT_TRACE | — | — |
| `/api/agency/apply` | POST | ENDPOINT_TRACE | — | — |
| `/api/agency/earnings` | GET | ENDPOINT_TRACE | — | — |
| `/api/agency/growth` | GET | ENDPOINT_TRACE | — | — |
| `/api/agency/invite` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/agency/invite-earnings` | GET | ENDPOINT_TRACE | — | contract |
| `/api/agency/join` | POST | ENDPOINT_TRACE | — | — |
| `/api/agency/leave` | DELETE, POST | ENDPOINT_TRACE | — | — |
| `/api/agency/live-status` | GET | ENDPOINT_TRACE | — | — |
| `/api/agency/members` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/agency/my` | GET, PATCH | ENDPOINT_TRACE | — | — |
| `/api/agency/tasks` | GET | ENDPOINT_TRACE | — | — |
| `/api/agency/wallet` | GET | ENDPOINT_TRACE | — | — |
| `/api/agency/wallet/transfer` | POST | ENDPOINT_TRACE | — | — |
| `/api/agency/withdrawals` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/animations/me` | GET | ENDPOINT_TRACE | — | — |
| `/api/animations/resolve` | GET | ENDPOINT_TRACE | — | — |
| `/api/astrology-panel` | GET | ENDPOINT_TRACE | — | — |
| `/api/auth/change-password` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/auth/email/send-verification` | POST | ENDPOINT_TRACE | — | contract |
| `/api/auth/logout` | POST | DATASOURCE | features/auth/data/datasources/auth_remote_datasource.dart, features/auth/data/datasources/auth_service.dart | contract |
| `/api/auth/logout-all` | POST | DATASOURCE | features/auth/data/datasources/auth_remote_datasource.dart | contract |
| `/api/auth/mobile-apple` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/auth/mobile-google` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/auth/mobile-login` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | contract |
| `/api/auth/mobile-refresh` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/auth/mobile-register` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/auth/mobile-tiktok` | POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/auth/phone/send-otp` | POST | ENDPOINT_TRACE | — | contract |
| `/api/auth/phone/verify-otp` | POST | ENDPOINT_TRACE | — | contract |
| `/api/auth/sessions` | DELETE, GET | ENDPOINT_TRACE | — | contract |
| `/api/bana-ozel` | GET | ENDPOINT_TRACE | — | contract |
| `/api/bana-ozel/open` | POST | ENDPOINT_TRACE | — | contract |
| `/api/billing/app-store/verify` | POST | ENDPOINT_TRACE | — | — |
| `/api/billing/google-play/verify` | POST | ENDPOINT_TRACE | — | — |
| `/api/blog/comments` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/blog/favorite` | POST | ENDPOINT_TRACE | — | — |
| `/api/blog/interactions` | GET | ENDPOINT_TRACE | — | — |
| `/api/blog/like` | POST | ENDPOINT_TRACE | — | — |
| `/api/bootstrap` | GET | ENDPOINT_TRACE | — | — |
| `/api/broadcast-images` | GET | DATASOURCE | features/platform/data/datasources/platform_content_remote_datasource.dart | — |
| `/api/cache` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/cfc-arena/join` | POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/gifts` | GET, POST | DATASOURCE | features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart | — |
| `/api/chat/rooms/[roomId]/messages` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/moderation` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/music` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/music-queue` | GET | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/music/stop` | POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/seats` | GET, PATCH | DATASOURCE | features/voice_hub/data/datasources/chat_room_remote_datasource.dart | — |
| `/api/chat/rooms/[roomId]/settings` | GET, PATCH | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/song-request` | GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/speak-request` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | DELETE, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | DELETE, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/speak-requests` | GET | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/state` | GET | DATASOURCE | features/voice_hub/data/datasources/chat_room_remote_datasource.dart | — |
| `/api/chat/rooms/[roomId]/stream` | GET | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/sync` | GET | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/typing` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/[roomId]/voice` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/chat/rooms/create` | POST | DATASOURCE | features/live/data/datasources/live_remote_datasource.dart | — |
| `/api/chat/rooms/pk/candidates` | GET | ENDPOINT_TRACE | — | — |
| `/api/daily-login` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/daily-missions` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/devices/fcm` | DELETE, POST | DATASOURCE | features/auth/data/datasources/auth_service.dart | — |
| `/api/dream-contest` | GET | ENDPOINT_TRACE | — | contract |
| `/api/dream-contest/[contestId]/entries` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/dream-contest/[contestId]/vote` | POST | ENDPOINT_TRACE | — | — |
| `/api/dream-diary` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/dream-stats` | GET | ENDPOINT_TRACE | — | — |
| `/api/dreams/[slug]/favorite` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/dreams/[slug]/view` | POST | ENDPOINT_TRACE | — | — |
| `/api/dreams/favorites` | GET | ENDPOINT_TRACE | — | — |
| `/api/dreams/interpret` | POST | ENDPOINT_TRACE | — | contract |
| `/api/dreams/recommendations` | GET | ENDPOINT_TRACE | — | — |
| `/api/effects/resolve` | GET | ENDPOINT_TRACE | — | — |
| `/api/favorite-tellers` | GET, POST | DATASOURCE | features/live_psychics/domain/repositories/live_psychics_repository.dart | — |
| `/api/fortune-access/check` | POST | DATASOURCE | features/fortune/data/datasources/fortune_access_remote_datasource.dart | — |
| `/api/fortune-tellers` | GET, POST | DATASOURCE | features/live_psychics/data/repositories/live_psychics_remote_datasource.dart, features/live_psychics/domain/repositories/live_psychics_repository.dart | contract |
| `/api/fortune-tellers/[tellerId]/session` | GET, POST | DATASOURCE | features/live_psychics/data/repositories/live_psychics_remote_datasource.dart | — |
| `/api/fortune-tellers/apply` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortune-tellers/my-profile` | GET | ENDPOINT_TRACE | — | — |
| `/api/fortune-tellers/session` | GET, POST | DATASOURCE | features/live_psychics/data/repositories/live_psychics_remote_datasource.dart, features/live_psychics/domain/repositories/live_psychics_repository.dart | contract |
| `/api/fortune-tellers/sessions` | GET | DATASOURCE | features/live_psychics/data/repositories/live_psychics_remote_datasource.dart, features/live_psychics/domain/repositories/live_psychics_repository.dart | — |
| `/api/fortune-tellers/sessions/[sessionId]` | PATCH | ENDPOINT_TRACE | — | — |
| `/api/fortune-tellers/sessions/stream` | GET | ENDPOINT_TRACE | — | — |
| `/api/fortune-tellers/toggle-online` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/ask-uyumu` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/aura-analizi` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/burc-yorumu` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/dogum-haritasi` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/el-fali` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/evet-hayir` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/istihare` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/kahve-fali` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/kahve-fali-image` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/katina` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/kursundokme` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/melek-kartlari` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/numeroloji` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/ruya-yorumu` | POST | ENDPOINT_TRACE | — | — |
| `/api/fortunes/tarot-fali` | POST | ENDPOINT_TRACE | — | — |
| `/api/games/auto-match` | POST | ENDPOINT_TRACE | — | contract |
| `/api/games/daily-reward` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/games/daily-spin` | POST | ENDPOINT_TRACE | — | — |
| `/api/games/lamba-cini` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/games/leaderboard` | GET | ENDPOINT_TRACE | — | contract |
| `/api/games/lobby` | GET | ENDPOINT_TRACE | — | — |
| `/api/games/play` | POST | ENDPOINT_TRACE | — | contract |
| `/api/games/profile` | GET | ENDPOINT_TRACE | — | — |
| `/api/games/quests` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/games/room` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/games/room/[roomId]` | DELETE, GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/games/room/[roomId]/chat` | GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/games/room/[roomId]/replace-ai` | POST | ENDPOINT_TRACE | — | — |
| `/api/games/room/[roomId]/viewers` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/games/sos` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/games/sos/[gameId]` | DELETE, GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/games/sos/[gameId]/chat` | GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/games/sos/[gameId]/viewers` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/gift-box` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/gift-box/[boxId]/join` | POST | ENDPOINT_TRACE | — | — |
| `/api/gift-box/share` | POST | ENDPOINT_TRACE | — | contract |
| `/api/gift-engine/finish` | POST | ENDPOINT_TRACE | — | — |
| `/api/gifts/battles` | GET, POST | DATASOURCE | features/gifts/data/gift_battle_remote_datasource.dart | contract |
| `/api/gifts/catalog` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/check-reciprocal` | POST | DATASOURCE | features/gifts/data/gift_repository.dart | contract |
| `/api/gifts/goals` | GET, POST | DATASOURCE | features/gifts/data/gift_goal_remote_datasource.dart | contract |
| `/api/gifts/insights/me/badge` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/insights/me/history` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/insights/me/recommendations` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/lucky/config` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/lucky/history` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/lucky/send` | POST | ENDPOINT_TRACE | — | — |
| `/api/gifts/missions/[missionId]/claim` | POST | ENDPOINT_TRACE | — | — |
| `/api/gifts/missions/me` | GET | ENDPOINT_TRACE | — | — |
| `/api/gifts/send` | POST | ENDPOINT_TRACE | — | — |
| `/api/hashtags/[name]` | GET | ENDPOINT_TRACE | — | — |
| `/api/horoscope/daily` | GET | DATASOURCE | features/home/data/datasources/home_remote_datasource.dart | — |
| `/api/jeton` | GET, POST | DATASOURCE | features/profile/data/datasources/daily_tasks_remote_datasource.dart | — |
| `/api/leaderboards` | GET | ENDPOINT_TRACE | — | — |
| `/api/leaderboards/top100` | GET | ENDPOINT_TRACE | — | — |
| `/api/live/create-room` | POST | DATASOURCE | features/live/data/datasources/live_field/live_field_room_lifecycle_api.dart | — |
| `/api/live/gift-types` | GET | ENDPOINT_TRACE | — | — |
| `/api/live/gift/send` | POST | ENDPOINT_TRACE | — | contract |
| `/api/live/guest` | GET, POST | DATASOURCE | features/live/data/datasources/live_api_remote_datasource.dart | contract |
| `/api/live/heartbeat` | POST | ENDPOINT_TRACE | — | — |
| `/api/live/join-room` | POST | ENDPOINT_TRACE | — | — |
| `/api/live/leave-room` | POST | ENDPOINT_TRACE | — | — |
| `/api/live/message` | GET, POST | DATASOURCE | features/live/data/datasources/live_field/live_field_message_api.dart | — |
| `/api/live/online-users` | GET | DATASOURCE | features/live/data/datasources/live_field/live_field_online_users_api.dart | — |
| `/api/live/pk` | GET, POST | DATASOURCE | features/live/data/datasources/live_api_remote_datasource.dart, features/live/data/datasources/live_field/live_field_pk_api.dart, features/live/data/pk/pk_room_remote_datasource.dart | contract |
| `/api/live/rooms` | GET | DATASOURCE | features/live/data/datasources/live_field/live_field_room_discovery_api.dart | — |
| `/api/live/seats` | GET, POST | DATASOURCE | features/live/data/datasources/live_field/live_field_seats_api.dart | — |
| `/api/me` | GET, PATCH | DATASOURCE | core/me/me_entitlements_remote_datasource.dart, features/auth/data/datasources/auth_service.dart, features/membership/data/membership_remote_datasource.dart | contract |
| `/api/me/admin-capabilities` | GET | ENDPOINT_TRACE | — | — |
| `/api/me/membership` | GET | DATASOURCE | core/me/me_entitlements_remote_datasource.dart | contract |
| `/api/me/membership-events` | GET | ENDPOINT_TRACE | — | — |
| `/api/me/membership-history` | GET, PUT | ENDPOINT_TRACE | — | — |
| `/api/me/profile-visitors` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/me/vip-identity` | GET, PUT | ENDPOINT_TRACE | — | — |
| `/api/me/vip-preferences` | GET, PUT | ENDPOINT_TRACE | — | — |
| `/api/me/vip-xp` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/memberships/gift` | POST | ENDPOINT_TRACE | — | — |
| `/api/memberships/purchase` | POST | DATASOURCE | features/membership/data/membership_remote_datasource.dart | contract |
| `/api/messages` | GET | ENDPOINT_TRACE | — | — |
| `/api/messages/[userId]` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/messages/request` | PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/mobile/fortune-menu` | GET | DATASOURCE | features/home/data/datasources/mobile_compound_remote_datasource.dart | — |
| `/api/mobile/home` | GET | DATASOURCE | features/home/data/datasources/mobile_compound_remote_datasource.dart | — |
| `/api/mobile/user-profile/[userId]` | GET | DATASOURCE | features/home/data/datasources/mobile_compound_remote_datasource.dart | — |
| `/api/music/search` | GET | ENDPOINT_TRACE | — | — |
| `/api/notifications` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/notifications/stream` | GET | ENDPOINT_TRACE | — | — |
| `/api/payments/config` | GET | ENDPOINT_TRACE | — | contract |
| `/api/payments/notifications/[notificationId]/dispute` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/payments/notify` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/payments/requests` | GET, POST | DATASOURCE | features/profile/data/datasources/profile_remote_datasource.dart | contract |
| `/api/pk/me/invites` | GET | ENDPOINT_TRACE | — | — |
| `/api/popups` | GET | ENDPOINT_TRACE | — | contract |
| `/api/presence` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/profile-frames` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/referral` | GET | ENDPOINT_TRACE | — | contract |
| `/api/refunds` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/room-themes/catalog` | GET | ENDPOINT_TRACE | — | — |
| `/api/room/[sessionId]` | GET, PATCH | ENDPOINT_TRACE | — | — |
| `/api/room/[sessionId]/messages` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/room/[sessionId]/review` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/room/[sessionId]/stream` | GET | ENDPOINT_TRACE | — | — |
| `/api/room/[sessionId]/summary` | GET | ENDPOINT_TRACE | — | — |
| `/api/room/[sessionId]/tip` | POST | ENDPOINT_TRACE | — | — |
| `/api/room/signal` | DELETE, GET, POST | DATASOURCE | features/live_psychics/data/repositories/live_psychics_remote_datasource.dart | — |
| `/api/rtc/telemetry` | POST | ENDPOINT_TRACE | — | — |
| `/api/search/advanced` | GET | ENDPOINT_TRACE | — | — |
| `/api/share-card` | GET | ENDPOINT_TRACE | — | contract |
| `/api/short-videos` | GET | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]` | DELETE, GET | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/comments` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/comments/[commentId]/like` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/comments/[commentId]/pin` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/duets` | GET | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/like` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/save` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/share` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/[id]/view` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/explore` | GET | ENDPOINT_TRACE | — | — |
| `/api/short-videos/profile/[userId]` | GET | ENDPOINT_TRACE | — | — |
| `/api/short-videos/register` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/upload` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/upload-url` | POST | ENDPOINT_TRACE | — | — |
| `/api/short-videos/user/[userId]` | GET | ENDPOINT_TRACE | — | — |
| `/api/social/actions` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/social/discovery` | GET | ENDPOINT_TRACE | — | contract |
| `/api/social/posts` | GET, POST | DATASOURCE | features/social/data/datasources/social_remote_datasource.dart | contract |
| `/api/social/posts/[postId]` | DELETE, GET | DATASOURCE | features/social/data/datasources/social_remote_datasource.dart | — |
| `/api/social/posts/[postId]/comments` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/social/posts/[postId]/likes` | POST | ENDPOINT_TRACE | — | — |
| `/api/social/profile` | GET | ENDPOINT_TRACE | — | contract |
| `/api/stories` | DELETE, GET, POST | DATASOURCE | features/feed/data/datasources/feed_remote_datasource.dart, features/social/data/datasources/social_remote_datasource.dart, features/social/domain/repositories/social_repository.dart | — |
| `/api/support/tickets` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/support/tickets/[ticketId]` | GET, PATCH | ENDPOINT_TRACE | — | — |
| `/api/support/tickets/[ticketId]/messages` | POST | ENDPOINT_TRACE | — | — |
| `/api/supporter-levels` | GET | ENDPOINT_TRACE | — | — |
| `/api/teams` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/teams/[teamId]` | GET, PATCH | ENDPOINT_TRACE | — | — |
| `/api/teller-chat` | GET | ENDPOINT_TRACE | — | — |
| `/api/teller-chat/[sessionId]` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/teller/analytics` | GET | ENDPOINT_TRACE | — | — |
| `/api/teller/level` | GET | ENDPOINT_TRACE | — | — |
| `/api/teller/verification` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/tournaments` | GET | ENDPOINT_TRACE | — | — |
| `/api/trends/[slug]/like` | POST | ENDPOINT_TRACE | — | — |
| `/api/trtc/token` | POST | ENDPOINT_TRACE | — | contract |
| `/api/trtc/usersig` | POST | DATASOURCE | features/trtc/data/datasources/trtc_remote_datasource.dart | contract |
| `/api/upload/get-url` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/upload/presigned` | POST | DATASOURCE | features/gifts/data/admin_gift_remote_datasource.dart | contract |
| `/api/user/[userId]/achievements` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/[userId]/follow` | DELETE, POST | ENDPOINT_TRACE | — | — |
| `/api/user/[userId]/follow-status` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/account` | DELETE, POST | ENDPOINT_TRACE | — | — |
| `/api/user/achievements` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/active-sessions` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/activity` | GET, PATCH | DATASOURCE | features/notifications/domain/repositories/notifications_repository.dart | — |
| `/api/user/block` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/user/blocked` | DELETE, GET | ENDPOINT_TRACE | — | — |
| `/api/user/broadcast-history` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/co-broadcast-invites` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/credits` | GET | ENDPOINT_TRACE | — | contract |
| `/api/user/followers` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/following` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/fortunes` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/fortunes/[fortuneId]` | PATCH | ENDPOINT_TRACE | — | — |
| `/api/user/likers` | GET | DATASOURCE | features/platform/data/datasources/platform_content_remote_datasource.dart | — |
| `/api/user/location` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/user/profile` | GET, PATCH | DATASOURCE | features/cosmetics/data/cosmetics_equip_remote_datasource.dart | — |
| `/api/user/received-gifts` | GET | ENDPOINT_TRACE | — | contract |
| `/api/user/referral-earnings` | GET | ENDPOINT_TRACE | — | contract |
| `/api/user/report` | POST | ENDPOINT_TRACE | — | — |
| `/api/user/social-settings` | GET, PUT | ENDPOINT_TRACE | — | contract |
| `/api/user/statistics` | GET | ENDPOINT_TRACE | — | — |
| `/api/user/stats` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/user/theme` | GET, PATCH | DATASOURCE | core/theme/user_theme_remote_datasource.dart | contract |
| `/api/user/wallet` | GET | ENDPOINT_TRACE | — | contract |
| `/api/user/watch-ad` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/user/xp` | GET | ENDPOINT_TRACE | — | — |
| `/api/users/[userId]` | GET | DATASOURCE | features/social/data/datasources/social_remote_datasource.dart | — |
| `/api/users/[userId]/follow` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/users/[userId]/posts` | GET | DATASOURCE | features/social/data/datasources/social_remote_datasource.dart | — |
| `/api/users/lookup/[username]` | GET | ENDPOINT_TRACE | — | — |
| `/api/users/search` | GET | ENDPOINT_TRACE | — | — |
| `/api/verification` | GET, POST | ENDPOINT_TRACE | — | contract |
| `/api/video-streams` | GET, POST | DATASOURCE | features/live/data/datasources/live_fortune_request_datasource.dart, features/live/data/datasources/live_remote_datasource.dart, features/live/data/datasources/live_stream_extras_datasource.dart | contract |
| `/api/video-streams/[streamId]/auto-close` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/ban` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/co-broadcast` | GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/co-broadcast/invite` | POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/comments` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/fortune-requests` | DELETE, GET, PATCH, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/fortune-requests/my-status` | GET | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/gifts` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/join` | DELETE, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/leave` | POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/like` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/live-started` | POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/media-heartbeat` | POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/messages` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/moderators` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/mute` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/pk-battle` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/signal` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/stream` | GET | ENDPOINT_TRACE | — | — |
| `/api/video-streams/[streamId]/sync` | GET | ENDPOINT_TRACE | — | — |
| `/api/video-streams/gifts` | GET | ENDPOINT_TRACE | — | — |
| `/api/video-streams/pk/candidates` | GET | ENDPOINT_TRACE | — | — |
| `/api/video-streams/pk/score` | POST | ENDPOINT_TRACE | — | — |
| `/api/video-streams/signal` | DELETE, GET, POST | ENDPOINT_TRACE | — | — |
| `/api/vip/leaderboard` | GET | ENDPOINT_TRACE | — | — |
| `/api/wallet` | GET | ENDPOINT_TRACE | — | contract |
| `/api/weekly-dream-report` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/withdrawals` | GET, POST | ENDPOINT_TRACE | — | — |
| `/api/youtube/search` | GET | ENDPOINT_TRACE | — | — |

## FAZ planı (bu audit sonrası)

| FAZ | Kapsam | Audit sonucu |
|-----|--------|--------------|
| 1 | Audit | **TAMAMLANDI** (bu dosya) |
| 2 | S1 Auth | EKSİK — repository/UI bağlantısı + OTP body OpenAPI MISSING |
| 3 | S2 Profile/VIP | EKSİK — entitlement UI |
| 4 | S4 Dreams | EKSİK — provider/UI |
| 5 | S11 Social | Kısmi — Tanış var; teams/hashtag UI yok |
| 6 | S3 Fortune | WIRED — `fortune_remote_datasource` + slug paths |
| 7 | S6–S7 Live/Voice/PK | **BLOCKED #1** auth çelişkisi + contract test eksik |
| 8–12 | S8–S18 + test/APK | Sırayla; contract önce |
