# Uç Nokta Sınıflandırması (ENDPOINT CLASSIFICATION)

Bu dosya **canlı kaynak koddan** otomatik üretilmiştir (tarama tarihi: 2026-09-12, BÖLÜM 22 dahil).
Kaynak veri: `endpoint_classification.json` (makine tarafından okunabilir, aynı klasörde).

## Özet

| Sınıf | Rota dosyası | Açıklama |
|---|---:|---|
| `FLUTTER_READY` | 306 | Mobil JWT (Authorization: Bearer) kabul ediyor — Flutter doğrudan kullanabilir. |
| `PUBLIC` | 121 | Kimlik doğrulaması gerektirmez — Flutter doğrudan kullanabilir. |
| `ADMIN_ONLY` | 175 | Yalnız yönetici rolleri (RBAC / resolveUser / isAdmin). Flutter son kullanıcı uygulamasında kullanılmaz. |
| `WEB_ONLY` | 2 | Yalnız web oturumu (cookie) ile çalışır; mobil karşılığı bilinçli olarak yok. |
| `MISSING_MOBILE_SUPPORT` | 1 | Mobil JWT desteği yok; mobil için gerekirse eklenmeli. |
| `INTERNAL` | 3 | Zamanlanmış görev / servis içi uç (paylaşılan gizli anahtar ile korunur). |
| `DEPRECATED_ALIAS` | 4 | Başka bir uca yönlendiren geriye dönük uyumluluk takma adı. |
| **TOPLAM** | **612** | 612 rota dosyası / 953 uç (path+method) |

## Flutter için kural

- `FLUTTER_READY` + `PUBLIC` = Flutter istemcisinin kullanabileceği yüzey.
- `ADMIN_ONLY` uçları Flutter son kullanıcı uygulamasına **konulmamalıdır**; yetki sunucuda zorlanır, istemcideki `isAdmin` alanına asla güvenilmez.
- `DEPRECATED_ALIAS` uçları çalışır ancak yeni geliştirmede hedef uç kullanılmalıdır.

