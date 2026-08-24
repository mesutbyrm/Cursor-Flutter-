# Backend API route index (OpenAPI / endpoints_index)

**Kaynak:** `backend-docs/endpoints_index.json`
**Üretim:** `bash scripts/generate-api-route-index.sh`
**Not:** `nextjs_space/app/api/**/route.ts` repoda yok; A6 yedeği.

**Toplam:** 690 method-endpoint, 148 tag

## `activities` (1)

- `GET    /api/activities`

## `admin/activity-feed` (2)

- `GET    /api/admin/activity-feed`
- `POST   /api/admin/activity-feed`

## `admin/ad-networks` (3)

- `DELETE /api/admin/ad-networks`
- `GET    /api/admin/ad-networks`
- `POST   /api/admin/ad-networks`

## `admin/agencies` (3)

- `DELETE /api/admin/agencies`
- `GET    /api/admin/agencies`
- `PATCH  /api/admin/agencies`

## `admin/announcement-sections` (2)

- `GET    /api/admin/announcement-sections`
- `POST   /api/admin/announcement-sections`

## `admin/awards` (3)

- `DELETE /api/admin/awards`
- `GET    /api/admin/awards`
- `POST   /api/admin/awards`

## `admin/backup` (1)

- `GET    /api/admin/backup`

## `admin/badges` (4)

- `DELETE /api/admin/badges`
- `GET    /api/admin/badges`
- `POST   /api/admin/badges`
- `PUT    /api/admin/badges`

## `admin/bana-ozel` (3)

- `GET    /api/admin/bana-ozel`
- `PATCH  /api/admin/bana-ozel`
- `POST   /api/admin/bana-ozel`

## `admin/blog` (19)

- `DELETE /api/admin/blog/categories`
- `DELETE /api/admin/blog/{postId}`
- `GET    /api/admin/blog`
- `GET    /api/admin/blog/analytics`
- `GET    /api/admin/blog/categories`
- `GET    /api/admin/blog/comments`
- `PATCH  /api/admin/blog/bulk-category`
- `PATCH  /api/admin/blog/bulk-publish`
- `PATCH  /api/admin/blog/comments`
- `PATCH  /api/admin/blog/{postId}`
- `POST   /api/admin/blog`
- `POST   /api/admin/blog/bulk-delete`
- `POST   /api/admin/blog/bulk-generate`
- `POST   /api/admin/blog/bulk-import`
- `POST   /api/admin/blog/categories`
- `POST   /api/admin/blog/generate`
- `POST   /api/admin/blog/import`
- `POST   /api/admin/blog/schedule-publish`
- `PUT    /api/admin/blog/{postId}`

## `admin/bots` (10)

- `GET    /api/admin/bots`
- `GET    /api/admin/bots/simulate`
- `GET    /api/admin/bots/simulate-fortune`
- `GET    /api/admin/bots/simulate-master`
- `GET    /api/admin/bots/simulate-social`
- `PATCH  /api/admin/bots`
- `POST   /api/admin/bots/simulate`
- `POST   /api/admin/bots/simulate-fortune`
- `POST   /api/admin/bots/simulate-master`
- `POST   /api/admin/bots/simulate-social`

## `admin/broadcast-images` (4)

- `DELETE /api/admin/broadcast-images`
- `GET    /api/admin/broadcast-images`
- `PATCH  /api/admin/broadcast-images`
- `POST   /api/admin/broadcast-images`

## `admin/button-order` (2)

- `GET    /api/admin/button-order`
- `POST   /api/admin/button-order`

## `admin/cache` (2)

- `DELETE /api/admin/cache`
- `GET    /api/admin/cache`

## `admin/cfc-payment-requests` (2)

- `GET    /api/admin/cfc-payment-requests`
- `PATCH  /api/admin/cfc-payment-requests`

## `admin/cfc-settings` (2)

- `GET    /api/admin/cfc-settings`
- `POST   /api/admin/cfc-settings`

## `admin/chat-rooms` (4)

- `DELETE /api/admin/chat-rooms`
- `GET    /api/admin/chat-rooms`
- `POST   /api/admin/chat-rooms`
- `PUT    /api/admin/chat-rooms`

## `admin/contests` (4)

- `DELETE /api/admin/contests`
- `GET    /api/admin/contests`
- `PATCH  /api/admin/contests`
- `POST   /api/admin/contests`

## `admin/credit-packages` (4)

- `DELETE /api/admin/credit-packages/{packageId}`
- `GET    /api/admin/credit-packages`
- `PATCH  /api/admin/credit-packages/{packageId}`
- `POST   /api/admin/credit-packages`

## `admin/credits` (1)

- `POST   /api/admin/credits`

