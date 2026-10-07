# CANLIFAL — API MISMATCH REPORT (Backend ↔ Flutter)

> 2026-10-07 · Flutter `main@45a6f4e0` · Backend `full-source@f084f3a` · Yalnız denetim.
> Yöntem: `scripts/backend-method-parity.py` mantığıyla Flutter'daki 637 çözülebilir HTTP çağrısı backend `route.ts` dosyalarına eşlendi. Her rotanın auth türü dosyadan okundu (takma ad `export {…} from` hedefine kadar izlendi).

## Auth türleri
- **JWT|oturum:** `authenticateRequest` (`lib/mobile-auth.ts:66`), önce Bearer JWT, sonra NextAuth oturumu. Flutter ile **uyumlu**.
- **rbac:** `requireAdmin`/`resolveUser` (`lib/rbac.ts:40`), JWT + oturum. Uyumlu.
- **WEB-SESSION-ONLY:** doğrudan `getServerSession(authOptions)`. Mobil Bearer JWT **görülmez** → Flutter **401/403** alır.
- **PASS\*:** public uç veya kimliği proxy hedefinde doğrulanan uç (`chat-route-proxy`, `live-fortune-proxy`, `export {…} from '../route'`). Elle doğrulanmalı.

## Sayım
| Durum | Rota+metot |
|---|---|
| PASS (kod) | 354 |
| PASS\* | 94 |
| **MISMATCH** | **30** |
| MISSING | 1 (`/api/admin/live-stats`: repoda yok, üretimde 401) |
| UNVERIFIED (dinamik yol) | 100 çağrı |
| Metot uyuşmazlığı | 0 |

Request/response gövdesi alan alan **bu turda karşılaştırılmadı**. Kritik akışların gövde sözleşmesi için [state machine raporuna](CANLIFAL_REALTIME_STATE_MACHINE_AUDIT.md) bakın.

## 1. MISMATCH — Flutter admin paneli web oturumu isteyen uçları çağırıyor (30)

Kanıt (üretim, yetkisiz): `GET /api/admin/statistics` → `401 {"error":"Oturum açmanız gerekiyor"}`. Backend kodu yalnız `getServerSession` okuduğu için Bearer JWT ile de aynı sonuç alınır. Örnekler: `app/api/admin/statistics/route.ts:12–24`, `admin/users/search/route.ts:12–14`, `admin/gifts/route.ts:17–19`, `admin/room-themes/backgrounds/route.ts:16–18`, `lib/animation-admin.ts:29–30`.

**Kök neden:** bildirilen #26, #27, #28 ("admin paneli çalışmıyor / bazı işlemler hiç çalışmıyor").
**Öneri:** Backend'de bu rotalarda `getServerSession` → `requireAdmin(req)` / `resolveUser(req)` (`lib/rbac.ts`). Flutter değişmez.

| Backend rota | Metot | Flutter çağrı yeri |
|---|---|---|
| `/api/admin/activity-feed` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:334` |
| `/api/admin/cfc-settings` | GET | `mobile/lib/features/admin/presentation/providers/admin_providers.dart:172` |
| `/api/admin/credits` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:208` |
| `/api/admin/finance` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:393` |
| `/api/admin/gifts` | GET | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:48` |
| `/api/admin/gifts` | POST | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:96` |
| `/api/admin/gifts/[giftId]` | DELETE | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:153` |
| `/api/admin/gifts/[giftId]` | PATCH | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:133` |
| `/api/admin/gifts/stats` | GET | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:163` |
| `/api/admin/live-tellers` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:507` |
| `/api/admin/live-tellers` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:539` |
| `/api/admin/live-tellers/[tellerId]/approve` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:568` |
| `/api/admin/notifications` | GET | `mobile/lib/features/admin/presentation/providers/admin_providers.dart:110` |
| `/api/admin/site-animations` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:27` |
| `/api/admin/site-animations` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:63` |
| `/api/admin/site-animations/[id]` | PATCH | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:84` |
| `/api/admin/site-animations/assign` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:237` |
| `/api/admin/site-animations/bulk-assign` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:272` |
| `/api/admin/site-animations/defaults` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:111` |
| `/api/admin/site-animations/defaults` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:145` |
| `/api/admin/site-animations/exit-defaults` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:165` |
| `/api/admin/site-animations/exit-defaults` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:191` |
| `/api/admin/site-animations/stats` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:46` |
| `/api/admin/site-animations/user/[userId]` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:213` |
| `/api/admin/statistics` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:87` |
| `/api/admin/users/[userId]` | GET | `mobile/lib/features/admin/presentation/providers/admin_bulk_operations_providers.dart:38` |
| `/api/admin/users/[userId]` | PATCH | `mobile/lib/features/admin/data/admin_remote_datasource.dart:133` |
| `/api/admin/users/search` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:40` |
| `/api/admin/users/withdrawal-limit` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:583` |
| `/api/admin/voice-room-backgrounds` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:722` |

## 2. Diğer sözleşme uyumsuzlukları