## FLUTTER_READY (306)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/activities` | GET | `app/api/activities/route.ts` |
| `/api/ads/placement` | GET, POST | `app/api/ads/placement/route.ts` |
| `/api/ads/reward` | POST | `app/api/ads/reward/route.ts` |
| `/api/agency/applicant-score/[userId]` | GET | `app/api/agency/applicant-score/[userId]/route.ts` |
| `/api/agency/apply` | POST | `app/api/agency/apply/route.ts` |
| `/api/agency/earnings` | GET | `app/api/agency/earnings/route.ts` |
| `/api/agency/growth` | GET | `app/api/agency/growth/route.ts` |
| `/api/agency/invite` | GET, POST | `app/api/agency/invite/route.ts` |
| `/api/agency/invite-earnings` | GET | `app/api/agency/invite-earnings/route.ts` |
| `/api/agency/join` | POST | `app/api/agency/join/route.ts` |
| `/api/agency/leave` | DELETE, POST | `app/api/agency/leave/route.ts` |
| `/api/agency/live-status` | GET | `app/api/agency/live-status/route.ts` |
| `/api/agency/members` | DELETE, GET, POST | `app/api/agency/members/route.ts` |
| `/api/agency/my` | GET, PATCH | `app/api/agency/my/route.ts` |
| `/api/agency/tasks` | GET | `app/api/agency/tasks/route.ts` |
| `/api/agency/wallet` | GET | `app/api/agency/wallet/route.ts` |
| `/api/agency/wallet/transfer` | POST | `app/api/agency/wallet/transfer/route.ts` |
| `/api/agency/withdrawals` | GET, POST | `app/api/agency/withdrawals/route.ts` |
| `/api/animations/me` | GET | `app/api/animations/me/route.ts` |
| `/api/animations/resolve` | GET | `app/api/animations/resolve/route.ts` |
| `/api/astrology-panel` | GET | `app/api/astrology-panel/route.ts` |
| `/api/auth/change-password` | POST | `app/api/auth/change-password/route.ts` |
| `/api/auth/email/send-verification` | POST | `app/api/auth/email/send-verification/route.ts` |
| `/api/auth/logout` | POST | `app/api/auth/logout/route.ts` |
| `/api/auth/logout-all` | POST | `app/api/auth/logout-all/route.ts` |
| `/api/auth/mobile-apple` | POST | `app/api/auth/mobile-apple/route.ts` |
| `/api/auth/mobile-google` | POST | `app/api/auth/mobile-google/route.ts` |
| `/api/auth/mobile-login` | POST | `app/api/auth/mobile-login/route.ts` |
| `/api/auth/mobile-refresh` | POST | `app/api/auth/mobile-refresh/route.ts` |
| `/api/auth/mobile-register` | POST | `app/api/auth/mobile-register/route.ts` |
| `/api/auth/mobile-tiktok` | POST | `app/api/auth/mobile-tiktok/route.ts` |
| `/api/auth/phone/send-otp` | POST | `app/api/auth/phone/send-otp/route.ts` |
| `/api/auth/phone/verify-otp` | POST | `app/api/auth/phone/verify-otp/route.ts` |
| `/api/auth/sessions` | DELETE, GET | `app/api/auth/sessions/route.ts` |
| `/api/bana-ozel` | GET | `app/api/bana-ozel/route.ts` |
| `/api/bana-ozel/open` | POST | `app/api/bana-ozel/open/route.ts` |
| `/api/billing/app-store/verify` | POST | `app/api/billing/app-store/verify/route.ts` |
| `/api/billing/google-play/verify` | POST | `app/api/billing/google-play/verify/route.ts` |
| `/api/blog/comments` | DELETE, GET, POST | `app/api/blog/comments/route.ts` |
| `/api/blog/favorite` | POST | `app/api/blog/favorite/route.ts` |
| `/api/blog/interactions` | GET | `app/api/blog/interactions/route.ts` |
| `/api/blog/like` | POST | `app/api/blog/like/route.ts` |
| `/api/bootstrap` | GET | `app/api/bootstrap/route.ts` |
| `/api/broadcast-images` | GET | `app/api/broadcast-images/route.ts` |
| `/api/cache` | GET, POST | `app/api/cache/route.ts` |
| `/api/cfc-arena/join` | POST | `app/api/cfc-arena/join/route.ts` |
| `/api/chat/rooms/[roomId]/gifts` | GET, POST | `app/api/chat/rooms/[roomId]/gifts/route.ts` |
| `/api/chat/rooms/[roomId]/messages` | DELETE, GET, POST | `app/api/chat/rooms/[roomId]/messages/route.ts` |
| `/api/chat/rooms/[roomId]/moderation` | GET, POST | `app/api/chat/rooms/[roomId]/moderation/route.ts` |
| `/api/chat/rooms/[roomId]/music` | DELETE, GET, POST | `app/api/chat/rooms/[roomId]/music/route.ts` |
| `/api/chat/rooms/[roomId]/music-queue` | GET | `app/api/chat/rooms/[roomId]/music-queue/route.ts` |
| `/api/chat/rooms/[roomId]/music/stop` | POST | `app/api/chat/rooms/[roomId]/music/stop/route.ts` |
| `/api/chat/rooms/[roomId]/seats` | GET, PATCH | `app/api/chat/rooms/[roomId]/seats/route.ts` |
| `/api/chat/rooms/[roomId]/settings` | GET, PATCH | `app/api/chat/rooms/[roomId]/settings/route.ts` |
| `/api/chat/rooms/[roomId]/song-request` | GET, PATCH, POST | `app/api/chat/rooms/[roomId]/song-request/route.ts` |
| `/api/chat/rooms/[roomId]/speak-request` | DELETE, GET, POST | `app/api/chat/rooms/[roomId]/speak-request/route.ts` |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | DELETE, POST | `app/api/chat/rooms/[roomId]/speak-request/[userId]/block/route.ts` |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | DELETE, POST | `app/api/chat/rooms/[roomId]/speak-request/[userId]/reject/route.ts` |
| `/api/chat/rooms/[roomId]/speak-requests` | GET | `app/api/chat/rooms/[roomId]/speak-requests/route.ts` |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | POST | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve/route.ts` |
| `/api/chat/rooms/[roomId]/state` | GET | `app/api/chat/rooms/[roomId]/state/route.ts` |
| `/api/chat/rooms/[roomId]/stream` | GET | `app/api/chat/rooms/[roomId]/stream/route.ts` |
| `/api/chat/rooms/[roomId]/sync` | GET | `app/api/chat/rooms/[roomId]/sync/route.ts` |
| `/api/chat/rooms/[roomId]/typing` | GET, POST | `app/api/chat/rooms/[roomId]/typing/route.ts` |
| `/api/chat/rooms/[roomId]/voice` | GET, POST | `app/api/chat/rooms/[roomId]/voice/route.ts` |
| `/api/chat/rooms/create` | POST | `app/api/chat/rooms/create/route.ts` |
| `/api/chat/rooms/pk/candidates` | GET | `app/api/chat/rooms/pk/candidates/route.ts` |
| `/api/daily-login` | GET, POST | `app/api/daily-login/route.ts` |
| `/api/daily-missions` | GET, POST | `app/api/daily-missions/route.ts` |
| `/api/devices/fcm` | DELETE, POST | `app/api/devices/fcm/route.ts` |
| `/api/dream-contest` | GET | `app/api/dream-contest/route.ts` |
| `/api/dream-contest/[contestId]/entries` | GET, POST | `app/api/dream-contest/[contestId]/entries/route.ts` |
| `/api/dream-contest/[contestId]/vote` | POST | `app/api/dream-contest/[contestId]/vote/route.ts` |
| `/api/dream-diary` | DELETE, GET, POST | `app/api/dream-diary/route.ts` |
| `/api/dream-stats` | GET | `app/api/dream-stats/route.ts` |
| `/api/dreams/[slug]/favorite` | GET, POST | `app/api/dreams/[slug]/favorite/route.ts` |
| `/api/dreams/[slug]/view` | POST | `app/api/dreams/[slug]/view/route.ts` |
| `/api/dreams/favorites` | GET | `app/api/dreams/favorites/route.ts` |
| `/api/dreams/interpret` | POST | `app/api/dreams/interpret/route.ts` |
| `/api/dreams/recommendations` | GET | `app/api/dreams/recommendations/route.ts` |
| `/api/effects/resolve` | GET | `app/api/effects/resolve/route.ts` |
| `/api/favorite-tellers` | GET, POST | `app/api/favorite-tellers/route.ts` |
| `/api/fortune-access/check` | POST | `app/api/fortune-access/check/route.ts` |
| `/api/fortune-tellers` | GET, POST | `app/api/fortune-tellers/route.ts` |
| `/api/fortune-tellers/[tellerId]/session` | GET, POST | `app/api/fortune-tellers/[tellerId]/session/route.ts` |
| `/api/fortune-tellers/apply` | POST | `app/api/fortune-tellers/apply/route.ts` |
| `/api/fortune-tellers/my-profile` | GET | `app/api/fortune-tellers/my-profile/route.ts` |
| `/api/fortune-tellers/session` | GET, POST | `app/api/fortune-tellers/session/route.ts` |
| `/api/fortune-tellers/sessions` | GET | `app/api/fortune-tellers/sessions/route.ts` |
| `/api/fortune-tellers/sessions/[sessionId]` | PATCH | `app/api/fortune-tellers/sessions/[sessionId]/route.ts` |
| `/api/fortune-tellers/sessions/stream` | GET | `app/api/fortune-tellers/sessions/stream/route.ts` |
| `/api/fortune-tellers/toggle-online` | GET, POST | `app/api/fortune-tellers/toggle-online/route.ts` |
| `/api/fortunes/ask-uyumu` | POST | `app/api/fortunes/ask-uyumu/route.ts` |
| `/api/fortunes/aura-analizi` | POST | `app/api/fortunes/aura-analizi/route.ts` |
| `/api/fortunes/burc-yorumu` | POST | `app/api/fortunes/burc-yorumu/route.ts` |
| `/api/fortunes/dogum-haritasi` | POST | `app/api/fortunes/dogum-haritasi/route.ts` |
| `/api/fortunes/el-fali` | POST | `app/api/fortunes/el-fali/route.ts` |
| `/api/fortunes/evet-hayir` | POST | `app/api/fortunes/evet-hayir/route.ts` |
| `/api/fortunes/istihare` | POST | `app/api/fortunes/istihare/route.ts` |
| `/api/fortunes/kahve-fali` | POST | `app/api/fortunes/kahve-fali/route.ts` |
| `/api/fortunes/kahve-fali-image` | POST | `app/api/fortunes/kahve-fali-image/route.ts` |
| `/api/fortunes/katina` | POST | `app/api/fortunes/katina/route.ts` |
| `/api/fortunes/kursundokme` | POST | `app/api/fortunes/kursundokme/route.ts` |
| `/api/fortunes/melek-kartlari` | POST | `app/api/fortunes/melek-kartlari/route.ts` |
| `/api/fortunes/numeroloji` | POST | `app/api/fortunes/numeroloji/route.ts` |
| `/api/fortunes/ruya-yorumu` | POST | `app/api/fortunes/ruya-yorumu/route.ts` |
| `/api/fortunes/tarot-fali` | POST | `app/api/fortunes/tarot-fali/route.ts` |
| `/api/games/auto-match` | POST | `app/api/games/auto-match/route.ts` |
| `/api/games/daily-reward` | GET, POST | `app/api/games/daily-reward/route.ts` |
| `/api/games/daily-spin` | POST | `app/api/games/daily-spin/route.ts` |
| `/api/games/lamba-cini` | GET, POST | `app/api/games/lamba-cini/route.ts` |
| `/api/games/leaderboard` | GET | `app/api/games/leaderboard/route.ts` |
| `/api/games/lobby` | GET | `app/api/games/lobby/route.ts` |
| `/api/games/play` | POST | `app/api/games/play/route.ts` |
| `/api/games/profile` | GET | `app/api/games/profile/route.ts` |
| `/api/games/quests` | GET, POST | `app/api/games/quests/route.ts` |
| `/api/games/room` | GET, POST | `app/api/games/room/route.ts` |
| `/api/games/room/[roomId]` | DELETE, GET, PATCH, POST | `app/api/games/room/[roomId]/route.ts` |
| `/api/games/room/[roomId]/chat` | GET, PATCH, POST | `app/api/games/room/[roomId]/chat/route.ts` |
| `/api/games/room/[roomId]/replace-ai` | POST | `app/api/games/room/[roomId]/replace-ai/route.ts` |
| `/api/games/room/[roomId]/viewers` | DELETE, GET, POST | `app/api/games/room/[roomId]/viewers/route.ts` |
| `/api/games/sos` | GET, POST | `app/api/games/sos/route.ts` |
| `/api/games/sos/[gameId]` | DELETE, GET, PATCH, POST | `app/api/games/sos/[gameId]/route.ts` |
| `/api/games/sos/[gameId]/chat` | GET, PATCH, POST | `app/api/games/sos/[gameId]/chat/route.ts` |
| `/api/games/sos/[gameId]/viewers` | DELETE, GET, POST | `app/api/games/sos/[gameId]/viewers/route.ts` |
| `/api/gift-box` | GET, POST | `app/api/gift-box/route.ts` |
| `/api/gift-box/[boxId]/join` | POST | `app/api/gift-box/[boxId]/join/route.ts` |
| `/api/gift-box/share` | POST | `app/api/gift-box/share/route.ts` |
| `/api/gift-engine/finish` | POST | `app/api/gift-engine/finish/route.ts` |
| `/api/gifts/battles` | GET, POST | `app/api/gifts/battles/route.ts` |
| `/api/gifts/catalog` | GET | `app/api/gifts/catalog/route.ts` |
| `/api/gifts/check-reciprocal` | POST | `app/api/gifts/check-reciprocal/route.ts` |
| `/api/gifts/goals` | GET, POST | `app/api/gifts/goals/route.ts` |
| `/api/gifts/insights/me/badge` | GET | `app/api/gifts/insights/me/badge/route.ts` |
| `/api/gifts/insights/me/history` | GET | `app/api/gifts/insights/me/history/route.ts` |
| `/api/gifts/insights/me/recommendations` | GET | `app/api/gifts/insights/me/recommendations/route.ts` |
| `/api/gifts/lucky/config` | GET | `app/api/gifts/lucky/config/route.ts` |
| `/api/gifts/lucky/history` | GET | `app/api/gifts/lucky/history/route.ts` |
| `/api/gifts/lucky/send` | POST | `app/api/gifts/lucky/send/route.ts` |
| `/api/gifts/missions/[missionId]/claim` | POST | `app/api/gifts/missions/[missionId]/claim/route.ts` |
| `/api/gifts/missions/me` | GET | `app/api/gifts/missions/me/route.ts` |
| `/api/gifts/send` | POST | `app/api/gifts/send/route.ts` |
| `/api/hashtags/[name]` | GET | `app/api/hashtags/[name]/route.ts` |
| `/api/horoscope/daily` | GET | `app/api/horoscope/daily/route.ts` |
| `/api/jeton` | GET, POST | `app/api/jeton/route.ts` |
| `/api/leaderboards` | GET | `app/api/leaderboards/route.ts` |
| `/api/leaderboards/top100` | GET | `app/api/leaderboards/top100/route.ts` |
| `/api/live/create-room` | POST | `app/api/live/create-room/route.ts` |
| `/api/live/gift-types` | GET | `app/api/live/gift-types/route.ts` |
| `/api/live/gift/send` | POST | `app/api/live/gift/send/route.ts` |
| `/api/live/guest` | GET, POST | `app/api/live/guest/route.ts` |
| `/api/live/heartbeat` | POST | `app/api/live/heartbeat/route.ts` |
| `/api/live/join-room` | POST | `app/api/live/join-room/route.ts` |
| `/api/live/leave-room` | POST | `app/api/live/leave-room/route.ts` |
| `/api/live/message` | GET, POST | `app/api/live/message/route.ts` |
| `/api/live/online-users` | GET | `app/api/live/online-users/route.ts` |
| `/api/live/pk` | GET, POST | `app/api/live/pk/route.ts` |
| `/api/live/rooms` | GET | `app/api/live/rooms/route.ts` |
| `/api/live/seats` | GET, POST | `app/api/live/seats/route.ts` |
| `/api/me` | GET, PATCH | `app/api/me/route.ts` |
| `/api/me/admin-capabilities` | GET | `app/api/me/admin-capabilities/route.ts` |
| `/api/me/membership` | GET | `app/api/me/membership/route.ts` |
| `/api/me/membership-events` | GET | `app/api/me/membership-events/route.ts` |
| `/api/me/membership-history` | GET, PUT | `app/api/me/membership-history/route.ts` |
| `/api/me/profile-visitors` | GET, POST | `app/api/me/profile-visitors/route.ts` |
| `/api/me/vip-identity` | GET, PUT | `app/api/me/vip-identity/route.ts` |
| `/api/me/vip-preferences` | GET, PUT | `app/api/me/vip-preferences/route.ts` |
| `/api/me/vip-xp` | GET, POST | `app/api/me/vip-xp/route.ts` |
| `/api/memberships/gift` | POST | `app/api/memberships/gift/route.ts` |
| `/api/memberships/purchase` | POST | `app/api/memberships/purchase/route.ts` |
| `/api/messages` | GET | `app/api/messages/route.ts` |
| `/api/messages/[userId]` | GET, POST | `app/api/messages/[userId]/route.ts` |
| `/api/messages/request` | PATCH, POST | `app/api/messages/request/route.ts` |
| `/api/mobile/fortune-menu` | GET | `app/api/mobile/fortune-menu/route.ts` |
| `/api/mobile/home` | GET | `app/api/mobile/home/route.ts` |
| `/api/mobile/user-profile/[userId]` | GET | `app/api/mobile/user-profile/[userId]/route.ts` |
| `/api/music/search` | GET | `app/api/music/search/route.ts` |
| `/api/notifications` | DELETE, GET, POST | `app/api/notifications/route.ts` |
| `/api/notifications/stream` | GET | `app/api/notifications/stream/route.ts` |
| `/api/payments/config` | GET | `app/api/payments/config/route.ts` |
| `/api/payments/notifications/[notificationId]/dispute` | GET, POST | `app/api/payments/notifications/[notificationId]/dispute/route.ts` |
| `/api/payments/notify` | GET, POST | `app/api/payments/notify/route.ts` |
| `/api/payments/requests` | GET, POST | `app/api/payments/requests/route.ts` |
| `/api/pk/me/invites` | GET | `app/api/pk/me/invites/route.ts` |
| `/api/popups` | GET | `app/api/popups/route.ts` |
| `/api/presence` | GET, POST | `app/api/presence/route.ts` |
| `/api/profile-frames` | GET, POST | `app/api/profile-frames/route.ts` |
| `/api/referral` | GET | `app/api/referral/route.ts` |
| `/api/refunds` | GET, POST | `app/api/refunds/route.ts` |
| `/api/room-themes/catalog` | GET | `app/api/room-themes/catalog/route.ts` |
| `/api/room/[sessionId]` | GET, PATCH | `app/api/room/[sessionId]/route.ts` |
| `/api/room/[sessionId]/messages` | GET, POST | `app/api/room/[sessionId]/messages/route.ts` |
| `/api/room/[sessionId]/review` | GET, POST | `app/api/room/[sessionId]/review/route.ts` |
| `/api/room/[sessionId]/stream` | GET | `app/api/room/[sessionId]/stream/route.ts` |
| `/api/room/[sessionId]/summary` | GET | `app/api/room/[sessionId]/summary/route.ts` |
| `/api/room/[sessionId]/tip` | POST | `app/api/room/[sessionId]/tip/route.ts` |
| `/api/room/signal` | DELETE, GET, POST | `app/api/room/signal/route.ts` |
| `/api/rtc/telemetry` | POST | `app/api/rtc/telemetry/route.ts` |
| `/api/search/advanced` | GET | `app/api/search/advanced/route.ts` |
| `/api/share-card` | GET | `app/api/share-card/route.ts` |
| `/api/short-videos` | GET | `app/api/short-videos/route.ts` |
| `/api/short-videos/[id]` | DELETE, GET | `app/api/short-videos/[id]/route.ts` |
| `/api/short-videos/[id]/comments` | GET, POST | `app/api/short-videos/[id]/comments/route.ts` |
| `/api/short-videos/[id]/comments/[commentId]/like` | POST | `app/api/short-videos/[id]/comments/[commentId]/like/route.ts` |
| `/api/short-videos/[id]/comments/[commentId]/pin` | POST | `app/api/short-videos/[id]/comments/[commentId]/pin/route.ts` |
| `/api/short-videos/[id]/duets` | GET | `app/api/short-videos/[id]/duets/route.ts` |
| `/api/short-videos/[id]/like` | POST | `app/api/short-videos/[id]/like/route.ts` |
| `/api/short-videos/[id]/save` | POST | `app/api/short-videos/[id]/save/route.ts` |
| `/api/short-videos/[id]/share` | POST | `app/api/short-videos/[id]/share/route.ts` |
| `/api/short-videos/[id]/view` | POST | `app/api/short-videos/[id]/view/route.ts` |
| `/api/short-videos/explore` | GET | `app/api/short-videos/explore/route.ts` |
| `/api/short-videos/profile/[userId]` | GET | `app/api/short-videos/profile/[userId]/route.ts` |
| `/api/short-videos/register` | POST | `app/api/short-videos/register/route.ts` |
| `/api/short-videos/upload` | POST | `app/api/short-videos/upload/route.ts` |
| `/api/short-videos/upload-url` | POST | `app/api/short-videos/upload-url/route.ts` |
| `/api/short-videos/user/[userId]` | GET | `app/api/short-videos/user/[userId]/route.ts` |
| `/api/social/actions` | GET, POST | `app/api/social/actions/route.ts` |
| `/api/social/discovery` | GET | `app/api/social/discovery/route.ts` |
| `/api/social/posts` | GET, POST | `app/api/social/posts/route.ts` |
| `/api/social/posts/[postId]` | DELETE, GET | `app/api/social/posts/[postId]/route.ts` |
| `/api/social/posts/[postId]/comments` | DELETE, GET, POST | `app/api/social/posts/[postId]/comments/route.ts` |
| `/api/social/posts/[postId]/likes` | POST | `app/api/social/posts/[postId]/likes/route.ts` |
| `/api/social/profile` | GET | `app/api/social/profile/route.ts` |
| `/api/stories` | DELETE, GET, POST | `app/api/stories/route.ts` |
| `/api/support/tickets` | GET, POST | `app/api/support/tickets/route.ts` |
| `/api/support/tickets/[ticketId]` | GET, PATCH | `app/api/support/tickets/[ticketId]/route.ts` |
| `/api/support/tickets/[ticketId]/messages` | POST | `app/api/support/tickets/[ticketId]/messages/route.ts` |
| `/api/supporter-levels` | GET | `app/api/supporter-levels/route.ts` |
| `/api/teams` | GET, POST | `app/api/teams/route.ts` |
| `/api/teams/[teamId]` | GET, PATCH | `app/api/teams/[teamId]/route.ts` |
| `/api/teller-chat` | GET | `app/api/teller-chat/route.ts` |
| `/api/teller-chat/[sessionId]` | GET, POST | `app/api/teller-chat/[sessionId]/route.ts` |
| `/api/teller/analytics` | GET | `app/api/teller/analytics/route.ts` |
| `/api/teller/level` | GET | `app/api/teller/level/route.ts` |
| `/api/teller/verification` | GET, POST | `app/api/teller/verification/route.ts` |
| `/api/tournaments` | GET | `app/api/tournaments/route.ts` |
| `/api/trends/[slug]/like` | POST | `app/api/trends/[slug]/like/route.ts` |
| `/api/trtc/token` | POST | `app/api/trtc/token/route.ts` |
| `/api/trtc/usersig` | POST | `app/api/trtc/usersig/route.ts` |
| `/api/upload/get-url` | GET, POST | `app/api/upload/get-url/route.ts` |
| `/api/upload/presigned` | POST | `app/api/upload/presigned/route.ts` |
| `/api/user/[userId]/achievements` | GET | `app/api/user/[userId]/achievements/route.ts` |
| `/api/user/[userId]/follow` | DELETE, POST | `app/api/user/[userId]/follow/route.ts` |
| `/api/user/[userId]/follow-status` | GET | `app/api/user/[userId]/follow-status/route.ts` |
| `/api/user/account` | DELETE, POST | `app/api/user/account/route.ts` |
| `/api/user/achievements` | GET | `app/api/user/achievements/route.ts` |
| `/api/user/active-sessions` | GET | `app/api/user/active-sessions/route.ts` |
| `/api/user/activity` | GET, PATCH | `app/api/user/activity/route.ts` |
| `/api/user/block` | GET, POST | `app/api/user/block/route.ts` |
| `/api/user/blocked` | DELETE, GET | `app/api/user/blocked/route.ts` |
| `/api/user/broadcast-history` | GET | `app/api/user/broadcast-history/route.ts` |
| `/api/user/co-broadcast-invites` | GET | `app/api/user/co-broadcast-invites/route.ts` |
| `/api/user/credits` | GET | `app/api/user/credits/route.ts` |
| `/api/user/followers` | GET | `app/api/user/followers/route.ts` |
| `/api/user/following` | GET | `app/api/user/following/route.ts` |
| `/api/user/fortunes` | GET | `app/api/user/fortunes/route.ts` |
| `/api/user/fortunes/[fortuneId]` | PATCH | `app/api/user/fortunes/[fortuneId]/route.ts` |
| `/api/user/likers` | GET | `app/api/user/likers/route.ts` |
| `/api/user/location` | GET, POST | `app/api/user/location/route.ts` |
| `/api/user/profile` | GET, PATCH | `app/api/user/profile/route.ts` |
| `/api/user/received-gifts` | GET | `app/api/user/received-gifts/route.ts` |
| `/api/user/referral-earnings` | GET | `app/api/user/referral-earnings/route.ts` |
| `/api/user/report` | POST | `app/api/user/report/route.ts` |
| `/api/user/social-settings` | GET, PUT | `app/api/user/social-settings/route.ts` |
| `/api/user/statistics` | GET | `app/api/user/statistics/route.ts` |
| `/api/user/stats` | GET, POST | `app/api/user/stats/route.ts` |
| `/api/user/theme` | GET, PATCH | `app/api/user/theme/route.ts` |
| `/api/user/wallet` | GET | `app/api/user/wallet/route.ts` |
| `/api/user/watch-ad` | GET, POST | `app/api/user/watch-ad/route.ts` |
| `/api/user/xp` | GET | `app/api/user/xp/route.ts` |
| `/api/users/[userId]` | GET | `app/api/users/[userId]/route.ts` |
| `/api/users/[userId]/follow` | GET, POST | `app/api/users/[userId]/follow/route.ts` |
| `/api/users/[userId]/posts` | GET | `app/api/users/[userId]/posts/route.ts` |
| `/api/users/lookup/[username]` | GET | `app/api/users/lookup/[username]/route.ts` |
| `/api/users/search` | GET | `app/api/users/search/route.ts` |
| `/api/verification` | GET, POST | `app/api/verification/route.ts` |
| `/api/video-streams` | GET, POST | `app/api/video-streams/route.ts` |
| `/api/video-streams/[streamId]/auto-close` | GET, POST | `app/api/video-streams/[streamId]/auto-close/route.ts` |
| `/api/video-streams/[streamId]/ban` | DELETE, GET, POST | `app/api/video-streams/[streamId]/ban/route.ts` |
| `/api/video-streams/[streamId]/co-broadcast` | GET, PATCH, POST | `app/api/video-streams/[streamId]/co-broadcast/route.ts` |
| `/api/video-streams/[streamId]/co-broadcast/invite` | POST | `app/api/video-streams/[streamId]/co-broadcast/invite/route.ts` |
| `/api/video-streams/[streamId]/comments` | GET, POST | `app/api/video-streams/[streamId]/comments/route.ts` |
| `/api/video-streams/[streamId]/fortune-requests` | DELETE, GET, PATCH, POST | `app/api/video-streams/[streamId]/fortune-requests/route.ts` |
| `/api/video-streams/[streamId]/fortune-requests/my-status` | GET | `app/api/video-streams/[streamId]/fortune-requests/my-status/route.ts` |
| `/api/video-streams/[streamId]/gifts` | GET, POST | `app/api/video-streams/[streamId]/gifts/route.ts` |
| `/api/video-streams/[streamId]/join` | DELETE, POST | `app/api/video-streams/[streamId]/join/route.ts` |
| `/api/video-streams/[streamId]/leave` | POST | `app/api/video-streams/[streamId]/leave/route.ts` |
| `/api/video-streams/[streamId]/like` | GET, POST | `app/api/video-streams/[streamId]/like/route.ts` |
| `/api/video-streams/[streamId]/live-started` | POST | `app/api/video-streams/[streamId]/live-started/route.ts` |
| `/api/video-streams/[streamId]/media-heartbeat` | POST | `app/api/video-streams/[streamId]/media-heartbeat/route.ts` |
| `/api/video-streams/[streamId]/messages` | GET, POST | `app/api/video-streams/[streamId]/messages/route.ts` |
| `/api/video-streams/[streamId]/moderators` | DELETE, GET, POST | `app/api/video-streams/[streamId]/moderators/route.ts` |
| `/api/video-streams/[streamId]/mute` | DELETE, GET, POST | `app/api/video-streams/[streamId]/mute/route.ts` |
| `/api/video-streams/[streamId]/pk-battle` | GET, POST | `app/api/video-streams/[streamId]/pk-battle/route.ts` |
| `/api/video-streams/[streamId]/signal` | DELETE, GET, POST | `app/api/video-streams/[streamId]/signal/route.ts` |
| `/api/video-streams/[streamId]/stream` | GET | `app/api/video-streams/[streamId]/stream/route.ts` |
| `/api/video-streams/[streamId]/sync` | GET | `app/api/video-streams/[streamId]/sync/route.ts` |
| `/api/video-streams/gifts` | GET | `app/api/video-streams/gifts/route.ts` |
| `/api/video-streams/pk/candidates` | GET | `app/api/video-streams/pk/candidates/route.ts` |
| `/api/video-streams/pk/score` | POST | `app/api/video-streams/pk/score/route.ts` |
| `/api/video-streams/signal` | DELETE, GET, POST | `app/api/video-streams/signal/route.ts` |
| `/api/vip/leaderboard` | GET | `app/api/vip/leaderboard/route.ts` |
| `/api/wallet` | GET | `app/api/wallet/route.ts` |
| `/api/weekly-dream-report` | GET, POST | `app/api/weekly-dream-report/route.ts` |
| `/api/withdrawals` | GET, POST | `app/api/withdrawals/route.ts` |
| `/api/youtube/search` | GET | `app/api/youtube/search/route.ts` |

## PUBLIC (121)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/[...unmatched]` | DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT | `app/api/[...unmatched]/route.ts` |
| `/api/ads/active` | GET | `app/api/ads/active/route.ts` |
| `/api/agency/leaderboard` | GET | `app/api/agency/leaderboard/route.ts` |
| `/api/animations/manifest` | GET | `app/api/animations/manifest/route.ts` |
| `/api/anonymous` | GET, POST | `app/api/anonymous/route.ts` |
| `/api/anonymous/watch-ad` | POST | `app/api/anonymous/watch-ad/route.ts` |
| `/api/auth/[...nextauth]` | GET, POST | `app/api/auth/[...nextauth]/route.ts` |
| `/api/auth/email/verify` | GET, POST | `app/api/auth/email/verify/route.ts` |
| `/api/auth/forgot-password` | POST | `app/api/auth/forgot-password/route.ts` |
| `/api/auth/reset-password` | POST | `app/api/auth/reset-password/route.ts` |
| `/api/avatar-accessories` | GET | `app/api/avatar-accessories/route.ts` |
| `/api/blog` | GET | `app/api/blog/route.ts` |
| `/api/blog/categories` | GET | `app/api/blog/categories/route.ts` |
| `/api/blog/related` | GET | `app/api/blog/related/route.ts` |
| `/api/blog/zodiac` | GET | `app/api/blog/zodiac/route.ts` |
| `/api/cfc-arena` | GET | `app/api/cfc-arena/route.ts` |
| `/api/cfc-arena/[contestId]` | GET | `app/api/cfc-arena/[contestId]/route.ts` |
| `/api/chat-bubbles` | GET | `app/api/chat-bubbles/route.ts` |
| `/api/chat/broadcast-images` | GET | `app/api/chat/broadcast-images/route.ts` |
| `/api/chat/rooms` | GET | `app/api/chat/rooms/route.ts` |
| `/api/chat/rooms/[roomId]/pin-message` | POST | `app/api/chat/rooms/[roomId]/pin-message/route.ts` |
| `/api/chat/rooms/backgrounds` | GET | `app/api/chat/rooms/backgrounds/route.ts` |
| `/api/chat/rooms/pk-list` | GET | `app/api/chat/rooms/pk-list/route.ts` |
| `/api/chat/youtube-audio` | GET, POST | `app/api/chat/youtube-audio/route.ts` |
| `/api/chat/youtube-stream` | GET | `app/api/chat/youtube-stream/route.ts` |
| `/api/compatibility` | POST | `app/api/compatibility/route.ts` |
| `/api/config` | GET | `app/api/config/route.ts` |
| `/api/contact` | POST | `app/api/contact/route.ts` |
| `/api/credit-packages` | GET | `app/api/credit-packages/route.ts` |
| `/api/currency-branding` | GET | `app/api/currency-branding/route.ts` |
| `/api/deeplink/resolve` | GET | `app/api/deeplink/resolve/route.ts` |
| `/api/dream-symbols` | GET | `app/api/dream-symbols/route.ts` |
| `/api/dream-symbols/[slug]` | GET | `app/api/dream-symbols/[slug]/route.ts` |
| `/api/dreams` | GET | `app/api/dreams/route.ts` |
| `/api/dreams/[slug]` | GET | `app/api/dreams/[slug]/route.ts` |
| `/api/dreams/generate` | POST | `app/api/dreams/generate/route.ts` |
| `/api/dreams/trends` | GET | `app/api/dreams/trends/route.ts` |
| `/api/emoji-packs` | GET | `app/api/emoji-packs/route.ts` |
| `/api/entrance-effects` | GET | `app/api/entrance-effects/route.ts` |
| `/api/football` | GET | `app/api/football/route.ts` |
| `/api/fortune-access/ip-status` | GET | `app/api/fortune-access/ip-status/route.ts` |
| `/api/fortune-request-types` | GET | `app/api/fortune-request-types/route.ts` |
| `/api/fortune-tellers/[tellerId]/reviews` | GET | `app/api/fortune-tellers/[tellerId]/reviews/route.ts` |
| `/api/fortune-tellers/awards` | GET | `app/api/fortune-tellers/awards/route.ts` |
| `/api/fortune-tellers/gifts` | GET | `app/api/fortune-tellers/gifts/route.ts` |
| `/api/games` | GET | `app/api/games/route.ts` |
| `/api/games/grid-settings` | GET | `app/api/games/grid-settings/route.ts` |
| `/api/games/rooms` | GET | `app/api/games/rooms/route.ts` |
| `/api/gift-box/[boxId]` | GET | `app/api/gift-box/[boxId]/route.ts` |
| `/api/gift-engine/gifts` | GET | `app/api/gift-engine/gifts/route.ts` |
| `/api/gift-engine/queue` | GET | `app/api/gift-engine/queue/route.ts` |
| `/api/gifts/battles/[battleId]` | GET | `app/api/gifts/battles/[battleId]/route.ts` |
| `/api/gifts/insights/album/[userId]` | GET | `app/api/gifts/insights/album/[userId]/route.ts` |
| `/api/gifts/insights/badge/[userId]` | GET | `app/api/gifts/insights/badge/[userId]/route.ts` |
| `/api/gifts/insights/collection/[userId]` | GET | `app/api/gifts/insights/collection/[userId]/route.ts` |
| `/api/gifts/insights/feed` | GET | `app/api/gifts/insights/feed/route.ts` |
| `/api/gifts/insights/first-gifter/[context]/[contextId]` | GET | `app/api/gifts/insights/first-gifter/[context]/[contextId]/route.ts` |
| `/api/gifts/insights/leaderboard` | GET | `app/api/gifts/insights/leaderboard/route.ts` |
| `/api/gifts/insights/map` | GET | `app/api/gifts/insights/map/route.ts` |
| `/api/gifts/missions` | GET | `app/api/gifts/missions/route.ts` |
| `/api/gifts/recent-big` | GET | `app/api/gifts/recent-big/route.ts` |
| `/api/gifts/types` | GET | `app/api/gifts/types/route.ts` |
| `/api/gifts/version` | GET | `app/api/gifts/version/route.ts` |
| `/api/hashtags/search` | GET | `app/api/hashtags/search/route.ts` |
| `/api/hashtags/trending` | GET | `app/api/hashtags/trending/route.ts` |
| `/api/health` | GET | `app/api/health/route.ts` |
| `/api/homepage-buttons` | GET | `app/api/homepage-buttons/route.ts` |
| `/api/homepage-fortune-cards` | GET | `app/api/homepage-fortune-cards/route.ts` |
| `/api/homepage-ticker` | GET | `app/api/homepage-ticker/route.ts` |
| `/api/legal/child-safety` | GET | `app/api/legal/child-safety/route.ts` |
| `/api/live/guest/list` | GET | `app/api/live/guest/list/route.ts` |
| `/api/live/pk/active` | GET | `app/api/live/pk/active/route.ts` |
| `/api/membership-badges` | GET | `app/api/membership-badges/route.ts` |
| `/api/membership/plans` | GET | `app/api/membership/plans/route.ts` |
| `/api/memberships` | GET | `app/api/memberships/route.ts` |
| `/api/memberships/comparison` | GET | `app/api/memberships/comparison/route.ts` |
| `/api/memberships/packages` | GET | `app/api/memberships/packages/route.ts` |
| `/api/mic-frames` | GET | `app/api/mic-frames/route.ts` |
| `/api/mobile/config` | GET | `app/api/mobile/config/route.ts` |
| `/api/music/history` | GET | `app/api/music/history/route.ts` |
| `/api/name-effects` | GET | `app/api/name-effects/route.ts` |
| `/api/online-fal` | GET | `app/api/online-fal/route.ts` |
| `/api/payments/methods` | GET | `app/api/payments/methods/route.ts` |
| `/api/payments/settings` | GET | `app/api/payments/settings/route.ts` |
| `/api/pk/[matchId]` | GET | `app/api/pk/[matchId]/route.ts` |
| `/api/pk/[matchId]/stream` | GET | `app/api/pk/[matchId]/stream/route.ts` |
| `/api/pk/active` | GET | `app/api/pk/active/route.ts` |
| `/api/pk/leaderboard` | GET | `app/api/pk/leaderboard/route.ts` |
| `/api/platform/commission-rate` | GET | `app/api/platform/commission-rate/route.ts` |
| `/api/presence/online-events` | GET | `app/api/presence/online-events/route.ts` |
| `/api/presence/sections` | GET | `app/api/presence/sections/route.ts` |
| `/api/public-stats` | GET | `app/api/public-stats/route.ts` |
| `/api/public/announcement-settings` | GET | `app/api/public/announcement-settings/route.ts` |
| `/api/public/jeton-price` | GET | `app/api/public/jeton-price/route.ts` |
| `/api/referral/validate` | GET | `app/api/referral/validate/route.ts` |
| `/api/room-themes` | GET | `app/api/room-themes/route.ts` |
| `/api/search` | GET | `app/api/search/route.ts` |
| `/api/seo-settings` | GET | `app/api/seo-settings/route.ts` |
| `/api/settings/ads` | GET | `app/api/settings/ads/route.ts` |
| `/api/settings/canlidark-hero` | GET | `app/api/settings/canlidark-hero/route.ts` |
| `/api/settings/public` | GET | `app/api/settings/public/route.ts` |
| `/api/settings/themes` | GET | `app/api/settings/themes/route.ts` |
| `/api/short-videos/mentions/search` | GET | `app/api/short-videos/mentions/search/route.ts` |
| `/api/short-videos/music` | GET | `app/api/short-videos/music/route.ts` |
| `/api/signup` | POST | `app/api/signup/route.ts` |
| `/api/site-pages/[slug]` | GET | `app/api/site-pages/[slug]/route.ts` |
| `/api/social/posts/[postId]/view` | POST | `app/api/social/posts/[postId]/view/route.ts` |
| `/api/tencent/webhook` | POST | `app/api/tencent/webhook/route.ts` |
| `/api/tiktok-videos` | GET | `app/api/tiktok-videos/route.ts` |
| `/api/tiktok-videos/[id]` | GET | `app/api/tiktok-videos/[id]/route.ts` |
| `/api/tiktok-videos/oembed` | GET | `app/api/tiktok-videos/oembed/route.ts` |
| `/api/tmdb` | GET | `app/api/tmdb/route.ts` |
| `/api/translations` | GET | `app/api/translations/route.ts` |
| `/api/trend-videos` | GET, POST | `app/api/trend-videos/route.ts` |
| `/api/trends` | GET | `app/api/trends/route.ts` |
| `/api/trends/[slug]` | GET | `app/api/trends/[slug]/route.ts` |
| `/api/trtc/webhook` | POST | `app/api/trtc/webhook/route.ts` |
| `/api/users/online` | GET | `app/api/users/online/route.ts` |
| `/api/video-streams/[streamId]/viewers` | GET | `app/api/video-streams/[streamId]/viewers/route.ts` |
| `/api/video-streams/pk/list` | GET | `app/api/video-streams/pk/list/route.ts` |
| `/api/warmup` | GET | `app/api/warmup/route.ts` |