## `admin/currency-config` (3)

- `GET    /api/admin/currency-config`
- `POST   /api/admin/currency-config`
- `PUT    /api/admin/currency-config`

## `admin/dreams` (9)

- `DELETE /api/admin/dreams`
- `GET    /api/admin/dreams`
- `PATCH  /api/admin/dreams/bulk-category`
- `PATCH  /api/admin/dreams/bulk-publish`
- `POST   /api/admin/dreams`
- `POST   /api/admin/dreams/bulk-delete`
- `POST   /api/admin/dreams/bulk-import`
- `POST   /api/admin/dreams/generate`
- `PUT    /api/admin/dreams`

## `admin/finance` (2)

- `GET    /api/admin/finance`
- `POST   /api/admin/finance`

## `admin/fortune-request-types` (4)

- `DELETE /api/admin/fortune-request-types`
- `GET    /api/admin/fortune-request-types`
- `PATCH  /api/admin/fortune-request-types`
- `POST   /api/admin/fortune-request-types`

## `admin/fortunes` (1)

- `GET    /api/admin/fortunes`

## `admin/games` (8)

- `DELETE /api/admin/games`
- `DELETE /api/admin/games/rooms`
- `GET    /api/admin/games`
- `GET    /api/admin/games/rooms`
- `GET    /api/admin/games/settings`
- `POST   /api/admin/games`
- `PUT    /api/admin/games`
- `PUT    /api/admin/games/settings`

## `admin/gift-collections` (3)

- `GET    /api/admin/gift-collections`
- `PATCH  /api/admin/gift-collections`
- `POST   /api/admin/gift-collections`

## `admin/gift-upload` (1)

- `POST   /api/admin/gift-upload`

## `admin/gifts` (6)

- `DELETE /api/admin/gifts/{giftId}`
- `GET    /api/admin/gifts`
- `GET    /api/admin/gifts/stats`
- `GET    /api/admin/gifts/{giftId}`
- `PATCH  /api/admin/gifts/{giftId}`
- `POST   /api/admin/gifts`

## `admin/homepage-buttons` (4)

- `DELETE /api/admin/homepage-buttons`
- `GET    /api/admin/homepage-buttons`
- `PATCH  /api/admin/homepage-buttons`
- `POST   /api/admin/homepage-buttons`

## `admin/homepage-fortune-cards` (5)

- `DELETE /api/admin/homepage-fortune-cards`
- `GET    /api/admin/homepage-fortune-cards`
- `PATCH  /api/admin/homepage-fortune-cards`
- `POST   /api/admin/homepage-fortune-cards`
- `PUT    /api/admin/homepage-fortune-cards`

## `admin/live-tellers` (12)

- `DELETE /api/admin/live-tellers/{tellerId}`
- `DELETE /api/admin/live-tellers/{tellerId}/warning`
- `GET    /api/admin/live-tellers`
- `GET    /api/admin/live-tellers/{tellerId}`
- `POST   /api/admin/live-tellers`
- `POST   /api/admin/live-tellers/{tellerId}/approve`
- `POST   /api/admin/live-tellers/{tellerId}/ban`
- `POST   /api/admin/live-tellers/{tellerId}/bonus`
- `POST   /api/admin/live-tellers/{tellerId}/freeze`
- `POST   /api/admin/live-tellers/{tellerId}/warning`
- `PUT    /api/admin/live-tellers/{tellerId}`
- `PUT    /api/admin/live-tellers/{tellerId}/permissions`

## `admin/lucky-gifts` (4)

- `DELETE /api/admin/lucky-gifts/tiers`
- `GET    /api/admin/lucky-gifts/tiers`
- `PATCH  /api/admin/lucky-gifts/tiers`
- `POST   /api/admin/lucky-gifts/tiers`

## `admin/membership-badges` (4)

- `DELETE /api/admin/membership-badges`
- `GET    /api/admin/membership-badges`
- `PATCH  /api/admin/membership-badges`
- `POST   /api/admin/membership-badges`

## `admin/memberships` (7)

- `DELETE /api/admin/memberships`
- `GET    /api/admin/memberships`
- `GET    /api/admin/memberships/purchases`
- `PATCH  /api/admin/memberships/purchases`
- `POST   /api/admin/memberships`
- `POST   /api/admin/memberships/purchases`
- `PUT    /api/admin/memberships`

## `admin/moderation` (2)

- `GET    /api/admin/moderation`
- `POST   /api/admin/moderation`

## `admin/notifications` (3)

- `DELETE /api/admin/notifications`
- `GET    /api/admin/notifications`
- `POST   /api/admin/notifications`

## `admin/online-fal` (7)