| # | Konu | Backend | Flutter | Durum |
|---|---|---|---|---|
| 31 | PK REST ↔ SSE farklı backend | `/api/pk/{id}` hem canlifal.com'da hem games backend'de var | REST → `canlifalapi.abacusai.app` (`api_backend_router.dart:26`), SSE → `canlifal.com` (`pk_match_sse_service.dart:28`) | MISMATCH (iki DB'nin paylaşılıp paylaşılmadığı doğrulanamadı) |
| 32 | PK aktif liste | `/api/pk/active` iki host'ta da `200 {"matches":[]}` | games host'a gidiyor | MISMATCH riski |
| 33 | Oda arka plan olayı | Sohbet SSE'si arka plan olayı yaymıyor; alan adı `backgroundImage` | `backgroundImageUrl`/`backgroundUrl` bekleniyor (`chat_room_providers.dart:1119`) | MISMATCH |
| 34 | Hediye süresi | `durationMs` yoksa 3000 (`lib/gift-engine.ts:92–96`) | Overlay `durationMs` ile kapanır; video süresi yok sayılır (`gift_engine_overlay.dart:83–103`) | MISMATCH |

## 3. MISSING
| Rota | Flutter | Not |
|---|---|---|
| `GET /api/admin/live-stats` | `mobile/lib/features/admin/data/admin_remote_datasource.dart:103` | Repo `full-source`'ta yok; üretim `401` dönüyor → **repo/üretim sapması** |

## 4. Tam eşleme matrisi
| Backend rota | Metot | Flutter (ilk konum) | Çağrı | Backend auth | Durum |
|---|---|---|---|---|---|
| `/api/activities` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:334` | 1 | JWT | PASS (kod) |
| `/api/admin/activity-feed` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:334` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/cfc-arena` | GET | `mobile/lib/features/cfc_arena/data/cfc_arena_repository.dart:24` | 1 | JWT | PASS (kod) |
| `/api/admin/cfc-arena` | POST | `mobile/lib/features/cfc_arena/data/cfc_arena_repository.dart:29` | 1 | JWT | PASS (kod) |
| `/api/admin/cfc-settings` | GET | `mobile/lib/features/admin/presentation/providers/admin_providers.dart:172` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/chat/rooms/create-for-user` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:618` | 1 | JWT | PASS (kod) |
| `/api/admin/credits` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:208` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/finance` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:393` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/gifts` | GET | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:48` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/gifts` | POST | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:96` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/gifts/[giftId]` | DELETE | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:153` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/gifts/[giftId]` | PATCH | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:133` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/gifts/stats` | GET | `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:163` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/live-tellers` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:507` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/live-tellers` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:539` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/live-tellers/[tellerId]/approve` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:568` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/membership-features` | GET | `mobile/lib/features/admin/presentation/pages/admin_membership_management_page.dart:44` | 1 | JWT | PASS (kod) |
| `/api/admin/membership-features` | PUT | `mobile/lib/features/admin/presentation/pages/admin_membership_management_page.dart:73` | 1 | JWT | PASS (kod) |
| `/api/admin/membership-tiers` | GET | `mobile/lib/features/admin/presentation/pages/admin_membership_management_page.dart:42` | 1 | JWT | PASS (kod) |
| `/api/admin/membership-tiers` | PUT | `mobile/lib/features/admin/presentation/pages/admin_membership_management_page.dart:105` | 1 | JWT | PASS (kod) |
| `/api/admin/notifications` | GET | `mobile/lib/features/admin/presentation/providers/admin_providers.dart:110` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/payment-notifications` | GET | `mobile/lib/features/admin/presentation/providers/admin_providers.dart:123` | 1 | JWT | PASS (kod) |
| `/api/admin/payment-notifications` | POST | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:755` | 1 | JWT | PASS (kod) |
| `/api/admin/payment-requests/dismiss-pending` | POST | `mobile/lib/features/admin/presentation/pages/admin_hub_page.dart:286` | 1 | JWT | PASS (kod) |
| `/api/admin/platform-analytics` | GET | `mobile/lib/features/admin/presentation/providers/admin_advanced_reporting_providers.dart:130` | 1 | JWT | PASS (kod) |
| `/api/admin/site-animations` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:27` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:63` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/[id]` | PATCH | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:84` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/assign` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:237` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/bulk-assign` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:272` | 1 | WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/defaults` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:111` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/defaults` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:145` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/exit-defaults` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:165` | 1 | WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/exit-defaults` | POST | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:191` | 1 | WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/stats` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:46` | 1 | ALIAS->WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/site-animations/user/[userId]` | GET | `mobile/lib/features/admin/data/admin_site_animation_remote_datasource.dart:213` | 1 | WEB-SESSION(lib:animation-admin) | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/statistics` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:87` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/users/[userId]` | GET | `mobile/lib/features/admin/presentation/providers/admin_bulk_operations_providers.dart:38` | 14 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/users/[userId]` | PATCH | `mobile/lib/features/admin/data/admin_remote_datasource.dart:133` | 3 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/users/[userId]/360` | GET | `mobile/lib/features/admin/presentation/providers/admin_user_hub_providers.dart:11` | 3 | JWT | PASS (kod) |
| `/api/admin/users/search` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:40` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/users/withdrawal-limit` | POST | `mobile/lib/features/admin/data/admin_remote_datasource.dart:583` | 1 | WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/voice-room-backgrounds` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:722` | 1 | ALIAS->WEB-SESSION-ONLY | MISMATCH (yalnız web oturumu; mobil JWT → 401/403) |
| `/api/admin/voice-room-finance-audit` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:418` | 1 | JWT | PASS (kod) |
| `/api/admin/voice-room-settings` | GET | `mobile/lib/features/admin/presentation/providers/admin_voice_room_providers.dart:16` | 1 | JWT | PASS (kod) |
| `/api/admin/voice-room-settings` | POST | `mobile/lib/features/admin/presentation/providers/admin_voice_room_providers.dart:40` | 1 | JWT | PASS (kod) |
| `/api/admin/withdrawals` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:371` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/ads/active` | GET | `mobile/lib/features/platform/data/datasources/platform_content_remote_datasource.dart:31` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/ads/reward` | POST | `mobile/lib/features/platform/data/datasources/platform_content_remote_datasource.dart:49` | 1 | JWT | PASS (kod) |
| `/api/advisors/online` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:69` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/agency/apply` | POST | `mobile/lib/features/agency/data/datasources/agency_remote_datasource.dart:37` | 1 | JWT | PASS (kod) |
| `/api/agency/earnings` | GET | `mobile/lib/features/shell/data/role_panel_resolver.dart:142` | 2 | JWT | PASS (kod) |
| `/api/agency/invite` | POST | `mobile/lib/features/agency/data/datasources/agency_remote_datasource.dart:182` | 1 | JWT | PASS (kod) |
| `/api/agency/invite-earnings` | GET | `mobile/lib/core/economy/data/referral_economy_remote_datasource.dart:47` | 1 | JWT | PASS (kod) |
| `/api/agency/invites` | GET | `mobile/lib/features/agency/presentation/pages/agency_invites_page.dart:39` | 1 | JWT | PASS (kod) |
| `/api/agency/invites` | POST | `mobile/lib/features/agency/presentation/pages/agency_invites_page.dart:63` | 1 | JWT | PASS (kod) |
| `/api/agency/leaderboard` | GET | `mobile/lib/features/agency/data/datasources/agency_remote_datasource.dart:89` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/agency/leave` | POST | `mobile/lib/features/agency/data/datasources/agency_remote_datasource.dart:165` | 1 | JWT | PASS (kod) |
| `/api/agency/live-status` | GET | `mobile/lib/features/agency/presentation/providers/agency_presence_provider.dart:11` | 1 | JWT | PASS (kod) |
| `/api/agency/members` | GET | `mobile/lib/features/shell/data/role_panel_resolver.dart:142` | 3 | JWT | PASS (kod) |
| `/api/agency/my` | GET | `mobile/lib/features/agency/data/datasources/agency_remote_datasource.dart:16` | 1 | JWT | PASS (kod) |
| `/api/agency/tasks` | GET | `mobile/lib/features/shell/data/role_panel_resolver.dart:142` | 2 | JWT | PASS (kod) |
| `/api/agency/wallet` | GET | `mobile/lib/features/agency/data/datasources/agency_wallet_datasource.dart:56` | 1 | JWT | PASS (kod) |
| `/api/agency/wallet/transfer` | POST | `mobile/lib/features/agency/data/datasources/agency_wallet_datasource.dart:74` | 1 | JWT | PASS (kod) |
| `/api/animations/manifest` | GET | `mobile/lib/core/animations/animations_repository.dart:84` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/animations/resolve` | GET | `mobile/lib/core/animations/animations_repository.dart:50` | 1 | JWT | PASS (kod) |
| `/api/auth/change-password` | POST | `mobile/lib/features/auth/data/datasources/auth_service.dart:157` | 2 | JWT | PASS (kod) |
| `/api/auth/email/send-verification` | POST | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:38` | 3 | JWT | PASS (kod) |
| `/api/auth/email/verify` | POST | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:48` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/auth/forgot-password` | POST | `mobile/lib/features/auth/data/datasources/auth_service.dart:243` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/auth/logout` | POST | `mobile/lib/features/auth/data/datasources/auth_service.dart:266` | 1 | JWT | PASS (kod) |
| `/api/auth/logout-all` | POST | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:87` | 1 | JWT | PASS (kod) |
| `/api/auth/mobile-sessions/[id]` | DELETE | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:80` | 1 | JWT | PASS (kod) |
| `/api/auth/phone/send-otp` | POST | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:212` | 1 | JWT | PASS (kod) |
| `/api/auth/phone/verify-otp` | POST | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:221` | 1 | JWT | PASS (kod) |
| `/api/auth/reset-password` | POST | `mobile/lib/features/auth/data/datasources/auth_service.dart:254` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/auth/sessions` | DELETE | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:69` | 1 | JWT | PASS (kod) |
| `/api/bana-ozel` | GET | `mobile/lib/features/bana_ozel/data/datasources/bana_ozel_remote_datasource.dart:16` | 1 | JWT | PASS (kod) |
| `/api/blog` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:144` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/blog/recent` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:144` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/celebrities` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:163` | 1 | JWT | PASS (kod) |
| `/api/cfc-arena` | GET | `mobile/lib/features/cfc_arena/data/cfc_arena_repository.dart:19` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/cfc-arena/[contestId]` | GET | `mobile/lib/features/cfc_arena/data/cfc_arena_repository.dart:34` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/cfc-arena/join` | POST | `mobile/lib/features/cfc_arena/presentation/pages/cfc_arena_contest_page.dart:144` | 2 | JWT | PASS (kod) |
| `/api/chat/music/popular` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1109` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms` | GET | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:254` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/background` | PATCH | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1296` | 1 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/banned-words` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2705` | 1 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/banned-words` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2723` | 1 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/banned-words/[word]` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2743` | 1 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/bans/[userId]` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1521` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/bans/[userId]` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1496` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/dj` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2575` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/dj/[targetUserId]` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2679` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/dj/[targetUserId]` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2631` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/gifts` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart:215` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/gifts` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_gifts_remote_datasource.dart:121` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/kick` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1566` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/mentions` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2879` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/messages` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1470` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/messages` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:306` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/messages` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2811` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/moderation` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:783` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/moderation` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1392` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/moderation/violations` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1232` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/music` | DELETE | `mobile/lib/features/voice_hub/music/data/datasources/room_song_remote_datasource.dart:97` | 6 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/music` | GET | `mobile/lib/features/voice_hub/music/data/datasources/room_song_remote_datasource.dart:13` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/music` | POST | `mobile/lib/features/voice_hub/music/data/datasources/room_music_remote_datasource.dart:243` | 4 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/music-queue` | GET | `mobile/lib/features/voice_hub/music/data/datasources/room_music_remote_datasource.dart:233` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/music-request-by-query` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2336` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/music-settings` | PATCH | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1058` | 1 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/music/stop` | POST | `mobile/lib/features/voice_hub/music/data/datasources/room_music_remote_datasource.dart:284` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/mute` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1541` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/pk` | GET | `mobile/lib/features/voice_hub/data/pk_room_api.dart:35` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/pk` | POST | `mobile/lib/features/voice_hub/data/pk_room_api.dart:59` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/pk/support` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1194` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/presence` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:641` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/presence` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:420` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/presence` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:118` | 4 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/queue` | GET | `mobile/lib/features/voice_hub/music/data/datasources/room_song_remote_datasource.dart:32` | 1 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/report` | POST | `mobile/lib/features/moderation/data/datasources/moderation_remote_datasource.dart:54` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/roles` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1644` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/seats` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:484` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/seats` | PATCH | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2462` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/settings` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1249` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/settings` | PATCH | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1008` | 5 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/song-request` | PATCH | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1021` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/song-request` | POST | `mobile/lib/features/voice_hub/music/data/datasources/room_song_remote_datasource.dart:90` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/song/[queueId]` | DELETE | `mobile/lib/features/voice_hub/music/data/datasources/room_song_remote_datasource.dart:109` | 2 | JWT(lib:chat-banned-words) | PASS (kod) |
| `/api/chat/rooms/[roomId]/speak-request` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1314` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/speak-request` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1305` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/speak-requests` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1324` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]` | DELETE | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1356` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1342` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/state` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:462` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/transfer-ownership` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1428` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/typing` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:767` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/typing` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:755` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/voice` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:738` | 1 | JWT | PASS (kod) |
| `/api/chat/rooms/[roomId]/voice` | POST | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:676` | 2 | JWT | PASS (kod) |
| `/api/chat/rooms/backgrounds` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:886` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/pk-list` | GET | `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart:471` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/chat/rooms/pk/candidates` | GET | `mobile/lib/features/pk/data/pk_service.dart:172` | 1 | JWT | PASS (kod) |
| `/api/chat/youtube-stream` | GET | `mobile/lib/features/voice_hub/music/data/datasources/room_music_remote_datasource.dart:66` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/compatibility` | POST | `mobile/lib/features/astrology/data/astrology_remote_datasource.dart:20` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/currency-branding` | GET | `mobile/lib/core/economy/data/currency_branding_remote_datasource.dart:15` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/daily-login` | POST | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:79` | 1 | JWT | PASS (kod) |
| `/api/daily-missions` | GET | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:20` | 2 | JWT | PASS (kod) |
| `/api/daily-missions` | POST | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:43` | 1 | JWT | PASS (kod) |
| `/api/dream-contest` | GET | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:16` | 1 | JWT | PASS (kod) |
| `/api/dream-contest/[contestId]/entries` | GET | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:27` | 1 | JWT | PASS (kod) |
| `/api/dream-contest/[contestId]/entries` | POST | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:38` | 1 | JWT | PASS (kod) |
| `/api/dream-contest/[contestId]/vote` | POST | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:49` | 1 | JWT | PASS (kod) |
| `/api/dreams/[slug]/favorite` | GET | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:75` | 1 | JWT | PASS (kod) |
| `/api/dreams/[slug]/favorite` | POST | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:83` | 1 | JWT | PASS (kod) |
| `/api/dreams/[slug]/view` | POST | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:94` | 1 | JWT | PASS (kod) |
| `/api/dreams/favorites` | GET | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:57` | 1 | JWT | PASS (kod) |
| `/api/dreams/interpret` | POST | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:67` | 1 | JWT | PASS (kod) |
| `/api/dreams/recommendations` | GET | `mobile/lib/features/dreams/data/datasources/dreams_abacus_remote_datasource.dart:62` | 1 | JWT | PASS (kod) |
| `/api/fan-clubs` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:187` | 2 | JWT | PASS (kod) |
| `/api/fan-clubs/popular` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:187` | 2 | ALIAS->JWT | PASS (kod) |
| `/api/favorite-tellers` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:420` | 1 | JWT | PASS (kod) |
| `/api/favorite-tellers` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:454` | 1 | JWT | PASS (kod) |
| `/api/football` | GET | `mobile/lib/features/football/data/football_remote_datasource.dart:20` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-access/check` | POST | `mobile/lib/features/fortune/data/datasources/fortune_access_remote_datasource.dart:36` | 2 | JWT | PASS (kod) |
| `/api/fortune-access/ip-status` | GET | `mobile/lib/features/fortune/data/datasources/fortune_access_remote_datasource.dart:20` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-access/settings` | GET | `mobile/lib/features/fortune/data/datasources/fortune_access_remote_datasource.dart:20` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-request-types` | GET | `mobile/lib/features/platform/data/datasources/platform_content_remote_datasource.dart:63` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-tellers` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:43` | 3 | JWT | PASS (kod) |
| `/api/fortune-tellers/[tellerId]` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:124` | 1 | JWT | PASS (kod) |
| `/api/fortune-tellers/[tellerId]/reviews` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:300` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-tellers/[tellerId]/session` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:493` | 1 | JWT | PASS (kod) |
| `/api/fortune-tellers/apply` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:202` | 1 | JWT | PASS (kod) |
| `/api/fortune-tellers/awards` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:330` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-tellers/gifts` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:360` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/fortune-tellers/my-profile` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:142` | 2 | JWT | PASS (kod) |
| `/api/fortune-tellers/session` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:535` | 4 | JWT | PASS (kod) |
| `/api/fortune-tellers/session` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:507` | 1 | JWT | PASS (kod) |
| `/api/fortune-tellers/sessions/[sessionId]` | PATCH | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:724` | 2 | JWT | PASS (kod) |
| `/api/fortune-tellers/sessions/stream` | GET | `mobile/lib/features/debug/presentation/pages/cf_diagnostics_page.dart:159` | 2 | JWT | PASS (kod) |
| `/api/fortune-tellers/toggle-online` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:180` | 1 | JWT | PASS (kod) |
| `/api/fortune-tellers/toggle-online` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:168` | 1 | JWT | PASS (kod) |
| `/api/fortunes/tarot-fali` | POST | `mobile/lib/features/fortune/data/services/fortune_sse_service.dart:112` | 1 | JWT | PASS (kod) |
| `/api/games` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:91` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/games/daily-reward` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:223` | 1 | JWT | PASS (kod) |
| `/api/games/daily-reward` | POST | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:79` | 1 | JWT | PASS (kod) |
| `/api/games/leaderboard` | GET | `mobile/lib/features/games/data/game_remote_datasource.dart:194` | 1 | JWT | PASS (kod) |
| `/api/games/play` | POST | `mobile/lib/features/games/data/game_remote_datasource.dart:124` | 2 | JWT | PASS (kod) |
| `/api/games/profile` | GET | `mobile/lib/features/games/data/game_remote_datasource.dart:221` | 1 | JWT | PASS (kod) |
| `/api/games/room/[roomId]` | GET | `mobile/lib/features/games/data/game_remote_datasource.dart:119` | 1 | JWT | PASS (kod) |
| `/api/games/room/[roomId]` | POST | `mobile/lib/features/games/data/game_remote_datasource.dart:120` | 1 | JWT | PASS (kod) |
| `/api/games/room/[roomId]/chat` | POST | `mobile/lib/features/games/data/game_remote_datasource.dart:185` | 1 | JWT | PASS (kod) |
| `/api/games/rooms` | GET | `mobile/lib/features/games/data/game_remote_datasource.dart:23` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/battles` | GET | `mobile/lib/features/gifts/data/gift_battle_remote_datasource.dart:78` | 1 | JWT | PASS (kod) |
| `/api/gifts/battles` | POST | `mobile/lib/features/gifts/data/gift_battle_remote_datasource.dart:59` | 1 | JWT | PASS (kod) |
| `/api/gifts/battles/[battleId]` | GET | `mobile/lib/features/gifts/data/gift_battle_remote_datasource.dart:93` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/catalog` | GET | `mobile/lib/features/gifts/data/lucky_gift_remote_datasource.dart:101` | 1 | JWT | PASS (kod) |
| `/api/gifts/check-reciprocal` | POST | `mobile/lib/features/gifts/data/gift_repository.dart:188` | 2 | JWT | PASS (kod) |
| `/api/gifts/display-settings` | GET | `mobile/lib/features/gifts/presentation/providers/gift_display_settings_provider.dart:18` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/goals` | GET | `mobile/lib/features/gifts/data/gift_goal_remote_datasource.dart:46` | 1 | JWT | PASS (kod) |
| `/api/gifts/goals` | POST | `mobile/lib/features/gifts/data/gift_goal_remote_datasource.dart:25` | 1 | JWT | PASS (kod) |
| `/api/gifts/insights/album/[userId]` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:94` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/badge/[userId]` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:76` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/collection/[userId]` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:85` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/feed` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:119` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/first-gifter/[context]/[contextId]` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:105` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/leaderboard` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:29` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/map` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:146` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/insights/me/badge` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:76` | 1 | JWT | PASS (kod) |
| `/api/gifts/insights/me/history` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:228` | 1 | JWT | PASS (kod) |
| `/api/gifts/insights/me/recommendations` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:157` | 1 | JWT | PASS (kod) |
| `/api/gifts/lucky/config` | GET | `mobile/lib/features/gifts/data/lucky_gift_remote_datasource.dart:17` | 1 | JWT | PASS (kod) |
| `/api/gifts/lucky/history` | GET | `mobile/lib/features/gifts/data/lucky_gift_remote_datasource.dart:52` | 1 | JWT | PASS (kod) |
| `/api/gifts/lucky/send` | POST | `mobile/lib/features/gifts/data/lucky_gift_remote_datasource.dart:31` | 1 | JWT | PASS (kod) |
| `/api/gifts/missions` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:178` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/missions/[missionId]/claim` | POST | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:253` | 1 | JWT | PASS (kod) |
| `/api/gifts/missions/me` | GET | `mobile/lib/features/gifts/data/gift_insights_remote_datasource.dart:182` | 1 | JWT | PASS (kod) |
| `/api/gifts/recent-big` | GET | `mobile/lib/features/gifts/data/gift_repository.dart:200` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/send` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:1004` | 1 | JWT | PASS (kod) |
| `/api/gifts/types` | GET | `mobile/lib/features/gifts/data/gift_repository.dart:147` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/gifts/version` | GET | `mobile/lib/features/gifts/data/lucky_gift_remote_datasource.dart:90` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/hashtags/[name]` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:268` | 1 | JWT | PASS (kod) |
| `/api/hashtags/search` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:273` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/hashtags/trending` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:281` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/homepage-buttons` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:107` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/homepage-fortune-cards` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:807` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/homepage-ticker` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:52` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/horoscope/daily` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:205` | 1 | JWT | PASS (kod) |
| `/api/jeton` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:849` | 1 | JWT | PASS (kod) |
| `/api/jeton` | POST | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:57` | 1 | JWT | PASS (kod) |
| `/api/leaderboards` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:353` | 2 | JWT | PASS (kod) |
| `/api/leaderboards/top100` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:116` | 1 | JWT | PASS (kod) |
| `/api/live/create-room` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_room_lifecycle_api.dart:22` | 1 | JWT | PASS (kod) |
| `/api/live/fal-request/[requestId]/complete` | POST | `mobile/lib/features/live/data/datasources/live_fortune_request_datasource.dart:173` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/live/fal-request/[requestId]/update` | POST | `mobile/lib/features/live/data/datasources/live_fortune_request_datasource.dart:154` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/live/fal-requests` | GET | `mobile/lib/features/live/data/datasources/live_fortune_request_datasource.dart:50` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/live/gift-types` | GET | `mobile/lib/features/live/data/datasources/live_field/live_field_gift_api.dart:19` | 1 | JWT | PASS (kod) |
| `/api/live/gift/send` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_gift_api.dart:51` | 1 | JWT | PASS (kod) |
| `/api/live/guest` | GET | `mobile/lib/features/live/data/datasources/live_api_remote_datasource.dart:34` | 2 | JWT | PASS (kod) |
| `/api/live/guest` | POST | `mobile/lib/features/live/data/datasources/live_api_remote_datasource.dart:57` | 2 | JWT | PASS (kod) |
| `/api/live/guest/list` | GET | `mobile/lib/features/live/data/datasources/live_api_remote_datasource.dart:74` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/live/heartbeat` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_room_lifecycle_api.dart:80` | 2 | JWT | PASS (kod) |
| `/api/live/join-room` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_room_lifecycle_api.dart:48` | 2 | JWT | PASS (kod) |
| `/api/live/leave-room` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_room_lifecycle_api.dart:70` | 2 | JWT | PASS (kod) |
| `/api/live/message` | GET | `mobile/lib/features/live/data/datasources/live_field/live_field_message_api.dart:39` | 1 | JWT | PASS (kod) |
| `/api/live/message` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_message_api.dart:18` | 1 | JWT | PASS (kod) |
| `/api/live/online-users` | GET | `mobile/lib/features/live/data/datasources/live_field/live_field_online_users_api.dart:18` | 1 | JWT | PASS (kod) |
| `/api/live/pk` | GET | `mobile/lib/features/pk/data/pk_service.dart:36` | 2 | JWT | PASS (kod) |
| `/api/live/pk` | POST | `mobile/lib/features/pk/data/pk_service.dart:72` | 4 | JWT | PASS (kod) |
| `/api/live/pk/active` | GET | `mobile/lib/features/live/data/pk/pk_room_remote_datasource.dart:188` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/live/rooms` | GET | `mobile/lib/features/live/data/datasources/live_field/live_field_room_discovery_api.dart:21` | 1 | JWT | PASS (kod) |
| `/api/live/rooms/[roomId]/join-request` | GET | `mobile/lib/features/vip_gold/data/room_access_remote_datasource.dart:100` | 2 | JWT | PASS (kod) |
| `/api/live/rooms/[roomId]/join-request` | POST | `mobile/lib/features/vip_gold/data/room_access_remote_datasource.dart:72` | 1 | JWT | PASS (kod) |
| `/api/live/rooms/[roomId]/join-request/[requestId]/approve` | POST | `mobile/lib/features/vip_gold/data/room_access_remote_datasource.dart:153` | 1 | JWT | PASS (kod) |
| `/api/live/rooms/[roomId]/join-request/[requestId]/reject` | POST | `mobile/lib/features/vip_gold/data/room_access_remote_datasource.dart:153` | 1 | JWT | PASS (kod) |
| `/api/live/rooms/[roomId]/verify-password` | GET | `mobile/lib/features/vip_gold/data/room_access_remote_datasource.dart:19` | 1 | JWT | PASS (kod) |
| `/api/live/rooms/[roomId]/verify-password` | POST | `mobile/lib/features/vip_gold/data/room_access_remote_datasource.dart:43` | 1 | JWT | PASS (kod) |
| `/api/live/seats` | GET | `mobile/lib/features/live/data/datasources/live_field/live_field_seats_api.dart:33` | 1 | JWT | PASS (kod) |
| `/api/live/seats` | POST | `mobile/lib/features/live/data/datasources/live_field/live_field_seats_api.dart:20` | 1 | JWT | PASS (kod) |
| `/api/me` | GET | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:88` | 6 | JWT | PASS (kod) |
| `/api/me/admin-capabilities` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:97` | 1 | JWT | PASS (kod) |
| `/api/me/membership` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:14` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/membership-events` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:19` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/membership-history` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:24` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/membership-history` | PUT | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:69` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/profile-visitors` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:77` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/profile-visitors` | POST | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:88` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/vip-identity` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:44` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/vip-identity` | PUT | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:49` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/vip-preferences` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:29` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/vip-preferences` | PUT | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:36` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/vip-xp` | GET | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:57` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/me/vip-xp` | POST | `mobile/lib/core/me/me_entitlements_remote_datasource.dart:62` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/membership-badges` | GET | `mobile/lib/features/cosmetics/data/cosmetics_remote_datasource.dart:27` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/membership/plans` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:79` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/membership/purchase` | POST | `mobile/lib/features/membership/data/membership_remote_datasource.dart:62` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/memberships` | GET | `mobile/lib/features/membership/data/membership_remote_datasource.dart:25` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/memberships/comparison` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:87` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/memberships/gift` | POST | `mobile/lib/features/web_parity/data/parity_api.dart:98` | 1 | JWT | PASS (kod) |
| `/api/memberships/packages` | GET | `mobile/lib/features/membership/data/membership_remote_datasource.dart:25` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/memberships/purchase` | POST | `mobile/lib/features/membership/data/membership_remote_datasource.dart:62` | 1 | JWT | PASS (kod) |
| `/api/messages` | GET | `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart:124` | 3 | JWT | PASS (kod) |
| `/api/messages/[userId]` | GET | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:101` | 4 | JWT | PASS (kod) |
| `/api/messages/[userId]` | POST | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:216` | 3 | JWT | PASS (kod) |
| `/api/messages/[userId]/[messageId]` | DELETE | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:384` | 1 | JWT | PASS (kod) |
| `/api/messages/conversations/[peerId]/messages` | GET | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:101` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/messages/conversations/[peerId]/messages` | POST | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:226` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/messages/conversations/[peerId]/typing` | POST | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:368` | 1 | JWT | PASS (kod) |
| `/api/messages/request` | PATCH | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:336` | 1 | JWT | PASS (kod) |
| `/api/messages/request` | POST | `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:315` | 1 | JWT | PASS (kod) |
| `/api/mobile/config` | GET | `mobile/lib/core/config/mobile_config_remote_datasource.dart:19` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/mobile/fortune-menu` | GET | `mobile/lib/features/home/data/datasources/mobile_compound_remote_datasource.dart:57` | 1 | JWT | PASS (kod) |
| `/api/mobile/home` | GET | `mobile/lib/features/home/data/datasources/mobile_compound_remote_datasource.dart:33` | 1 | JWT | PASS (kod) |
| `/api/mobile/user-profile/[userId]` | GET | `mobile/lib/features/home/data/datasources/mobile_compound_remote_datasource.dart:78` | 1 | JWT | PASS (kod) |
| `/api/music/search` | GET | `mobile/lib/features/voice_hub/music/data/datasources/room_song_remote_datasource.dart:58` | 6 | JWT | PASS (kod) |
| `/api/notifications` | GET | `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart:16` | 3 | JWT | PASS (kod) |
| `/api/notifications` | POST | `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart:159` | 2 | JWT | PASS (kod) |
| `/api/notifications/[notificationId]/read` | PATCH | `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart:164` | 1 | JWT | PASS (kod) |
| `/api/notifications/payment` | DELETE | `mobile/lib/features/notifications/data/datasources/notifications_remote_datasource.dart:183` | 1 | JWT | PASS (kod) |
| `/api/notifications/test-push` | POST | `mobile/lib/features/notifications/presentation/pages/notification_diagnostics_page.dart:77` | 1 | JWT | PASS (kod) |
| `/api/payments/config` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:472` | 1 | JWT | PASS (kod) |
| `/api/payments/methods` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:498` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/payments/requests` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:804` | 1 | JWT | PASS (kod) |
| `/api/pk/[matchId]` | GET | `mobile/lib/features/live/data/pk/pk_room_remote_datasource.dart:177` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/pk/[matchId]/stream` | GET | `mobile/lib/features/live/data/pk/pk_room_remote_datasource.dart:253` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/pk/active` | GET | `mobile/lib/features/live/data/pk/pk_room_remote_datasource.dart:194` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/pk/leaderboard` | GET | `mobile/lib/features/live/data/pk/pk_room_remote_datasource.dart:210` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/pk/me/invites` | GET | `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart:774` | 2 | JWT | PASS (kod) |
| `/api/platform/commission-rate` | GET | `mobile/lib/features/wallet/data/wallet_remote_datasource_extended.dart:65` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/popups` | GET | `mobile/lib/features/platform/data/datasources/platform_content_remote_datasource.dart:18` | 1 | JWT | PASS (kod) |
| `/api/presence` | POST | `mobile/lib/core/network/user_presence_service.dart:14` | 2 | JWT | PASS (kod) |
| `/api/profile-frames` | GET | `mobile/lib/features/cosmetics/data/cosmetics_remote_datasource.dart:18` | 1 | JWT | PASS (kod) |
| `/api/referral/me` | GET | `mobile/lib/features/referral/data/datasources/referral_remote_datasource.dart:123` | 1 | ALIAS->JWT | PASS (kod) |
| `/api/referral/stats` | GET | `mobile/lib/features/referral/data/datasources/referral_remote_datasource.dart:123` | 1 | JWT | PASS (kod) |
| `/api/refunds` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:54` | 1 | JWT | PASS (kod) |
| `/api/refunds` | POST | `mobile/lib/features/web_parity/data/parity_api.dart:68` | 1 | JWT | PASS (kod) |
| `/api/room/[sessionId]` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:880` | 1 | JWT | PASS (kod) |
| `/api/room/[sessionId]` | PATCH | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:922` | 1 | JWT | PASS (kod) |
| `/api/room/[sessionId]/messages` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:948` | 2 | JWT | PASS (kod) |
| `/api/room/[sessionId]/messages` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:967` | 1 | JWT | PASS (kod) |
| `/api/room/[sessionId]/review` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:408` | 1 | JWT | PASS (kod) |
| `/api/room/[sessionId]/stream` | GET | `mobile/lib/features/live_psychics/data/services/psychic_room_sse_service.dart:102` | 1 | JWT | PASS (kod) |
| `/api/room/[sessionId]/tip` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:1010` | 1 | JWT | PASS (kod) |
| `/api/room/signal` | POST | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:859` | 1 | JWT | PASS (kod) |
| `/api/search` | GET | `mobile/lib/features/search/data/datasources/search_remote_datasource.dart:43` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/share-card` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:257` | 1 | JWT | PASS (kod) |
| `/api/short-videos` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:278` | 2 | JWT | PASS (kod) |
| `/api/short-videos/[id]` | DELETE | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:672` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:405` | 2 | JWT | PASS (kod) |
| `/api/short-videos/[id]/comments` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:598` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/comments` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:615` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/comments/[commentId]` | DELETE | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:633` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/comments/[commentId]/like` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:640` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/comments/[commentId]/pin` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:873` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/duets` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:745` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/like` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:558` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/save` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:573` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/share` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:588` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/subtitles/generate` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:981` | 1 | JWT | PASS (kod) |
| `/api/short-videos/[id]/view` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:658` | 1 | JWT | PASS (kod) |
| `/api/short-videos/explore` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:290` | 3 | JWT | PASS (kod) |
| `/api/short-videos/hashtags/search` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:754` | 1 | ALIAS->NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/short-videos/hashtags/trending` | GET | `mobile/lib/features/voice_hub/data/datasources/voice_rooms_discover_remote_datasource.dart:119` | 2 | ALIAS->NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/short-videos/mentions/search` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:859` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/short-videos/music` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:795` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/short-videos/music/recommend` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:955` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/short-videos/profile/[userId]` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:693` | 1 | JWT | PASS (kod) |
| `/api/short-videos/register` | POST | `mobile/lib/features/shorts/data/services/short_video_upload_service.dart:134` | 2 | JWT | PASS (kod) |
| `/api/short-videos/upload` | POST | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:541` | 1 | JWT | PASS (kod) |
| `/api/short-videos/upload-url` | POST | `mobile/lib/features/shorts/data/services/short_video_upload_service.dart:68` | 2 | JWT | PASS (kod) |
| `/api/short-videos/user/[userId]` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:684` | 1 | JWT | PASS (kod) |
| `/api/short-videos/viewed/me` | GET | `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:736` | 1 | JWT | PASS (kod) |
| `/api/site-animations/active` | GET | `mobile/lib/core/site_animation/data/site_animation_catalog_datasource.dart:31` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/social/actions` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:62` | 1 | JWT | PASS (kod) |
| `/api/social/announcements` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:41` | 1 | ALIAS->JWT | PASS (kod) |
| `/api/social/discovery` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:46` | 1 | JWT | PASS (kod) |
| `/api/social/posts` | GET | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:33` | 1 | JWT | PASS (kod) |
| `/api/social/posts` | POST | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:147` | 2 | JWT | PASS (kod) |
| `/api/social/posts/[postId]` | DELETE | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:219` | 1 | JWT | PASS (kod) |
| `/api/social/posts/[postId]` | GET | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:110` | 1 | JWT | PASS (kod) |
| `/api/social/posts/[postId]/comments` | GET | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:249` | 1 | JWT | PASS (kod) |
| `/api/social/posts/[postId]/comments` | POST | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:260` | 1 | JWT | PASS (kod) |
| `/api/social/posts/[postId]/likes` | POST | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:232` | 1 | JWT | PASS (kod) |
| `/api/social/posts/[postId]/view` | POST | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:226` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/social/profile` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:246` | 1 | JWT | PASS (kod) |
| `/api/social/stories` | GET | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:354` | 1 | ALIAS->JWT | PASS (kod) |
| `/api/stories` | DELETE | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:339` | 1 | JWT | PASS (kod) |
| `/api/stories` | GET | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:347` | 1 | JWT | PASS (kod) |
| `/api/stories` | POST | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:327` | 1 | JWT | PASS (kod) |
| `/api/support/tickets` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:17` | 1 | JWT | PASS (kod) |
| `/api/support/tickets` | POST | `mobile/lib/features/web_parity/data/parity_api.dart:31` | 1 | JWT | PASS (kod) |
| `/api/support/tickets/[ticketId]` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:22` | 1 | JWT | PASS (kod) |
| `/api/support/tickets/[ticketId]` | PATCH | `mobile/lib/features/web_parity/data/parity_api.dart:46` | 1 | JWT | PASS (kod) |
| `/api/support/tickets/[ticketId]/messages` | POST | `mobile/lib/features/web_parity/data/parity_api.dart:39` | 1 | JWT | PASS (kod) |
| `/api/supporter-levels` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:147` | 2 | JWT | PASS (kod) |
| `/api/teams` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:286` | 1 | JWT | PASS (kod) |
| `/api/teams` | POST | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:296` | 1 | JWT | PASS (kod) |
| `/api/teams/[teamId]` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:291` | 1 | JWT | PASS (kod) |
| `/api/teams/[teamId]` | PATCH | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:304` | 1 | JWT | PASS (kod) |
| `/api/tournaments` | GET | `mobile/lib/features/games/data/game_remote_datasource.dart:230` | 1 | JWT | PASS (kod) |
| `/api/tournaments/join` | POST | `mobile/lib/features/games/data/game_remote_datasource.dart:242` | 1 | JWT | PASS (kod) |
| `/api/translations` | GET | `mobile/lib/features/platform/data/datasources/platform_content_remote_datasource.dart:107` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/trend-videos` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:304` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/trends` | GET | `mobile/lib/features/voice_hub/data/datasources/voice_rooms_discover_remote_datasource.dart:119` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/trtc/token` | POST | `mobile/lib/features/trtc/data/datasources/trtc_remote_datasource.dart:35` | 1 | JWT | PASS (kod) |
| `/api/trtc/usersig` | POST | `mobile/lib/features/trtc/data/datasources/trtc_remote_datasource.dart:89` | 1 | JWT | PASS (kod) |
| `/api/upload/get-url` | POST | `mobile/lib/features/shorts/presentation/utils/short_video_url_resolver.dart:56` | 2 | JWT | PASS (kod) |
| `/api/upload/presigned` | POST | `mobile/lib/features/profile/data/services/payment_receipt_upload_service.dart:20` | 4 | JWT | PASS (kod) |
| `/api/user/account/delete` | POST | `mobile/lib/features/profile/presentation/providers/account_privacy_providers.dart:72` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/user/achievements` | GET | `mobile/lib/features/profile/data/datasources/achievements_remote_datasource.dart:45` | 1 | JWT | PASS (kod) |
| `/api/user/active-sessions` | GET | `mobile/lib/features/live_psychics/data/repositories/live_psychics_remote_datasource.dart:623` | 2 | JWT | PASS (kod) |
| `/api/user/activity` | GET | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart:77` | 2 | JWT | PASS (kod) |
| `/api/user/activity` | PATCH | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart:109` | 2 | JWT | PASS (kod) |
| `/api/user/block` | GET | `mobile/lib/features/profile/presentation/providers/account_privacy_providers.dart:48` | 1 | JWT | PASS (kod) |
| `/api/user/block` | POST | `mobile/lib/features/profile/presentation/providers/account_privacy_providers.dart:60` | 2 | JWT | PASS (kod) |
| `/api/user/broadcast-history` | GET | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart:53` | 1 | JWT | PASS (kod) |
| `/api/user/co-broadcast-invites` | GET | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:381` | 1 | JWT | PASS (kod) |
| `/api/user/credits` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:869` | 1 | JWT | PASS (kod) |
| `/api/user/daily-tasks` | GET | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:20` | 1 | ALIAS->JWT | PASS (kod) |
| `/api/user/daily-tasks` | POST | `mobile/lib/features/profile/data/datasources/daily_tasks_remote_datasource.dart:43` | 1 | ALIAS->JWT | PASS (kod) |
| `/api/user/device-token` | DELETE | `mobile/lib/features/auth/data/datasources/auth_service.dart:359` | 2 | ALIAS->JWT | PASS (kod) |
| `/api/user/favorites` | GET | `mobile/lib/features/favorites/data/datasources/favorites_remote_datasource.dart:17` | 1 | JWT | PASS (kod) |
| `/api/user/favorites` | POST | `mobile/lib/features/favorites/data/datasources/favorites_remote_datasource.dart:33` | 1 | JWT | PASS (kod) |
| `/api/user/favorites/[favoriteId]` | DELETE | `mobile/lib/features/favorites/data/datasources/favorites_remote_datasource.dart:47` | 1 | JWT | PASS (kod) |
| `/api/user/fortunes` | GET | `mobile/lib/features/fortune/data/datasources/fortune_remote_datasource.dart:204` | 2 | JWT | PASS (kod) |
| `/api/user/location` | GET | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:144` | 1 | JWT | PASS (kod) |
| `/api/user/location` | POST | `mobile/lib/features/social/data/datasources/social_discovery_remote_datasource.dart:152` | 1 | JWT | PASS (kod) |
| `/api/user/profile` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:182` | 3 | JWT | PASS (kod) |
| `/api/user/referral-earnings` | GET | `mobile/lib/core/economy/data/referral_economy_remote_datasource.dart:20` | 1 | JWT | PASS (kod) |
| `/api/user/report` | POST | `mobile/lib/features/moderation/data/datasources/moderation_remote_datasource.dart:66` | 1 | JWT | PASS (kod) |
| `/api/user/statistics` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:200` | 1 | JWT | PASS (kod) |
| `/api/user/stats` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:200` | 1 | JWT | PASS (kod) |
| `/api/user/theme` | GET | `mobile/lib/core/theme/user_theme_remote_datasource.dart:16` | 1 | JWT | PASS (kod) |
| `/api/user/theme` | PATCH | `mobile/lib/core/theme/user_theme_remote_datasource.dart:38` | 1 | JWT | PASS (kod) |
| `/api/user/watch-ad` | POST | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:440` | 2 | JWT | PASS (kod) |
| `/api/user/xp` | GET | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:213` | 1 | JWT | PASS (kod) |
| `/api/users/[userId]` | GET | `mobile/lib/features/admin/presentation/providers/admin_user_detail_provider.dart:68` | 1 | JWT | PASS (kod) |
| `/api/users/[userId]/follow` | POST | `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:107` | 1 | JWT | PASS (kod) |
| `/api/users/[userId]/posts` | GET | `mobile/lib/features/social/data/datasources/social_remote_datasource.dart:52` | 1 | JWT | PASS (kod) |
| `/api/users/lookup/[username]` | GET | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart:23` | 1 | JWT | PASS (kod) |
| `/api/users/me/activity` | GET | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart:77` | 2 | ALIAS->JWT | PASS (kod) |
| `/api/users/me/broadcast-history` | GET | `mobile/lib/features/profile/data/datasources/canlifal_user_api_datasource.dart:53` | 1 | ALIAS->JWT | PASS (kod) |
| `/api/users/me/profile-visitors` | GET | `mobile/lib/features/profile/presentation/pages/profile_visitors_page.dart:64` | 2 | ALIAS->JWT(lib:vip-guard) | PASS (kod) |
| `/api/users/online` | GET | `mobile/lib/core/network/user_online_presence_provider.dart:52` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/users/search` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:40` | 2 | JWT | PASS (kod) |
| `/api/verification` | GET | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:229` | 1 | JWT | PASS (kod) |
| `/api/verification` | POST | `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:236` | 1 | JWT | PASS (kod) |
| `/api/video-streams` | GET | `mobile/lib/features/admin/presentation/providers/admin_live_broadcasts_providers.dart:14` | 3 | JWT | PASS (kod) |
| `/api/video-streams` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:722` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]` | GET | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:27` | 2 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]` | PATCH | `mobile/lib/features/admin/presentation/pages/admin_live_broadcasts_control_page.dart:56` | 5 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/auto-close` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:531` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/background` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:523` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/video-streams/[streamId]/ban` | DELETE | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:427` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/ban` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:417` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/co-broadcast` | GET | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:291` | 2 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/co-broadcast` | PATCH | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:339` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/co-broadcast` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:325` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/co-broadcast/invite` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:363` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/end` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:985` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/fortune-requests` | GET | `mobile/lib/features/live/data/datasources/live_fortune_request_datasource.dart:39` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/fortune-requests` | POST | `mobile/lib/features/live/data/datasources/live_fortune_request_datasource.dart:91` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/fortune-requests/my-status` | GET | `mobile/lib/features/live/data/datasources/live_fortune_request_datasource.dart:191` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/gifts` | GET | `mobile/lib/features/live/data/datasources/live_gifts_remote_datasource.dart:94` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/gifts` | POST | `mobile/lib/features/live/data/datasources/live_gifts_remote_datasource.dart:144` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/gifts/leaderboard` | GET | `mobile/lib/features/gifts/data/gift_repository.dart:155` | 2 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/video-streams/[streamId]/image` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:506` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/video-streams/[streamId]/join` | DELETE | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:621` | 2 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/join` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:601` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/leave` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:628` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/like` | GET | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:16` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/like` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:47` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/live-started` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:867` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/media-heartbeat` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:857` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/messages` | GET | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:637` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/messages` | POST | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:649` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/moderator` | DELETE | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:485` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/video-streams/[streamId]/moderator` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:469` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/video-streams/[streamId]/moderators` | DELETE | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:481` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/moderators` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:464` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/mute` | DELETE | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:453` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/mute` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:438` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/pk-battle` | GET | `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart:457` | 2 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/pk-battle` | POST | `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart:710` | 4 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/signal` | GET | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:193` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/signal` | POST | `mobile/lib/features/live/data/datasources/live_stream_extras_datasource.dart:207` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/stream` | GET | `mobile/lib/features/live/data/services/video_stream_sse_service.dart:153` | 1 | JWT | PASS (kod) |
| `/api/video-streams/[streamId]/viewers` | GET | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:908` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/video-streams/gifts` | GET | `mobile/lib/features/gifts/data/gift_repository.dart:55` | 2 | JWT | PASS (kod) |
| `/api/video-streams/pk` | GET | `mobile/lib/features/pk/data/pk_service.dart:63` | 4 | JWT | PASS (kod) |
| `/api/video-streams/pk` | POST | `mobile/lib/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart:710` | 4 | JWT | PASS (kod) |
| `/api/video-streams/pk/candidates` | GET | `mobile/lib/features/pk/data/pk_service.dart:158` | 2 | JWT | PASS (kod) |
| `/api/video-streams/pk/list` | GET | `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:91` | 1 | NONE | PASS* (public veya proxy; auth elle doğrulanmalı) |
| `/api/vip/leaderboard` | GET | `mobile/lib/features/web_parity/data/parity_api.dart:134` | 1 | JWT(lib:vip-guard) | PASS (kod) |
| `/api/wallet` | GET | `mobile/lib/features/home/data/datasources/home_remote_datasource.dart:869` | 1 | JWT | PASS (kod) |
| `/api/withdrawals` | GET | `mobile/lib/features/wallet/data/wallet_remote_datasource_extended.dart:17` | 1 | JWT | PASS (kod) |
| `/api/withdrawals` | POST | `mobile/lib/features/wallet/data/wallet_remote_datasource_extended.dart:42` | 1 | JWT | PASS (kod) |
| `/api/youtube/search` | GET | `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1821` | 1 | JWT | PASS (kod) |
| `/api/admin/live-stats` | GET | `mobile/lib/features/admin/data/admin_remote_datasource.dart:103` | 1 | — | MISSING (repo `full-source` dalında yok; üretimde 401 dönüyor → kaynak sapması) |


## 5. Statik çözülemeyen çağrılar (UNVERIFIED)

Yol çalışma zamanında hesaplanıyor; elle veya cihaz loglarıyla doğrulanmalı.

| Flutter konumu | Metot | Çözülemeyen yol ifadesi |
|---|---|---|
| `mobile/lib/features/admin/presentation/providers/admin_providers.dart:33` | GET | `path` |
| `mobile/lib/features/admin/presentation/pages/admin_user_command_center_extended_tabs.dart:17` | GET | `path` |
| `mobile/lib/features/admin/presentation/widgets/admin_user_finance_ledger_section.dart:25` | GET | `path` |
| `mobile/lib/features/admin/data/admin_remote_datasource.dart:307` | GET | `path` |
| `mobile/lib/features/admin/data/admin_remote_datasource.dart:646` | GET | `path` |
| `mobile/lib/features/admin/data/admin_remote_datasource.dart:681` | GET | `path` |
| `mobile/lib/features/admin/data/admin_remote_datasource.dart:694` | GET | `path` |
| `mobile/lib/features/admin/domain/admin_payment_review.dart:212` | PATCH | `path` |
| `mobile/lib/features/debug/presentation/pages/cf_diagnostics_page.dart:70` | GET | `path` |
| `mobile/lib/features/platform/data/datasources/platform_content_remote_datasource.dart:141` | GET | `path` |
| `mobile/lib/features/voice_hub/presentation/audio/voice_room_dj_stream_loader.dart:128` | DELETE | `` |
| `mobile/lib/features/voice_hub/presentation/sheets/voice_room_hub_settings.dart:67` | DELETE | `` |
| `mobile/lib/features/voice_hub/presentation/sheets/voice_room_hub_settings.dart:267` | DELETE | `` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:807` | GET | `endpoint` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1737` | GET | `q` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1751` | PUT | `q` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1783` | PUT | `q` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:1801` | PUT | `q` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2182` | POST | `usedEndpoint` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2185` | POST | `usedEndpoint` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2192` | POST | `usedEndpoint` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2199` | POST | `usedEndpoint` |
| `mobile/lib/features/voice_hub/data/datasources/chat_room_remote_datasource.dart:2202` | POST | `usedEndpoint` |
| `mobile/lib/features/profile/presentation/pages/profile_edit_page.dart:120` | DELETE | `` |
| `mobile/lib/features/profile/data/services/payment_receipt_upload_service.dart:57` | PUT | `uploadUrl` |
| `mobile/lib/features/profile/data/datasources/profile_remote_datasource.dart:585` | POST | `requestPath` |
| `mobile/lib/features/web_parity/data/parity_api.dart:161` | GET | `path` |
| `mobile/lib/features/web_parity/data/parity_api.dart:166` | GET | `path` |
| `mobile/lib/features/web_parity/data/parity_api.dart:171` | POST | `path` |
| `mobile/lib/features/web_parity/data/parity_api.dart:176` | POST | `path` |
| `mobile/lib/features/cosmetics/data/cosmetics_equip_remote_datasource.dart:77` | GET | `path` |
| `mobile/lib/features/cosmetics/data/cosmetics_equip_remote_datasource.dart:119` | POST | `path` |
| `mobile/lib/features/cosmetics/data/cosmetics_equip_remote_datasource.dart:125` | POST | `path` |
| `mobile/lib/features/cosmetics/data/cosmetics_equip_remote_datasource.dart:128` | POST | `path` |
| `mobile/lib/features/cosmetics/data/cosmetics_equip_remote_datasource.dart:136` | POST | `path` |
| `mobile/lib/features/gifts/data/admin_gift_remote_datasource.dart:292` | PUT | `uploadUrl` |
| `mobile/lib/features/gifts/data/gift_cache_service.dart:16` | GET | `url` |
| `mobile/lib/features/gifts/data/gift_cache_service.dart:28` | PUT | `url` |
| `mobile/lib/features/fortune/data/services/fortune_image_upload_service.dart:53` | PUT | `uploadUrl` |
| `mobile/lib/features/shorts/presentation/utils/short_studio_launch.dart:112` | PATCH | `(d) => d.copyWith(
            sourceLiveClipId: params.liveClipId,
            ` |