## ADMIN_ONLY (175)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/admin/activity-feed` | GET, POST | `app/api/admin/activity-feed/route.ts` |
| `/api/admin/ad-networks` | DELETE, GET, POST | `app/api/admin/ad-networks/route.ts` |
| `/api/admin/ad-placements` | GET, POST | `app/api/admin/ad-placements/route.ts` |
| `/api/admin/ad-placements/[id]` | DELETE, GET, PATCH | `app/api/admin/ad-placements/[id]/route.ts` |
| `/api/admin/ad-placements/stats` | GET | `app/api/admin/ad-placements/stats/route.ts` |
| `/api/admin/agencies` | DELETE, GET, PATCH, POST | `app/api/admin/agencies/route.ts` |
| `/api/admin/agencies/[agencyId]/commission` | GET, PUT | `app/api/admin/agencies/[agencyId]/commission/route.ts` |
| `/api/admin/agencies/[agencyId]/wallet` | GET, POST | `app/api/admin/agencies/[agencyId]/wallet/route.ts` |
| `/api/admin/agency-applicant-config` | GET, PUT | `app/api/admin/agency-applicant-config/route.ts` |
| `/api/admin/agency-finance` | GET, PUT | `app/api/admin/agency-finance/route.ts` |
| `/api/admin/animations` | GET, POST | `app/api/admin/animations/route.ts` |
| `/api/admin/animations/[id]` | DELETE, GET, PATCH | `app/api/admin/animations/[id]/route.ts` |
| `/api/admin/animations/assignments` | DELETE, GET, PATCH, POST | `app/api/admin/animations/assignments/route.ts` |
| `/api/admin/animations/membership-defaults` | DELETE, GET, POST | `app/api/admin/animations/membership-defaults/route.ts` |
| `/api/admin/animations/stats` | GET | `app/api/admin/animations/stats/route.ts` |
| `/api/admin/announcement-sections` | GET, POST | `app/api/admin/announcement-sections/route.ts` |
| `/api/admin/audit-logs` | GET | `app/api/admin/audit-logs/route.ts` |
| `/api/admin/avatar-accessories` | GET | `app/api/admin/avatar-accessories/route.ts` |
| `/api/admin/awards` | DELETE, GET, POST | `app/api/admin/awards/route.ts` |
| `/api/admin/backup` | GET | `app/api/admin/backup/route.ts` |
| `/api/admin/badges` | DELETE, GET, POST, PUT | `app/api/admin/badges/route.ts` |
| `/api/admin/bana-ozel` | GET, PATCH, POST | `app/api/admin/bana-ozel/route.ts` |
| `/api/admin/blog` | GET, POST | `app/api/admin/blog/route.ts` |
| `/api/admin/blog/[postId]` | DELETE, PATCH, PUT | `app/api/admin/blog/[postId]/route.ts` |
| `/api/admin/blog/analytics` | GET | `app/api/admin/blog/analytics/route.ts` |
| `/api/admin/blog/bulk-category` | PATCH | `app/api/admin/blog/bulk-category/route.ts` |
| `/api/admin/blog/bulk-delete` | POST | `app/api/admin/blog/bulk-delete/route.ts` |
| `/api/admin/blog/bulk-generate` | POST | `app/api/admin/blog/bulk-generate/route.ts` |
| `/api/admin/blog/bulk-import` | POST | `app/api/admin/blog/bulk-import/route.ts` |
| `/api/admin/blog/bulk-publish` | PATCH | `app/api/admin/blog/bulk-publish/route.ts` |
| `/api/admin/blog/categories` | DELETE, GET, POST | `app/api/admin/blog/categories/route.ts` |
| `/api/admin/blog/comments` | GET, PATCH | `app/api/admin/blog/comments/route.ts` |
| `/api/admin/blog/generate` | POST | `app/api/admin/blog/generate/route.ts` |
| `/api/admin/blog/import` | POST | `app/api/admin/blog/import/route.ts` |
| `/api/admin/blog/schedule-publish` | POST | `app/api/admin/blog/schedule-publish/route.ts` |
| `/api/admin/bots` | GET, PATCH | `app/api/admin/bots/route.ts` |
| `/api/admin/bots/simulate` | GET, POST | `app/api/admin/bots/simulate/route.ts` |
| `/api/admin/bots/simulate-fortune` | GET, POST | `app/api/admin/bots/simulate-fortune/route.ts` |
| `/api/admin/bots/simulate-master` | GET, POST | `app/api/admin/bots/simulate-master/route.ts` |
| `/api/admin/bots/simulate-social` | GET, POST | `app/api/admin/bots/simulate-social/route.ts` |
| `/api/admin/broadcast-images` | DELETE, GET, PATCH, POST | `app/api/admin/broadcast-images/route.ts` |
| `/api/admin/button-order` | GET, POST | `app/api/admin/button-order/route.ts` |
| `/api/admin/cache` | DELETE, GET | `app/api/admin/cache/route.ts` |
| `/api/admin/cfc-arena` | GET, POST | `app/api/admin/cfc-arena/route.ts` |
| `/api/admin/cfc-arena/[contestId]` | GET | `app/api/admin/cfc-arena/[contestId]/route.ts` |
| `/api/admin/cfc-payment-requests` | GET, PATCH | `app/api/admin/cfc-payment-requests/route.ts` |
| `/api/admin/cfc-settings` | GET, POST | `app/api/admin/cfc-settings/route.ts` |
| `/api/admin/chat-bubbles` | GET | `app/api/admin/chat-bubbles/route.ts` |
| `/api/admin/chat-rooms` | DELETE, GET, POST, PUT | `app/api/admin/chat-rooms/route.ts` |
| `/api/admin/contests` | DELETE, GET, PATCH, POST | `app/api/admin/contests/route.ts` |
| `/api/admin/credit-packages` | GET, POST | `app/api/admin/credit-packages/route.ts` |
| `/api/admin/credit-packages/[packageId]` | DELETE, PATCH | `app/api/admin/credit-packages/[packageId]/route.ts` |
| `/api/admin/credits` | POST | `app/api/admin/credits/route.ts` |
| `/api/admin/currency-config` | GET, POST, PUT | `app/api/admin/currency-config/route.ts` |
| `/api/admin/currency-settings` | GET, PATCH | `app/api/admin/currency-settings/route.ts` |
| `/api/admin/dreams` | DELETE, GET, POST, PUT | `app/api/admin/dreams/route.ts` |
| `/api/admin/dreams/bulk-category` | PATCH | `app/api/admin/dreams/bulk-category/route.ts` |
| `/api/admin/dreams/bulk-delete` | POST | `app/api/admin/dreams/bulk-delete/route.ts` |
| `/api/admin/dreams/bulk-import` | POST | `app/api/admin/dreams/bulk-import/route.ts` |
| `/api/admin/dreams/bulk-publish` | PATCH | `app/api/admin/dreams/bulk-publish/route.ts` |
| `/api/admin/dreams/generate` | POST | `app/api/admin/dreams/generate/route.ts` |
| `/api/admin/effect-rules` | GET, POST | `app/api/admin/effect-rules/route.ts` |
| `/api/admin/effect-rules/[ruleId]` | DELETE, PATCH | `app/api/admin/effect-rules/[ruleId]/route.ts` |
| `/api/admin/emoji-packs` | GET | `app/api/admin/emoji-packs/route.ts` |
| `/api/admin/entrance-effects` | GET | `app/api/admin/entrance-effects/route.ts` |
| `/api/admin/feature-flags` | GET, POST | `app/api/admin/feature-flags/route.ts` |
| `/api/admin/feature-flags/[flagId]` | DELETE, PATCH | `app/api/admin/feature-flags/[flagId]/route.ts` |
| `/api/admin/finance` | GET, POST | `app/api/admin/finance/route.ts` |
| `/api/admin/fortune-request-types` | DELETE, GET, PATCH, POST | `app/api/admin/fortune-request-types/route.ts` |
| `/api/admin/fortunes` | GET | `app/api/admin/fortunes/route.ts` |
| `/api/admin/games` | DELETE, GET, POST, PUT | `app/api/admin/games/route.ts` |
| `/api/admin/games/rooms` | DELETE, GET | `app/api/admin/games/rooms/route.ts` |
| `/api/admin/games/settings` | GET, PUT | `app/api/admin/games/settings/route.ts` |
| `/api/admin/gift-collections` | GET, PATCH, POST | `app/api/admin/gift-collections/route.ts` |
| `/api/admin/gift-upload` | POST | `app/api/admin/gift-upload/route.ts` |
| `/api/admin/gifts` | GET, POST | `app/api/admin/gifts/route.ts` |
| `/api/admin/gifts/[giftId]` | DELETE, GET, PATCH | `app/api/admin/gifts/[giftId]/route.ts` |
| `/api/admin/gifts/stats` | GET | `app/api/admin/gifts/stats/route.ts` |
| `/api/admin/global-search` | GET | `app/api/admin/global-search/route.ts` |
| `/api/admin/homepage-buttons` | DELETE, GET, PATCH, POST | `app/api/admin/homepage-buttons/route.ts` |
| `/api/admin/homepage-fortune-cards` | DELETE, GET, PATCH, POST, PUT | `app/api/admin/homepage-fortune-cards/route.ts` |
| `/api/admin/integrations/apple` | DELETE, GET, PUT | `app/api/admin/integrations/apple/route.ts` |
| `/api/admin/integrations/google-play` | DELETE, GET, PUT | `app/api/admin/integrations/google-play/route.ts` |
| `/api/admin/integrations/sms` | GET, PATCH | `app/api/admin/integrations/sms/route.ts` |
| `/api/admin/integrations/sms/[providerKey]` | DELETE, PATCH, PUT | `app/api/admin/integrations/sms/[providerKey]/route.ts` |
| `/api/admin/integrations/sms/[providerKey]/test` | POST | `app/api/admin/integrations/sms/[providerKey]/test/route.ts` |
| `/api/admin/leaderboards` | GET, POST | `app/api/admin/leaderboards/route.ts` |
| `/api/admin/ledger` | GET | `app/api/admin/ledger/route.ts` |
| `/api/admin/live-tellers` | GET, POST | `app/api/admin/live-tellers/route.ts` |
| `/api/admin/live-tellers/[tellerId]` | DELETE, GET, PUT | `app/api/admin/live-tellers/[tellerId]/route.ts` |
| `/api/admin/live-tellers/[tellerId]/approve` | POST | `app/api/admin/live-tellers/[tellerId]/approve/route.ts` |
| `/api/admin/live-tellers/[tellerId]/ban` | POST | `app/api/admin/live-tellers/[tellerId]/ban/route.ts` |
| `/api/admin/live-tellers/[tellerId]/bonus` | POST | `app/api/admin/live-tellers/[tellerId]/bonus/route.ts` |
| `/api/admin/live-tellers/[tellerId]/freeze` | POST | `app/api/admin/live-tellers/[tellerId]/freeze/route.ts` |
| `/api/admin/live-tellers/[tellerId]/permissions` | PUT | `app/api/admin/live-tellers/[tellerId]/permissions/route.ts` |
| `/api/admin/live-tellers/[tellerId]/warning` | DELETE, POST | `app/api/admin/live-tellers/[tellerId]/warning/route.ts` |
| `/api/admin/lucky-gifts/tiers` | DELETE, GET, PATCH, POST | `app/api/admin/lucky-gifts/tiers/route.ts` |
| `/api/admin/membership-badges` | DELETE, GET, PATCH, POST | `app/api/admin/membership-badges/route.ts` |
| `/api/admin/membership-events` | DELETE, GET, POST, PUT | `app/api/admin/membership-events/route.ts` |
| `/api/admin/membership-features` | DELETE, GET, POST, PUT | `app/api/admin/membership-features/route.ts` |
| `/api/admin/membership-grants` | DELETE, GET, POST | `app/api/admin/membership-grants/route.ts` |
| `/api/admin/membership-reports` | GET | `app/api/admin/membership-reports/route.ts` |
| `/api/admin/membership-tiers` | DELETE, GET, POST, PUT | `app/api/admin/membership-tiers/route.ts` |
| `/api/admin/memberships` | DELETE, GET, POST, PUT | `app/api/admin/memberships/route.ts` |
| `/api/admin/memberships/purchases` | GET, PATCH, POST | `app/api/admin/memberships/purchases/route.ts` |
| `/api/admin/mic-frames` | GET | `app/api/admin/mic-frames/route.ts` |
| `/api/admin/moderation` | GET, POST | `app/api/admin/moderation/route.ts` |
| `/api/admin/name-effects` | GET | `app/api/admin/name-effects/route.ts` |
| `/api/admin/notifications` | DELETE, GET, POST | `app/api/admin/notifications/route.ts` |
| `/api/admin/online-fal/buttons` | DELETE, GET, PATCH, POST | `app/api/admin/online-fal/buttons/route.ts` |
| `/api/admin/online-fal/sections` | GET, PATCH, POST | `app/api/admin/online-fal/sections/route.ts` |
| `/api/admin/payment-methods` | GET, POST | `app/api/admin/payment-methods/route.ts` |
| `/api/admin/payments` | GET, POST | `app/api/admin/payments/route.ts` |
| `/api/admin/pending-counts` | GET | `app/api/admin/pending-counts/route.ts` |
| `/api/admin/platform-analytics` | GET | `app/api/admin/platform-analytics/route.ts` |
| `/api/admin/popups` | DELETE, GET, POST, PUT | `app/api/admin/popups/route.ts` |
| `/api/admin/premium-entrance` | GET, POST | `app/api/admin/premium-entrance/route.ts` |
| `/api/admin/profile-frames` | DELETE, GET, POST | `app/api/admin/profile-frames/route.ts` |
| `/api/admin/profile-frames/assign` | POST | `app/api/admin/profile-frames/assign/route.ts` |
| `/api/admin/referral-commission` | GET | `app/api/admin/referral-commission/route.ts` |
| `/api/admin/referral-commission/settings` | GET, PATCH | `app/api/admin/referral-commission/settings/route.ts` |
| `/api/admin/refunds` | GET, PATCH | `app/api/admin/refunds/route.ts` |
| `/api/admin/remote-config` | GET, POST | `app/api/admin/remote-config/route.ts` |
| `/api/admin/remote-config/[configId]` | DELETE, PATCH | `app/api/admin/remote-config/[configId]/route.ts` |
| `/api/admin/risk-events` | GET | `app/api/admin/risk-events/route.ts` |
| `/api/admin/risk-events/[eventId]` | PATCH | `app/api/admin/risk-events/[eventId]/route.ts` |
| `/api/admin/roles` | GET, POST | `app/api/admin/roles/route.ts` |
| `/api/admin/roles/[roleId]` | DELETE, PATCH | `app/api/admin/roles/[roleId]/route.ts` |
| `/api/admin/room-themes` | GET | `app/api/admin/room-themes/route.ts` |
| `/api/admin/room-themes/backgrounds` | GET, PATCH, POST | `app/api/admin/room-themes/backgrounds/route.ts` |
| `/api/admin/rooms` | GET, PATCH | `app/api/admin/rooms/route.ts` |
| `/api/admin/rtc-telemetry` | GET | `app/api/admin/rtc-telemetry/route.ts` |
| `/api/admin/seo-settings` | GET, POST | `app/api/admin/seo-settings/route.ts` |
| `/api/admin/settings` | GET, POST | `app/api/admin/settings/route.ts` |
| `/api/admin/site-pages` | DELETE, GET, POST, PUT | `app/api/admin/site-pages/route.ts` |
| `/api/admin/statistics` | GET | `app/api/admin/statistics/route.ts` |
| `/api/admin/support` | GET | `app/api/admin/support/route.ts` |
| `/api/admin/system-stats` | GET | `app/api/admin/system-stats/route.ts` |
| `/api/admin/teller-levels` | POST | `app/api/admin/teller-levels/route.ts` |
| `/api/admin/teller-performance` | GET | `app/api/admin/teller-performance/route.ts` |
| `/api/admin/teller-verification` | GET, POST | `app/api/admin/teller-verification/route.ts` |
| `/api/admin/ticker-messages` | GET, POST | `app/api/admin/ticker-messages/route.ts` |
| `/api/admin/ticker-messages/[messageId]` | DELETE, PATCH | `app/api/admin/ticker-messages/[messageId]/route.ts` |
| `/api/admin/tiktok-categories` | DELETE, GET, PATCH, POST | `app/api/admin/tiktok-categories/route.ts` |
| `/api/admin/tiktok-videos` | DELETE, GET, PATCH, POST, PUT | `app/api/admin/tiktok-videos/route.ts` |
| `/api/admin/topup-bonus-tiers` | GET, POST | `app/api/admin/topup-bonus-tiers/route.ts` |
| `/api/admin/topup-bonus-tiers/[id]` | DELETE, PATCH | `app/api/admin/topup-bonus-tiers/[id]/route.ts` |
| `/api/admin/tournaments` | GET, POST | `app/api/admin/tournaments/route.ts` |
| `/api/admin/trend-videos` | GET, POST | `app/api/admin/trend-videos/route.ts` |
| `/api/admin/trend-videos/youtube` | POST | `app/api/admin/trend-videos/youtube/route.ts` |
| `/api/admin/trends` | DELETE, GET, POST | `app/api/admin/trends/route.ts` |
| `/api/admin/users` | GET | `app/api/admin/users/route.ts` |
| `/api/admin/users/[userId]` | DELETE, GET, PATCH | `app/api/admin/users/[userId]/route.ts` |
| `/api/admin/users/[userId]/360` | GET | `app/api/admin/users/[userId]/360/route.ts` |
| `/api/admin/users/[userId]/manage` | GET, POST | `app/api/admin/users/[userId]/manage/route.ts` |
| `/api/admin/users/search` | GET | `app/api/admin/users/search/route.ts` |
| `/api/admin/users/withdrawal-limit` | POST | `app/api/admin/users/withdrawal-limit/route.ts` |
| `/api/admin/verification` | GET, PATCH | `app/api/admin/verification/route.ts` |
| `/api/admin/video-streams` | DELETE, GET, PATCH | `app/api/admin/video-streams/route.ts` |
| `/api/admin/visitor-stats` | GET | `app/api/admin/visitor-stats/route.ts` |
| `/api/admin/withdrawals` | GET, POST | `app/api/admin/withdrawals/route.ts` |
| `/api/announcements` | GET, POST | `app/api/announcements/route.ts` |
| `/api/announcements/event` | POST | `app/api/announcements/event/route.ts` |
| `/api/chat/rooms/[roomId]/dj` | GET, POST | `app/api/chat/rooms/[roomId]/dj/route.ts` |
| `/api/chat/rooms/[roomId]/pk` | GET, POST | `app/api/chat/rooms/[roomId]/pk/route.ts` |
| `/api/chat/rooms/[roomId]/pk/score` | POST | `app/api/chat/rooms/[roomId]/pk/score/route.ts` |
| `/api/chat/rooms/[roomId]/presence` | DELETE, GET, POST | `app/api/chat/rooms/[roomId]/presence/route.ts` |
| `/api/chat/rooms/[roomId]/transfer-ownership` | POST | `app/api/chat/rooms/[roomId]/transfer-ownership/route.ts` |
| `/api/dreams/[slug]/comments` | DELETE, GET, POST | `app/api/dreams/[slug]/comments/route.ts` |
| `/api/fortune-tellers/[tellerId]` | GET, PATCH | `app/api/fortune-tellers/[tellerId]/route.ts` |
| `/api/live/pk/score` | POST | `app/api/live/pk/score/route.ts` |
| `/api/short-videos/[id]/comments/[commentId]` | DELETE | `app/api/short-videos/[id]/comments/[commentId]/route.ts` |
| `/api/video-streams/[streamId]` | GET, PATCH | `app/api/video-streams/[streamId]/route.ts` |
| `/api/video-streams/[streamId]/end` | POST | `app/api/video-streams/[streamId]/end/route.ts` |
| `/api/video-streams/pk` | GET, POST | `app/api/video-streams/pk/route.ts` |

## WEB_ONLY (2)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/auth/verify-device` | GET | `app/api/auth/verify-device/route.ts` |
| `/api/monitoring` | GET | `app/api/monitoring/route.ts` |

## MISSING_MOBILE_SUPPORT (1)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/auth/reclaim-device` | POST | `app/api/auth/reclaim-device/route.ts` |

## INTERNAL (3)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/chat/cleanup` | DELETE, GET, POST | `app/api/chat/cleanup/route.ts` |
| `/api/cron/membership-expiry` | GET, POST | `app/api/cron/membership-expiry/route.ts` |
| `/api/dreams/morning-reminder` | POST | `app/api/dreams/morning-reminder/route.ts` |

## DEPRECATED_ALIAS (4)

| Yol | Metotlar | Dosya |
|---|---|---|
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | DELETE, POST | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block/route.ts` |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | DELETE, POST | `app/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject/route.ts` |
| `/api/membership/purchase` | POST | `app/api/membership/purchase/route.ts` |
| `/api/user/account/delete` | POST | `app/api/user/account/delete/route.ts` |