- `DELETE /api/admin/online-fal/buttons`
- `GET    /api/admin/online-fal/buttons`
- `GET    /api/admin/online-fal/sections`
- `PATCH  /api/admin/online-fal/buttons`
- `PATCH  /api/admin/online-fal/sections`
- `POST   /api/admin/online-fal/buttons`
- `POST   /api/admin/online-fal/sections`

## `admin/payment-methods` (2)

- `GET    /api/admin/payment-methods`
- `POST   /api/admin/payment-methods`

## `admin/payments` (3)

- `GET    /api/admin/payments`
- `PATCH  /api/admin/payments`
- `POST   /api/admin/payments`

## `admin/pending-counts` (1)

- `GET    /api/admin/pending-counts`

## `admin/popups` (4)

- `DELETE /api/admin/popups`
- `GET    /api/admin/popups`
- `POST   /api/admin/popups`
- `PUT    /api/admin/popups`

## `admin/profile-frames` (4)

- `DELETE /api/admin/profile-frames`
- `GET    /api/admin/profile-frames`
- `POST   /api/admin/profile-frames`
- `POST   /api/admin/profile-frames/assign`

## `admin/room-themes` (3)

- `GET    /api/admin/room-themes/backgrounds`
- `PATCH  /api/admin/room-themes/backgrounds`
- `POST   /api/admin/room-themes/backgrounds`

## `admin/rooms` (2)

- `GET    /api/admin/rooms`
- `PATCH  /api/admin/rooms`

## `admin/seo-settings` (2)

- `GET    /api/admin/seo-settings`
- `POST   /api/admin/seo-settings`

## `admin/settings` (2)

- `GET    /api/admin/settings`
- `POST   /api/admin/settings`

## `admin/site-pages` (4)

- `DELETE /api/admin/site-pages`
- `GET    /api/admin/site-pages`
- `POST   /api/admin/site-pages`
- `PUT    /api/admin/site-pages`

## `admin/statistics` (1)

- `GET    /api/admin/statistics`

## `admin/teller-levels` (1)

- `POST   /api/admin/teller-levels`

## `admin/teller-performance` (1)

- `GET    /api/admin/teller-performance`

## `admin/teller-verification` (2)

- `GET    /api/admin/teller-verification`
- `POST   /api/admin/teller-verification`

## `admin/ticker-messages` (4)

- `DELETE /api/admin/ticker-messages/{messageId}`
- `GET    /api/admin/ticker-messages`
- `PATCH  /api/admin/ticker-messages/{messageId}`
- `POST   /api/admin/ticker-messages`

## `admin/tiktok-categories` (4)

- `DELETE /api/admin/tiktok-categories`
- `GET    /api/admin/tiktok-categories`
- `PATCH  /api/admin/tiktok-categories`
- `POST   /api/admin/tiktok-categories`

## `admin/tiktok-videos` (5)

- `DELETE /api/admin/tiktok-videos`
- `GET    /api/admin/tiktok-videos`
- `PATCH  /api/admin/tiktok-videos`
- `POST   /api/admin/tiktok-videos`
- `PUT    /api/admin/tiktok-videos`

## `admin/trend-videos` (3)

- `GET    /api/admin/trend-videos`
- `POST   /api/admin/trend-videos`
- `POST   /api/admin/trend-videos/youtube`

## `admin/trends` (3)

- `DELETE /api/admin/trends`
- `GET    /api/admin/trends`
- `POST   /api/admin/trends`

## `admin/users` (6)

- `DELETE /api/admin/users/{userId}`
- `GET    /api/admin/users`
- `GET    /api/admin/users/search`
- `GET    /api/admin/users/{userId}`
- `PATCH  /api/admin/users/{userId}`
- `POST   /api/admin/users/withdrawal-limit`

## `admin/video-streams` (3)

- `DELETE /api/admin/video-streams`
- `GET    /api/admin/video-streams`
- `PATCH  /api/admin/video-streams`

## `admin/visitor-stats` (1)

- `GET    /api/admin/visitor-stats`

## `admin/withdrawals` (2)

- `GET    /api/admin/withdrawals`
- `POST   /api/admin/withdrawals`

## `ads` (2)

- `GET    /api/ads/active`
- `POST   /api/ads/reward`

## `agency` (16)

- `DELETE /api/agency/leave`
- `DELETE /api/agency/members`
- `GET    /api/agency/earnings`
- `GET    /api/agency/invite`
- `GET    /api/agency/leaderboard`
- `GET    /api/agency/members`
- `GET    /api/agency/my`
- `GET    /api/agency/tasks`
- `GET    /api/agency/withdrawals`
- `PATCH  /api/agency/my`
- `POST   /api/agency/apply`
- `POST   /api/agency/invite`
- `POST   /api/agency/join`
- `POST   /api/agency/leave`
- `POST   /api/agency/members`
- `POST   /api/agency/withdrawals`

