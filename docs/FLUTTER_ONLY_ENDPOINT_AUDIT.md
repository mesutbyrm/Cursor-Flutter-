# Flutter-only endpoint denetimi (MATCH / YEDEK / KALDIR)

> **Generated:** 2026-09-14 11:18 UTC (`scripts/generate_flutter_only_endpoint_audit.py`)

OpenAPI `backend-docs/openapi.json` ile **normalize eşleşmeyen** `mobile/lib` `/api/` literal’leri.
Kılavuz: `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (§9 mobil sözleşme, §10 opsiyonel/fallback).

## Özet

| Karar | Adet |
|-------|-----:|
| **MATCH** | 127 |
| **YEDEK** | 95 |
| **KALDIR** | 3 |
| **Toplam** | 225 |

- **MATCH:** Birincil üretim/kılavuz yolu (şablon farkı veya opsiyonel uç).
- **YEDEK:** Geriye dönük veya ikincil; kanonik uç başarısız olunca kullan.
- **KALDIR:** Ölü kod, log artefaktı veya yanlış auth prefix.

## Mobil hizalama (2026-09-14 parite — `1.0.490+528`)

| Alan | Birincil (OpenAPI/kılavuz) | Yedek |
|------|---------------------------|-------|
| Auth | `mobile-login/register/refresh`, `GET /api/me` | (legacy web auth kaldırıldı) |
| Push token | `POST /api/user/device-token` | `POST /api/auth/mobile/device-token` |
| Bildirim unread | `GET /api/notifications?unreadOnly=true` | `GET /api/messages?unreadCount=true` |
| Günlük ödül | `GET/POST /api/games/daily-reward` | `GET /api/mobile/home` gömülü |
| Fal jeton/CFC ön | `POST /api/fortune-access/check` | (consume kaldırıldı) |
| Popüler müzik | `GET /api/music/search` | `GET /api/chat/music/popular` |
| Turnuva katılım | `POST /api/tournaments` `{action:join}` | — |
| Cüzdan | `GET /api/wallet` | `GET /api/user/wallet` |
| Fal erişim ayar | `GET /api/fortune-access/ip-status` | `GET /api/fortune-access/settings` |
| Referral özet | `GET /api/referral` | `/api/referral/stats`, `/me` |
| Referral kazanç | `GET /api/user/referral-earnings` | `/api/referral/earnings` |
| İstatistik | `GET /api/user/stats` | `GET /api/user/statistics` |
| Hediyeler | `GET /api/user/received-gifts` | — |
| Site stats | `GET /api/public-stats` | — |
| Stories | `GET /api/stories` | `GET /api/social/stories` |
| Ana sayfa banner | `GET /api/mobile/home` | `GET /api/social/announcements` |

## Tam liste

| Flutter literal | Karar | Kanonik / hedef | Not |
|-----------------|-------|-----------------|-----|
| `/api/admin/` | **YEDEK** | (çoklu `/api/admin/*`) | Dinamik admin prefix; her çağrı ilgili OpenAPI admin path ile doğrulanmalı |
| `/api/admin/chat/rooms/create-for-user` | **YEDEK** | `/api/admin/chat-rooms` (benzer) | Mobil admin kolaylığı |
| `/api/admin/mobile-auth` | **YEDEK** | `/api/auth/mobile-*` | Admin oturum köprüsü |
| `/api/admin/payment-notifications` | **YEDEK** | `/api/admin/cfc-payment-requests` | Ödeme bildirimleri |
| `/api/admin/payment-requests` | **YEDEK** | `GET/PATCH /api/admin/cfc-payment-requests` | OpenAPI kanonik |
| `/api/admin/payment-requests/dismiss-pending` | **YEDEK** | `/api/admin/cfc-payment-requests` | PATCH ile birleştir |
| `/api/admin/payments/stream` | **YEDEK** | SSE admin ödeme | Web/admin SSE |
| `/api/admin/site-animations` | **YEDEK** | (web admin) | OpenAPI’de site-animations yok |
| `/api/admin/site-animations/assign` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/bulk-assign` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/defaults` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/exit-defaults` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/site-animations/stats` | **YEDEK** | (web admin) | Yerel katalog fallback |
| `/api/admin/users/credits` | **MATCH** | `/api/admin/users/{id}/credits` | Şablon farkı — normalize `{id}` |
| `/api/admin/users/grant-membership` | **YEDEK** | `/api/admin/memberships` | Admin üyelik |
| `/api/admin/users/stats` | **YEDEK** | `/api/admin/users` | Özet istatistik |
| `/api/admin/voice-room-backgrounds` | **YEDEK** | `/api/admin/voice-rooms` | Arka plan yönetimi |
| `/api/admin/voice-room-finance-audit` | **YEDEK** | `/api/admin/voice-room-finance` | Finans denetimi |
| `/api/admin/voice-room-settings` | **YEDEK** | `/api/platform/voice-room-settings` | Platform ayarı |
| `/api/ads/placement` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/advisors` | **MATCH** | `GET /api/advisors` | OpenAPI şablon farkı (literal prefix) |
| `/api/advisors/online` | **MATCH** | `GET /api/advisors/online` | Şablon |
| `/api/agency/applicant-score/[userId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/agency/growth` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/agency/invite-earnings` | **MATCH** | Kılavuz §10 opsiyonel | 404 → gizle |
| `/api/agency/live-status` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/agency/wallet` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/agency/wallet/transfer` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/animations/me` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/animations/resolve` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/auth/` | **KALDIR** | `/api/auth/mobile-*` | Eski web auth prefix — mobilde kullanılmamalı |
| `/api/auth/email/send-verification` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/auth/logout-all` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/auth/mobile-send-verification` | **YEDEK** | `POST /api/auth/mobile-verify-email` | Doğrulama akışı |
| `/api/auth/mobile-sessions` | **MATCH** | Kılavuz §9 Auth | Üretimde mobil oturumlar |
| `/api/auth/mobile-verify-email` | **MATCH** | Kılavuz §9 Auth | Üretim |
| `/api/auth/mobile/device-token` | **MATCH** | `POST /api/user/device-token` | Cihaz token alias |
| `/api/auth/phone/send-otp` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/auth/phone/verify-otp` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/auth/sessions` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/billing/app-store/verify` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/billing/google-play/verify` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/blog/recent` | **MATCH** | `GET /api/blog/recent` | Blog |
| `/api/celebrities` | **MATCH** | `GET /api/celebrities` | Keşfet |
| `/api/cfc-arena/join` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/chat/music/popular` | **MATCH** | `GET /api/chat/music/popular` | Müzik |
| `/api/chat/rooms/` | **MATCH** | `/api/chat/rooms/{id}/*` | Dinamik oda prefix |
| `/api/chat/rooms/[roomId]/gifts` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/messages` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/moderation` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/music` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/music-queue` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/music/stop` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/seats` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/settings` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/song-request` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/speak-request` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/speak-requests` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/state` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/stream` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/sync` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/typing` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/[roomId]/voice` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/chat/rooms/pk/candidates` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/currency-branding` | **MATCH** | Kılavuz §10 | OpenAPI’de olabilir; ekonomi v2 |
| `/api/dream-contest/[contestId]/entries` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/dream-contest/[contestId]/vote` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/dreams/[slug]/favorite` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/dreams/[slug]/view` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/fan-clubs` | **MATCH** | `GET /api/fan-clubs` | Fan kulüp |
| `/api/fan-clubs/popular` | **MATCH** | `GET /api/fan-clubs/popular` | Fan kulüp |
| `/api/fortune-access/settings` | **YEDEK** | `GET /api/fortune-access/ip-status` | Settings 404; ip-status kanonik |
| `/api/fortune-tellers/[tellerId]/session` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/fortune-tellers/sessions/[sessionId]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/games/history` | **MATCH** | `GET /api/games/history` | Oyun geçmişi |
| `/api/games/mini-scores` | **MATCH** | `GET /api/games/mini-scores` | Mini oyun |
| `/api/games/room/[roomId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/room/[roomId]/chat` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/room/[roomId]/replace-ai` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/room/[roomId]/viewers` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/sos/[gameId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/sos/[gameId]/chat` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/sos/[gameId]/viewers` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/games/sos/create` | **MATCH** | Kılavuz §10 korunan | SOS oluştur |
| `/api/gift-box` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/gift-box/[boxId]/join` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/gift-box/share` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/gifts/display-settings` | **MATCH** | `GET /api/gifts/display-settings` | Hediye UI |
| `/api/gifts/missions/[missionId]/claim` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/hashtags/[name]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/leaderboard` | **MATCH** | `GET /api/leaderboard` | Liderlik |
| `/api/leaderboards/top100` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/live` | **MATCH** | `/api/live/*` | Canlı prefix |
| `/api/live/fal-request/create` | **YEDEK** | `/api/video-streams/{id}/fortune-requests` | Legacy canlı fal |
| `/api/live/fal-requests` | **YEDEK** | `/api/video-streams/{id}/fortune-requests` | Legacy liste |
| `/api/me/admin-capabilities` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/membership` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/membership-events` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/membership-history` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/profile-visitors` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/vip-identity` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/vip-preferences` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/me/vip-xp` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/memberships/gift` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/messages/[userId]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/messages/conversations` | **MATCH** | `GET /api/messages/conversations` | DM |
| `/api/mobile/auth/web-session` | **YEDEK** | `/api/auth/mobile-*` | Web oturum köprüsü |
| `/api/mobile/user-profile/[userId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/notifications/payment` | **MATCH** | `GET /api/notifications/payment` | Ödeme bildirimi |
| `/api/payments/notifications/[notificationId]/dispute` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/pk` | **MATCH** | `/api/pk/*` (games host) | Router → games API |
| `/api/pk/` | **MATCH** | `/api/pk/*` | Router prefix |
| `/api/pk/admin/ban` | **YEDEK** | games PK admin | Games backend |
| `/api/pk/admin/bans` | **YEDEK** | games PK admin | Games backend |
| `/api/pk/history` | **YEDEK** | `GET /api/pk/me/history` | Şablon/host |
| `/api/pk/me/history` | **YEDEK** | games `/api/pk/me/history` | Ana host 404 |
| `/api/pk/me/matches` | **YEDEK** | games PK | Ana host 404 |
| `/api/pk/me/stats` | **YEDEK** | games PK | Ana host 404 |
| `/api/pk/request` | **MATCH** | `POST /api/pk/request` | PK davet |
| `/api/pk/room` | **MATCH** | `/api/pk/room` | PK oda |
| `/api/platform-stats` | **MATCH** | `GET /api/platform-stats` | İstatistik |
| `/api/platform/voice-room-settings` | **MATCH** | `GET /api/platform/voice-room-settings` | Sesli oda |
| `/api/referral/earnings` | **YEDEK** | `GET /api/referral` + `/api/user/referral-earnings` | OpenAPI yalnız `/api/referral` |
| `/api/referral/invite-link` | **YEDEK** | `GET /api/referral` | shareUrl alanı |
| `/api/referral/ledger` | **YEDEK** | `GET /api/user/referral-earnings` | Komisyon kalemleri |
| `/api/referral/me` | **YEDEK** | `GET /api/referral` | Birleşik yanıt |
| `/api/referral/settings` | **YEDEK** | `GET /api/referral` | Ayarlar gömülü |
| `/api/referral/stats` | **YEDEK** | `GET /api/referral` | OpenAPI kanonik |
| `/api/referral/users` | **YEDEK** | `GET /api/referral` | referrals[] gömülü |
| `/api/refunds` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/reports` | **MATCH** | `POST /api/reports` | Şikayet |
| `/api/room/[sessionId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/room/[sessionId]/messages` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/room/[sessionId]/review` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/room/[sessionId]/stream` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/room/[sessionId]/summary` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/room/[sessionId]/tip` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/short-videos/[id]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/comments` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/comments/[commentId]/like` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/comments/[commentId]/pin` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/duets` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/like` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/save` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/share` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/[id]/view` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/explore/nearby` | **MATCH** | `GET /api/short-videos/explore/nearby` | Keşfet |
| `/api/short-videos/hashtags/search` | **MATCH** | `GET .../search` | Hashtag |
| `/api/short-videos/hashtags/trending` | **MATCH** | `GET .../trending` | Hashtag |
| `/api/short-videos/live-clip` | **MATCH** | `POST /api/short-videos/live-clip` | Klip |
| `/api/short-videos/music/recommend` | **MATCH** | `GET .../recommend` | Müzik |
| `/api/short-videos/profile/[userId]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/recommend` | **MATCH** | `GET /api/short-videos/recommend` | Öneri |
| `/api/short-videos/suggest-metadata` | **MATCH** | `POST .../suggest-metadata` | Metadata |
| `/api/short-videos/user/[userId]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/short-videos/viewed/me` | **MATCH** | `GET .../viewed/me` | İzleme geçmişi |
| `/api/site-animations/active` | **YEDEK** | Yerel asset katalog | Üretim 404; fallback |
| `/api/social/actions` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/social/announcements` | **MATCH** | `GET /api/social/announcements` | Duyuru |
| `/api/social/discovery` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/social/posts/[postId]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/social/posts/[postId]/comments` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/social/posts/[postId]/likes` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/social/posts/auto-fortune` | **MATCH** | `POST .../auto-fortune` | Sosyal fal |
| `/api/social/profile` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/social/stories` | **MATCH** | `GET /api/social/stories` | Hikaye |
| `/api/support/tickets/[ticketId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/support/tickets/[ticketId]/messages` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/teams/[teamId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/teller-chat/[sessionId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/teller/gifts` | **MATCH** | `GET /api/teller/gifts` | Falcı hediye |
| `/api/teller/reviews` | **MATCH** | `GET /api/teller/reviews` | Yorum |
| `/api/trends/[slug]/like` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/user/[userId]/achievements` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/user/[userId]/follow` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/user/[userId]/follow-status` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/user/account` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/user/cosmetics` | **MATCH** | `GET /api/user/cosmetics` | Kozmetik |
| `/api/user/cosmetics/equip` | **MATCH** | `POST .../equip` | Kozmetik |
| `/api/user/cosmetics/loadout` | **MATCH** | `GET .../loadout` | Loadout |
| `/api/user/daily-tasks` | **MATCH** | `GET /api/user/daily-tasks` | Görevler |
| `/api/user/device-token` | **MATCH** | `POST /api/user/device-token` | FCM |
| `/api/user/favorites` | **MATCH** | `GET /api/user/favorites` | Favori |
| `/api/user/fortunes/[fortuneId]` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/user/location` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/user/profile/cosmetics/equip` | **YEDEK** | `/api/user/cosmetics/equip` | Alias |
| `/api/user/referral-earnings` | **MATCH** | Kılavuz §10 birincil (404→`/api/referral`) | Ekonomi ekranı |
| `/api/user/social-settings` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/user/story` | **MATCH** | `GET/POST /api/user/story` | Hikaye |
| `/api/user/wallet` | **YEDEK** | `GET /api/wallet` | Kılavuz §9/§10; OpenAPI kanonik wallet |
| `/api/users/[userId]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/users/[userId]/follow` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/users/[userId]/posts` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/users/lookup/[username]` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |
| `/api/users/me/activity` | **MATCH** | `GET /api/users/me/activity` | Aktivite |
| `/api/users/me/broadcast-history` | **MATCH** | `GET .../broadcast-history` | Yayın |
| `/api/users/me/profile-visitors` | **MATCH** | `GET .../profile-visitors` | Ziyaretçi |
| `/api/v1` | **KALDIR** | Yerel mirror / Invidious | Üretim API değil |
| `/api/v1/` | **KALDIR** | Yerel mirror | Üretim API değil |
| `/api/video` | **MATCH** | `/api/video/*` prefix | Video modülü |
| `/api/video-streams/[streamId]/auto-close` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/ban` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/co-broadcast` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/co-broadcast/invite` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/comments` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/fortune-requests` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/fortune-requests/my-status` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/gifts` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/join` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/leave` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/like` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/live-started` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/media-heartbeat` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/messages` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/moderators` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/mute` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/pk-battle` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/signal` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/stream` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/[streamId]/sync` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/video-streams/pk/candidates` | **MATCH** | Kılavuz §9 | Backtick referans; OpenAPI şablon farkı |
| `/api/vip/leaderboard` | **YEDEK** | (doğrula) | OpenAPI’de birebir yok — üretim probe gerekir |

## Komut

```bash
python3 scripts/generate_flutter_only_endpoint_audit.py
python3 scripts/generate_cross_source_parity_report.py
```