| `mobile/lib/features/shorts/presentation/utils/short_studio_launch.dart:130` | PATCH | `(d) => d.copyWith(sourcePath: localPath)` |
| `mobile/lib/features/shorts/presentation/utils/short_studio_launch.dart:147` | PATCH | `(d) => d.copyWith(
              duetOfId: videoId,
              sourceVideoTit` |
| `mobile/lib/features/shorts/presentation/utils/short_studio_launch.dart:154` | PATCH | `(d) => d.copyWith(
              remixOfId: videoId,
              musicId: vide` |
| `mobile/lib/features/shorts/presentation/utils/short_studio_launch.dart:166` | PATCH | `(d) => d.copyWith(
              replyToVideoId: videoId,
              sourceVi` |
| `mobile/lib/features/shorts/presentation/studio/studio_voiceover_sheet.dart:44` | PATCH | `(d) => d.copyWith(voiceoverPath: path)` |
| `mobile/lib/features/shorts/presentation/studio/shorts_studio_page.dart:292` | DELETE | `meta.id` |
| `mobile/lib/features/shorts/presentation/studio/studio_editor_page.dart:49` | PATCH | `(d) {
        final selected = d.thumbnailPath;
        return d.copyWith(
     ` |
| `mobile/lib/features/shorts/presentation/studio/studio_editor_page.dart:116` | PATCH | `(d) => d.copyWith(
              editedPath: outPath,
              thumbnailPat` |