## `announcements` (3)

- `GET    /api/announcements`
- `POST   /api/announcements`
- `POST   /api/announcements/event`

## `anonymous` (3)

- `GET    /api/anonymous`
- `POST   /api/anonymous`
- `POST   /api/anonymous/watch-ad`

## `astrology-panel` (1)

- `GET    /api/astrology-panel`

## `auth` (14)

- `GET    /api/auth/verify-device`
- `GET    /api/auth/{nextauth}`
- `POST   /api/auth/change-password`
- `POST   /api/auth/forgot-password`
- `POST   /api/auth/logout`
- `POST   /api/auth/mobile-apple`
- `POST   /api/auth/mobile-google`
- `POST   /api/auth/mobile-login`
- `POST   /api/auth/mobile-refresh`
- `POST   /api/auth/mobile-register`
- `POST   /api/auth/mobile-tiktok`
- `POST   /api/auth/reclaim-device`
- `POST   /api/auth/reset-password`
- `POST   /api/auth/{nextauth}`

## `bana-ozel` (2)

- `GET    /api/bana-ozel`
- `POST   /api/bana-ozel/open`

## `blog` (10)

- `DELETE /api/blog/comments`
- `GET    /api/blog`
- `GET    /api/blog/categories`
- `GET    /api/blog/comments`
- `GET    /api/blog/interactions`
- `GET    /api/blog/related`
- `GET    /api/blog/zodiac`
- `POST   /api/blog/comments`
- `POST   /api/blog/favorite`
- `POST   /api/blog/like`

## `broadcast-images` (1)

- `GET    /api/broadcast-images`

## `cache` (2)

- `GET    /api/cache`
- `POST   /api/cache`

## `chat` (43)

- `DELETE /api/chat/cleanup`
- `DELETE /api/chat/rooms/{roomId}/messages`
- `DELETE /api/chat/rooms/{roomId}/music`
- `DELETE /api/chat/rooms/{roomId}/presence`
- `GET    /api/chat/broadcast-images`
- `GET    /api/chat/cleanup`
- `GET    /api/chat/rooms`
- `GET    /api/chat/rooms/backgrounds`
- `GET    /api/chat/rooms/pk-list`
- `GET    /api/chat/rooms/{roomId}/dj`
- `GET    /api/chat/rooms/{roomId}/gifts`
- `GET    /api/chat/rooms/{roomId}/messages`
- `GET    /api/chat/rooms/{roomId}/moderation`
- `GET    /api/chat/rooms/{roomId}/music`
- `GET    /api/chat/rooms/{roomId}/music-queue`
- `GET    /api/chat/rooms/{roomId}/pk`
- `GET    /api/chat/rooms/{roomId}/presence`
- `GET    /api/chat/rooms/{roomId}/seats`
- `GET    /api/chat/rooms/{roomId}/settings`
- `GET    /api/chat/rooms/{roomId}/song-request`
- `GET    /api/chat/rooms/{roomId}/state`
- `GET    /api/chat/rooms/{roomId}/stream`
- `GET    /api/chat/rooms/{roomId}/typing`
- `GET    /api/chat/rooms/{roomId}/voice`
- `GET    /api/chat/youtube-stream`
- `PATCH  /api/chat/rooms/{roomId}/seats`
- `PATCH  /api/chat/rooms/{roomId}/settings`
- `PATCH  /api/chat/rooms/{roomId}/song-request`
- `POST   /api/chat/cleanup`
- `POST   /api/chat/rooms/create`
- `POST   /api/chat/rooms/{roomId}/dj`
- `POST   /api/chat/rooms/{roomId}/gifts`
- `POST   /api/chat/rooms/{roomId}/messages`
- `POST   /api/chat/rooms/{roomId}/moderation`
- `POST   /api/chat/rooms/{roomId}/music`
- `POST   /api/chat/rooms/{roomId}/music/stop`
- `POST   /api/chat/rooms/{roomId}/pk`
- `POST   /api/chat/rooms/{roomId}/pk/score`
- `POST   /api/chat/rooms/{roomId}/presence`
- `POST   /api/chat/rooms/{roomId}/song-request`
- `POST   /api/chat/rooms/{roomId}/transfer-ownership`
- `POST   /api/chat/rooms/{roomId}/typing`
- `POST   /api/chat/rooms/{roomId}/voice`

## `compatibility` (1)

- `POST   /api/compatibility`

## `contact` (1)

- `POST   /api/contact`

## `credit-packages` (1)

- `GET    /api/credit-packages`

## `daily-login` (2)

- `GET    /api/daily-login`
- `POST   /api/daily-login`

## `daily-missions` (2)

- `GET    /api/daily-missions`
- `POST   /api/daily-missions`

## `devices` (2)

- `DELETE /api/devices/fcm`
- `POST   /api/devices/fcm`

## `dream-contest` (4)

- `GET    /api/dream-contest`
- `GET    /api/dream-contest/{contestId}/entries`
- `POST   /api/dream-contest/{contestId}/entries`
- `POST   /api/dream-contest/{contestId}/vote`

## `dream-diary` (3)

- `DELETE /api/dream-diary`
- `GET    /api/dream-diary`
- `POST   /api/dream-diary`

## `dream-stats` (1)

- `GET    /api/dream-stats`

## `dream-symbols` (2)

- `GET    /api/dream-symbols`
- `GET    /api/dream-symbols/{slug}`

## `dreams` (14)

- `DELETE /api/dreams/{slug}/comments`
- `GET    /api/dreams`
- `GET    /api/dreams/favorites`
- `GET    /api/dreams/recommendations`
- `GET    /api/dreams/trends`
- `GET    /api/dreams/{slug}`
- `GET    /api/dreams/{slug}/comments`
- `GET    /api/dreams/{slug}/favorite`
- `POST   /api/dreams/generate`
- `POST   /api/dreams/interpret`
- `POST   /api/dreams/morning-reminder`
- `POST   /api/dreams/{slug}/comments`
- `POST   /api/dreams/{slug}/favorite`
- `POST   /api/dreams/{slug}/view`

## `favorite-tellers` (2)

- `GET    /api/favorite-tellers`
- `POST   /api/favorite-tellers`

## `football` (1)

- `GET    /api/football`

## `fortune-access` (2)

- `GET    /api/fortune-access/ip-status`
- `POST   /api/fortune-access/check`

## `fortune-request-types` (1)

- `GET    /api/fortune-request-types`

## `fortune-tellers` (18)

- `GET    /api/fortune-tellers`
- `GET    /api/fortune-tellers/awards`
- `GET    /api/fortune-tellers/gifts`
- `GET    /api/fortune-tellers/my-profile`
- `GET    /api/fortune-tellers/session`
- `GET    /api/fortune-tellers/sessions`
- `GET    /api/fortune-tellers/sessions/stream`
- `GET    /api/fortune-tellers/toggle-online`
- `GET    /api/fortune-tellers/{tellerId}`
- `GET    /api/fortune-tellers/{tellerId}/reviews`
- `GET    /api/fortune-tellers/{tellerId}/session`
- `PATCH  /api/fortune-tellers/sessions/{sessionId}`
- `PATCH  /api/fortune-tellers/{tellerId}`
- `POST   /api/fortune-tellers`
- `POST   /api/fortune-tellers/apply`
- `POST   /api/fortune-tellers/session`
- `POST   /api/fortune-tellers/toggle-online`
- `POST   /api/fortune-tellers/{tellerId}/session`

## `fortunes` (15)

- `POST   /api/fortunes/ask-uyumu`
- `POST   /api/fortunes/aura-analizi`
- `POST   /api/fortunes/burc-yorumu`
- `POST   /api/fortunes/dogum-haritasi`
- `POST   /api/fortunes/el-fali`
- `POST   /api/fortunes/evet-hayir`
- `POST   /api/fortunes/istihare`
- `POST   /api/fortunes/kahve-fali`
- `POST   /api/fortunes/kahve-fali-image`
- `POST   /api/fortunes/katina`
- `POST   /api/fortunes/kursundokme`
- `POST   /api/fortunes/melek-kartlari`
- `POST   /api/fortunes/numeroloji`
- `POST   /api/fortunes/ruya-yorumu`
- `POST   /api/fortunes/tarot-fali`

## `games` (38)