| `mobile/lib/features/shorts/presentation/studio/studio_editor_page.dart:188` | PATCH | `(d) => d.copyWith(thumbnailPath: path)` |
| `mobile/lib/features/shorts/presentation/studio/studio_editor_page.dart:197` | PATCH | `(_) => d` |
| `mobile/lib/features/shorts/presentation/studio/studio_compose_page.dart:61` | PATCH | `(d) {
      return d.copyWith(
        textOverlays: [
          ...d.textOverla` |
| `mobile/lib/features/shorts/presentation/studio/studio_compose_page.dart:82` | PATCH | `(d) {
      return d.copyWith(
        stickerOverlays: [
          ...d.sticker` |
| `mobile/lib/features/shorts/presentation/studio/studio_compose_page.dart:104` | PATCH | `(d) {
      return d.copyWith(
        textOverlays: [
          for (final o in` |
| `mobile/lib/features/shorts/presentation/studio/studio_compose_page.dart:157` | PATCH | `(d) {
      return d.copyWith(
        textOverlays: [
          for (final o in` |
| `mobile/lib/features/shorts/presentation/studio/studio_compose_page.dart:225` | PATCH | `(d) {
                        return d.copyWith(
                          textO` |
| `mobile/lib/features/shorts/presentation/studio/studio_compose_page.dart:244` | PATCH | `(d) {
                        return d.copyWith(
                          stick` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:96` | PATCH | `(d) => d.copyWith(description: text)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:132` | PATCH | `(d) {
      if (d.mentionUserIds.contains(user.id)) return d;
      return d.cop` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:180` | PATCH | `(_) => draft` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:225` | PATCH | `(d) => d.copyWith(
              description: descNext.trim(),
              aiS` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:258` | PATCH | `(d) => d.copyWith(musicId: picked.id, musicTitle: picked.title)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:283` | PATCH | `(d) => d.copyWith(
              thumbnailCandidates: thumbs,
              thum` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:299` | PATCH | `(d) => d.copyWith(subtitlesSrt: srt)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:320` | PATCH | `(d) => d.copyWith(contentRating: picked)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:327` | PATCH | `(d) => d.copyWith(thumbnailPath: path)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:409` | PATCH | `(d) => d.copyWith(visibility: picked)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:429` | PATCH | `(d) => d.copyWith(commentSetting: picked)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:592` | PATCH | `(d) => d.copyWith(
                        musicId: picked.id,
                 ` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:632` | PATCH | `(d) => d.copyWith(locationLabel: label)` |
| `mobile/lib/features/shorts/presentation/studio/studio_publish_page.dart:662` | PATCH | `(d) => d.copyWith(allowDuet: v)` |
| `mobile/lib/features/shorts/presentation/studio/short_studio_providers.dart:29` | DELETE | `draftId` |
| `mobile/lib/features/shorts/data/short_upload_draft_store.dart:86` | DELETE | `recursive: true` |
| `mobile/lib/features/shorts/data/services/short_video_upload_service.dart:192` | PUT | `url` |
| `mobile/lib/features/shorts/data/datasources/shorts_remote_datasource.dart:427` | GET | `entry.path` |
| `mobile/lib/features/messages/presentation/services/dm_voice_note_service.dart:46` | DELETE | `` |
| `mobile/lib/features/messages/data/datasources/messages_remote_datasource.dart:26` | GET | `path` |
| `mobile/lib/features/feed/data/datasources/platform_stats_remote_datasource.dart:18` | GET | `path` |
| `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:422` | POST | `path` |
| `mobile/lib/features/live/data/datasources/live_remote_datasource.dart:553` | GET | `path` |
| `mobile/lib/features/trtc/presentation/trtc_live_room_coordinator.dart:117` | PUT | `cred` |
| `mobile/lib/features/trtc/presentation/trtc_live_room_coordinator.dart:197` | PUT | `cred` |
| `mobile/lib/features/games/data/game_remote_datasource.dart:51` | POST | `attempt.path` |
| `mobile/lib/features/games/data/game_remote_datasource.dart:84` | POST | `attempt.path` |
| `mobile/lib/features/games/data/game_remote_datasource.dart:105` | POST | `path` |
| `mobile/lib/features/games/data/game_remote_datasource.dart:169` | POST | `pathFn()` |
| `mobile/lib/core/sse_client.dart:322` | POST | `path` |
| `mobile/lib/core/sse_client.dart:516` | GET | `path` |
| `mobile/lib/core/auth/session_user_cache.dart:64` | DELETE | `key: _kCachedUser` |
| `mobile/lib/core/network/token_storage.dart:96` | DELETE | `key: _kAccess` |
| `mobile/lib/core/network/token_storage.dart:97` | DELETE | `key: _kRefresh` |
| `mobile/lib/core/network/token_storage.dart:98` | DELETE | `key: _kUserId` |
| `mobile/lib/core/network/lazy_cookie_jar.dart:66` | DELETE | `uri` |
| `mobile/lib/core/network/sse/base_sse_service.dart:173` | GET | `streamPath()` |
| `mobile/lib/core/media/cloud_upload_service.dart:64` | PUT | `uploadUrl` |
| `mobile/lib/core/economy/data/economy_wallet_remote_datasource.dart:35` | GET | `path` |
| `mobile/lib/core/storage/local_cache.dart:27` | PUT | `key` |
| `mobile/lib/core/storage/local_cache.dart:30` | GET | `key` |
| `mobile/lib/core/storage/local_cache.dart:33` | PUT | `key` |
| `mobile/lib/core/storage/local_cache.dart:37` | GET | `key` |
| `mobile/lib/core/push/push_registrar.dart:55` | POST | `path` |