- `DELETE /api/games/room/{roomId}`
- `DELETE /api/games/room/{roomId}/viewers`
- `DELETE /api/games/sos/{gameId}`
- `DELETE /api/games/sos/{gameId}/viewers`
- `GET    /api/games`
- `GET    /api/games/daily-reward`
- `GET    /api/games/grid-settings`
- `GET    /api/games/lamba-cini`
- `GET    /api/games/leaderboard`
- `GET    /api/games/lobby`
- `GET    /api/games/profile`
- `GET    /api/games/quests`
- `GET    /api/games/room`
- `GET    /api/games/room/{roomId}`
- `GET    /api/games/room/{roomId}/chat`
- `GET    /api/games/room/{roomId}/viewers`
- `GET    /api/games/sos`
- `GET    /api/games/sos/{gameId}`
- `GET    /api/games/sos/{gameId}/chat`
- `GET    /api/games/sos/{gameId}/viewers`
- `PATCH  /api/games/room/{roomId}`
- `PATCH  /api/games/room/{roomId}/chat`
- `PATCH  /api/games/sos/{gameId}`
- `PATCH  /api/games/sos/{gameId}/chat`
- `POST   /api/games/daily-reward`
- `POST   /api/games/daily-spin`
- `POST   /api/games/lamba-cini`
- `POST   /api/games/play`
- `POST   /api/games/quests`
- `POST   /api/games/room`
- `POST   /api/games/room/{roomId}`
- `POST   /api/games/room/{roomId}/chat`
- `POST   /api/games/room/{roomId}/replace-ai`
- `POST   /api/games/room/{roomId}/viewers`
- `POST   /api/games/sos`
- `POST   /api/games/sos/{gameId}`
- `POST   /api/games/sos/{gameId}/chat`
- `POST   /api/games/sos/{gameId}/viewers`

## `gift-engine` (3)

- `GET    /api/gift-engine/gifts`
- `GET    /api/gift-engine/queue`
- `POST   /api/gift-engine/finish`

## `gifts` (9)

- `GET    /api/gifts/catalog`
- `GET    /api/gifts/lucky/config`
- `GET    /api/gifts/lucky/history`
- `GET    /api/gifts/recent-big`
- `GET    /api/gifts/types`
- `GET    /api/gifts/version`
- `POST   /api/gifts/check-reciprocal`
- `POST   /api/gifts/lucky/send`
- `POST   /api/gifts/send`

## `hashtags` (3)

- `GET    /api/hashtags/search`
- `GET    /api/hashtags/trending`
- `GET    /api/hashtags/{name}`

## `homepage-buttons` (1)

- `GET    /api/homepage-buttons`

## `homepage-fortune-cards` (1)

- `GET    /api/homepage-fortune-cards`

## `homepage-ticker` (1)

- `GET    /api/homepage-ticker`

## `horoscope` (1)

- `GET    /api/horoscope/daily`

## `jeton` (2)

- `GET    /api/jeton`
- `POST   /api/jeton`

## `leaderboards` (1)

- `GET    /api/leaderboards`

## `legal` (1)

- `GET    /api/legal/child-safety`

## `live` (15)

- `GET    /api/live/gift-types`
- `GET    /api/live/message`
- `GET    /api/live/online-users`
- `GET    /api/live/pk`
- `GET    /api/live/rooms`
- `GET    /api/live/seats`
- `POST   /api/live/create-room`
- `POST   /api/live/gift/send`
- `POST   /api/live/heartbeat`
- `POST   /api/live/join-room`
- `POST   /api/live/leave-room`
- `POST   /api/live/message`
- `POST   /api/live/pk`
- `POST   /api/live/pk/score`
- `POST   /api/live/seats`

## `me` (2)

- `GET    /api/me`
- `PATCH  /api/me`

## `membership-badges` (1)

- `GET    /api/membership-badges`

## `memberships` (3)

- `GET    /api/memberships`
- `GET    /api/memberships/packages`
- `POST   /api/memberships/purchase`

## `messages` (5)

- `GET    /api/messages`
- `GET    /api/messages/{userId}`
- `PATCH  /api/messages/request`
- `POST   /api/messages/request`
- `POST   /api/messages/{userId}`

## `mobile` (4)

- `GET    /api/mobile/config`
- `GET    /api/mobile/fortune-menu`
- `GET    /api/mobile/home`
- `GET    /api/mobile/user-profile/{userId}`

## `monitoring` (1)

- `GET    /api/monitoring`

## `music` (2)

- `GET    /api/music/history`
- `GET    /api/music/search`

## `notifications` (4)

- `DELETE /api/notifications`
- `GET    /api/notifications`
- `GET    /api/notifications/stream`
- `POST   /api/notifications`

## `online-fal` (1)

- `GET    /api/online-fal`

## `payments` (7)

- `GET    /api/payments/config`
- `GET    /api/payments/methods`
- `GET    /api/payments/notify`
- `GET    /api/payments/requests`
- `GET    /api/payments/settings`
- `POST   /api/payments/notify`
- `POST   /api/payments/requests`

## `platform` (1)

- `GET    /api/platform/commission-rate`

## `popups` (1)

- `GET    /api/popups`

## `presence` (3)

- `GET    /api/presence`
- `GET    /api/presence/sections`
- `POST   /api/presence`

## `profile-frames` (2)

- `GET    /api/profile-frames`
- `POST   /api/profile-frames`

## `public` (2)

- `GET    /api/public/announcement-settings`
- `GET    /api/public/jeton-price`

## `public-stats` (1)

- `GET    /api/public-stats`

## `referral` (2)

- `GET    /api/referral`
- `GET    /api/referral/validate`

## `room` (12)

- `DELETE /api/room/signal`
- `GET    /api/room/signal`
- `GET    /api/room/{sessionId}`
- `GET    /api/room/{sessionId}/messages`
- `GET    /api/room/{sessionId}/review`
- `GET    /api/room/{sessionId}/stream`
- `GET    /api/room/{sessionId}/summary`
- `PATCH  /api/room/{sessionId}`
- `POST   /api/room/signal`
- `POST   /api/room/{sessionId}/messages`
- `POST   /api/room/{sessionId}/review`
- `POST   /api/room/{sessionId}/tip`

## `room-themes` (1)

- `GET    /api/room-themes/catalog`

## `search` (2)

- `GET    /api/search`
- `GET    /api/search/advanced`

## `seo-settings` (1)

- `GET    /api/seo-settings`

## `settings` (4)

- `GET    /api/settings/ads`
- `GET    /api/settings/canlidark-hero`
- `GET    /api/settings/public`
- `GET    /api/settings/themes`

## `share-card` (1)

- `GET    /api/share-card`

## `short-videos` (21)

- `DELETE /api/short-videos/{id}`
- `DELETE /api/short-videos/{id}/comments/{commentId}`
- `GET    /api/short-videos`
- `GET    /api/short-videos/explore`
- `GET    /api/short-videos/mentions/search`
- `GET    /api/short-videos/music`
- `GET    /api/short-videos/profile/{userId}`
- `GET    /api/short-videos/user/{userId}`
- `GET    /api/short-videos/{id}`
- `GET    /api/short-videos/{id}/comments`
- `GET    /api/short-videos/{id}/duets`
- `POST   /api/short-videos/register`
- `POST   /api/short-videos/upload`
- `POST   /api/short-videos/upload-url`
- `POST   /api/short-videos/{id}/comments`
- `POST   /api/short-videos/{id}/comments/{commentId}/like`
- `POST   /api/short-videos/{id}/comments/{commentId}/pin`
- `POST   /api/short-videos/{id}/like`
- `POST   /api/short-videos/{id}/save`
- `POST   /api/short-videos/{id}/share`
- `POST   /api/short-videos/{id}/view`

## `signup` (1)

- `POST   /api/signup`

## `site-pages` (1)

- `GET    /api/site-pages/{slug}`

## `social` (9)

- `DELETE /api/social/posts/{postId}`
- `DELETE /api/social/posts/{postId}/comments`
- `GET    /api/social/posts`
- `GET    /api/social/posts/{postId}`
- `GET    /api/social/posts/{postId}/comments`
- `POST   /api/social/posts`
- `POST   /api/social/posts/{postId}/comments`
- `POST   /api/social/posts/{postId}/likes`
- `POST   /api/social/posts/{postId}/view`

## `stories` (3)

- `DELETE /api/stories`
- `GET    /api/stories`
- `POST   /api/stories`

## `teller` (4)

- `GET    /api/teller/analytics`
- `GET    /api/teller/level`
- `GET    /api/teller/verification`
- `POST   /api/teller/verification`

## `teller-chat` (3)

- `GET    /api/teller-chat`
- `GET    /api/teller-chat/{sessionId}`
- `POST   /api/teller-chat/{sessionId}`

## `tencent` (1)

- `POST   /api/tencent/webhook`

## `tiktok-videos` (3)

- `GET    /api/tiktok-videos`
- `GET    /api/tiktok-videos/oembed`
- `GET    /api/tiktok-videos/{id}`

## `tmdb` (1)

- `GET    /api/tmdb`

## `tournaments` (1)

- `GET    /api/tournaments`

## `translations` (1)

- `GET    /api/translations`

## `trend-videos` (2)

- `GET    /api/trend-videos`
- `POST   /api/trend-videos`

## `trends` (3)

- `GET    /api/trends`
- `GET    /api/trends/{slug}`
- `POST   /api/trends/{slug}/like`

## `trtc` (3)

- `POST   /api/trtc/token`
- `POST   /api/trtc/usersig`
- `POST   /api/trtc/webhook`

## `upload` (3)

- `GET    /api/upload/get-url`
- `POST   /api/upload/get-url`
- `POST   /api/upload/presigned`

## `user` (32)

- `DELETE /api/user/blocked`
- `DELETE /api/user/{userId}/follow`
- `GET    /api/user/achievements`
- `GET    /api/user/active-sessions`
- `GET    /api/user/activity`
- `GET    /api/user/block`
- `GET    /api/user/blocked`
- `GET    /api/user/broadcast-history`
- `GET    /api/user/co-broadcast-invites`
- `GET    /api/user/credits`
- `GET    /api/user/followers`
- `GET    /api/user/following`
- `GET    /api/user/fortunes`
- `GET    /api/user/likers`
- `GET    /api/user/profile`
- `GET    /api/user/received-gifts`
- `GET    /api/user/statistics`
- `GET    /api/user/stats`
- `GET    /api/user/theme`
- `GET    /api/user/watch-ad`
- `GET    /api/user/xp`
- `GET    /api/user/{userId}/achievements`
- `GET    /api/user/{userId}/follow-status`
- `PATCH  /api/user/activity`
- `PATCH  /api/user/fortunes/{fortuneId}`
- `PATCH  /api/user/profile`
- `PATCH  /api/user/theme`
- `POST   /api/user/block`
- `POST   /api/user/report`
- `POST   /api/user/stats`
- `POST   /api/user/watch-ad`
- `POST   /api/user/{userId}/follow`

## `users` (7)

- `GET    /api/users/lookup/{username}`
- `GET    /api/users/online`
- `GET    /api/users/search`
- `GET    /api/users/{userId}`
- `GET    /api/users/{userId}/follow`
- `GET    /api/users/{userId}/posts`
- `POST   /api/users/{userId}/follow`

## `video-streams` (52)

- `DELETE /api/video-streams/signal`
- `DELETE /api/video-streams/{streamId}/ban`
- `DELETE /api/video-streams/{streamId}/fortune-requests`
- `DELETE /api/video-streams/{streamId}/join`
- `DELETE /api/video-streams/{streamId}/moderators`
- `DELETE /api/video-streams/{streamId}/mute`
- `DELETE /api/video-streams/{streamId}/signal`
- `GET    /api/video-streams`
- `GET    /api/video-streams/gifts`
- `GET    /api/video-streams/pk`
- `GET    /api/video-streams/pk/list`
- `GET    /api/video-streams/signal`
- `GET    /api/video-streams/{streamId}`
- `GET    /api/video-streams/{streamId}/auto-close`
- `GET    /api/video-streams/{streamId}/ban`
- `GET    /api/video-streams/{streamId}/co-broadcast`
- `GET    /api/video-streams/{streamId}/comments`
- `GET    /api/video-streams/{streamId}/fortune-requests`
- `GET    /api/video-streams/{streamId}/fortune-requests/my-status`
- `GET    /api/video-streams/{streamId}/gifts`
- `GET    /api/video-streams/{streamId}/like`
- `GET    /api/video-streams/{streamId}/messages`
- `GET    /api/video-streams/{streamId}/moderators`
- `GET    /api/video-streams/{streamId}/mute`
- `GET    /api/video-streams/{streamId}/pk-battle`
- `GET    /api/video-streams/{streamId}/signal`
- `GET    /api/video-streams/{streamId}/stream`
- `GET    /api/video-streams/{streamId}/viewers`
- `PATCH  /api/video-streams/{streamId}`
- `PATCH  /api/video-streams/{streamId}/co-broadcast`
- `PATCH  /api/video-streams/{streamId}/fortune-requests`
- `POST   /api/video-streams`
- `POST   /api/video-streams/pk`
- `POST   /api/video-streams/pk/score`
- `POST   /api/video-streams/signal`
- `POST   /api/video-streams/{streamId}/auto-close`
- `POST   /api/video-streams/{streamId}/ban`
- `POST   /api/video-streams/{streamId}/co-broadcast`
- `POST   /api/video-streams/{streamId}/co-broadcast/invite`
- `POST   /api/video-streams/{streamId}/comments`
- `POST   /api/video-streams/{streamId}/end`
- `POST   /api/video-streams/{streamId}/fortune-requests`
- `POST   /api/video-streams/{streamId}/gifts`
- `POST   /api/video-streams/{streamId}/join`
- `POST   /api/video-streams/{streamId}/leave`
- `POST   /api/video-streams/{streamId}/like`
- `POST   /api/video-streams/{streamId}/live-started`
- `POST   /api/video-streams/{streamId}/messages`
- `POST   /api/video-streams/{streamId}/moderators`
- `POST   /api/video-streams/{streamId}/mute`
- `POST   /api/video-streams/{streamId}/pk-battle`
- `POST   /api/video-streams/{streamId}/signal`

## `wallet` (1)

- `GET    /api/wallet`

## `warmup` (1)

- `GET    /api/warmup`

## `weekly-dream-report` (2)

- `GET    /api/weekly-dream-report`
- `POST   /api/weekly-dream-report`

## `withdrawals` (2)

- `GET    /api/withdrawals`
- `POST   /api/withdrawals`

## `youtube` (1)

- `GET    /api/youtube/search`
