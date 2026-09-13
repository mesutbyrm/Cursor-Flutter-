# Abacus ZIP → Flutter yol haritası

> **Üretim:** 2026-09-13 02:19 UTC

## Durum özeti

| Metrik | Değer |
|--------|------:|
| `FLUTTER_READY` path (unique) | 306 |
| Mobil tarafta iz (endpoint const veya kullanım) | ~306 |
| Eksik / kısmi (tahmini) | ~0 |

Aşağıdaki tablolar **otomatik taramadır**; `PARTIAL` = path var ama datasource/UI eksik olabilir.

## §1 — Kimlik & Oturum

**18/18** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/auth/change-password` | POST | ✅ |
| `/api/auth/email/send-verification` | POST | ✅ |
| `/api/auth/logout` | POST | ✅ |
| `/api/auth/logout-all` | POST | ✅ |
| `/api/auth/mobile-apple` | POST | ✅ |
| `/api/auth/mobile-google` | POST | ✅ |
| `/api/auth/mobile-login` | POST | ✅ |
| `/api/auth/mobile-refresh` | POST | ✅ |
| `/api/auth/mobile-register` | POST | ✅ |
| `/api/auth/mobile-tiktok` | POST | ✅ |
| `/api/auth/phone/send-otp` | POST | ✅ |
| `/api/auth/phone/verify-otp` | POST | ✅ |
| `/api/auth/sessions` | DELETE, GET | ✅ |
| `/api/devices/fcm` | DELETE, POST | ✅ |
| `/api/mobile/fortune-menu` | GET | ✅ |
| `/api/mobile/home` | GET | ✅ |
| `/api/mobile/user-profile/[userId]` | GET | ✅ |
| `/api/verification` | GET, POST | ✅ |

## §2 — Kullanıcı Profili & Ayarlar

**47/47** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/activities` | GET | ✅ |
| `/api/me` | GET, PATCH | ✅ |
| `/api/me/admin-capabilities` | GET | ✅ |
| `/api/me/membership` | GET | ✅ |
| `/api/me/membership-events` | GET | ✅ |
| `/api/me/membership-history` | GET, PUT | ✅ |
| `/api/me/profile-visitors` | GET, POST | ✅ |
| `/api/me/vip-identity` | GET, PUT | ✅ |
| `/api/me/vip-preferences` | GET, PUT | ✅ |
| `/api/me/vip-xp` | GET, POST | ✅ |
| `/api/presence` | GET, POST | ✅ |
| `/api/upload/get-url` | GET, POST | ✅ |
| `/api/upload/presigned` | POST | ✅ |
| `/api/user/[userId]/achievements` | GET | ✅ |
| `/api/user/[userId]/follow` | DELETE, POST | ✅ |
| `/api/user/[userId]/follow-status` | GET | ✅ |
| `/api/user/account` | DELETE, POST | ✅ |
| `/api/user/achievements` | GET | ✅ |
| `/api/user/active-sessions` | GET | ✅ |
| `/api/user/activity` | GET, PATCH | ✅ |
| `/api/user/block` | GET, POST | ✅ |
| `/api/user/blocked` | DELETE, GET | ✅ |
| `/api/user/broadcast-history` | GET | ✅ |
| `/api/user/co-broadcast-invites` | GET | ✅ |
| `/api/user/credits` | GET | ✅ |
| `/api/user/followers` | GET | ✅ |
| `/api/user/following` | GET | ✅ |
| `/api/user/fortunes` | GET | ✅ |
| `/api/user/fortunes/[fortuneId]` | PATCH | ✅ |
| `/api/user/likers` | GET | ✅ |
| `/api/user/location` | GET, POST | ✅ |
| `/api/user/profile` | GET, PATCH | ✅ |
| `/api/user/received-gifts` | GET | ✅ |
| `/api/user/referral-earnings` | GET | ✅ |
| `/api/user/report` | POST | ✅ |
| `/api/user/social-settings` | GET, PUT | ✅ |
| `/api/user/statistics` | GET | ✅ |
| `/api/user/stats` | GET, POST | ✅ |
| `/api/user/theme` | GET, PATCH | ✅ |
| `/api/user/wallet` | GET | ✅ |
| `/api/user/watch-ad` | GET, POST | ✅ |
| `/api/user/xp` | GET | ✅ |
| `/api/users/[userId]` | GET | ✅ |
| `/api/users/[userId]/follow` | GET, POST | ✅ |
| `/api/users/[userId]/posts` | GET | ✅ |
| `/api/users/lookup/[username]` | GET | ✅ |
| `/api/users/search` | GET | ✅ |

## §3 — Fal & Falcılar

**25/25** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/fortune-access/check` | POST | ✅ |
| `/api/fortune-tellers` | GET, POST | ✅ |
| `/api/fortune-tellers/[tellerId]/session` | GET, POST | ✅ |
| `/api/fortune-tellers/apply` | POST | ✅ |
| `/api/fortune-tellers/my-profile` | GET | ✅ |
| `/api/fortune-tellers/session` | GET, POST | ✅ |
| `/api/fortune-tellers/sessions` | GET | ✅ |
| `/api/fortune-tellers/sessions/[sessionId]` | PATCH | ✅ |
| `/api/fortune-tellers/sessions/stream` | GET | ✅ |
| `/api/fortune-tellers/toggle-online` | GET, POST | ✅ |
| `/api/fortunes/ask-uyumu` | POST | ✅ |
| `/api/fortunes/aura-analizi` | POST | ✅ |
| `/api/fortunes/burc-yorumu` | POST | ✅ |
| `/api/fortunes/dogum-haritasi` | POST | ✅ |
| `/api/fortunes/el-fali` | POST | ✅ |
| `/api/fortunes/evet-hayir` | POST | ✅ |
| `/api/fortunes/istihare` | POST | ✅ |
| `/api/fortunes/kahve-fali` | POST | ✅ |
| `/api/fortunes/kahve-fali-image` | POST | ✅ |
| `/api/fortunes/katina` | POST | ✅ |
| `/api/fortunes/kursundokme` | POST | ✅ |
| `/api/fortunes/melek-kartlari` | POST | ✅ |
| `/api/fortunes/numeroloji` | POST | ✅ |
| `/api/fortunes/ruya-yorumu` | POST | ✅ |
| `/api/fortunes/tarot-fali` | POST | ✅ |

## §4 — Rüya Dünyası

**8/8** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/dream-contest` | GET | ✅ |
| `/api/dream-contest/[contestId]/entries` | GET, POST | ✅ |
| `/api/dream-contest/[contestId]/vote` | POST | ✅ |
| `/api/dreams/[slug]/favorite` | GET, POST | ✅ |
| `/api/dreams/[slug]/view` | POST | ✅ |
| `/api/dreams/favorites` | GET | ✅ |
| `/api/dreams/interpret` | POST | ✅ |
| `/api/dreams/recommendations` | GET | ✅ |

## §5 — Astroloji & Uyum

**2/2** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/astrology-panel` | GET | ✅ |
| `/api/horoscope/daily` | GET | ✅ |

## §6 — Canlı Yayın

**39/39** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/live/create-room` | POST | ✅ |
| `/api/live/gift-types` | GET | ✅ |
| `/api/live/gift/send` | POST | ✅ |
| `/api/live/guest` | GET, POST | ✅ |
| `/api/live/heartbeat` | POST | ✅ |
| `/api/live/join-room` | POST | ✅ |
| `/api/live/leave-room` | POST | ✅ |
| `/api/live/message` | GET, POST | ✅ |
| `/api/live/online-users` | GET | ✅ |
| `/api/live/pk` | GET, POST | ✅ |
| `/api/live/rooms` | GET | ✅ |
| `/api/live/seats` | GET, POST | ✅ |
| `/api/trtc/token` | POST | ✅ |
| `/api/trtc/usersig` | POST | ✅ |
| `/api/video-streams` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/auto-close` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/ban` | DELETE, GET, POST | ✅ |
| `/api/video-streams/[streamId]/co-broadcast` | GET, PATCH, POST | ✅ |
| `/api/video-streams/[streamId]/co-broadcast/invite` | POST | ✅ |
| `/api/video-streams/[streamId]/comments` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/fortune-requests` | DELETE, GET, PATCH, POST | ✅ |
| `/api/video-streams/[streamId]/fortune-requests/my-status` | GET | ✅ |
| `/api/video-streams/[streamId]/gifts` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/join` | DELETE, POST | ✅ |
| `/api/video-streams/[streamId]/leave` | POST | ✅ |
| `/api/video-streams/[streamId]/like` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/live-started` | POST | ✅ |
| `/api/video-streams/[streamId]/media-heartbeat` | POST | ✅ |
| `/api/video-streams/[streamId]/messages` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/moderators` | DELETE, GET, POST | ✅ |
| `/api/video-streams/[streamId]/mute` | DELETE, GET, POST | ✅ |
| `/api/video-streams/[streamId]/pk-battle` | GET, POST | ✅ |
| `/api/video-streams/[streamId]/signal` | DELETE, GET, POST | ✅ |
| `/api/video-streams/[streamId]/stream` | GET | ✅ |
| `/api/video-streams/[streamId]/sync` | GET | ✅ |
| `/api/video-streams/gifts` | GET | ✅ |
| `/api/video-streams/pk/candidates` | GET | ✅ |
| `/api/video-streams/pk/score` | POST | ✅ |
| `/api/video-streams/signal` | DELETE, GET, POST | ✅ |

## §7 — Sesli Oda

**28/28** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/chat/rooms/[roomId]/gifts` | GET, POST | ✅ |
| `/api/chat/rooms/[roomId]/messages` | DELETE, GET, POST | ✅ |
| `/api/chat/rooms/[roomId]/moderation` | GET, POST | ✅ |
| `/api/chat/rooms/[roomId]/music` | DELETE, GET, POST | ✅ |
| `/api/chat/rooms/[roomId]/music-queue` | GET | ✅ |
| `/api/chat/rooms/[roomId]/music/stop` | POST | ✅ |
| `/api/chat/rooms/[roomId]/seats` | GET, PATCH | ✅ |
| `/api/chat/rooms/[roomId]/settings` | GET, PATCH | ✅ |
| `/api/chat/rooms/[roomId]/song-request` | GET, PATCH, POST | ✅ |
| `/api/chat/rooms/[roomId]/speak-request` | DELETE, GET, POST | ✅ |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | DELETE, POST | ✅ |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | DELETE, POST | ✅ |
| `/api/chat/rooms/[roomId]/speak-requests` | GET | ✅ |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | POST | ✅ |
| `/api/chat/rooms/[roomId]/state` | GET | ✅ |
| `/api/chat/rooms/[roomId]/stream` | GET | ✅ |
| `/api/chat/rooms/[roomId]/sync` | GET | ✅ |
| `/api/chat/rooms/[roomId]/typing` | GET, POST | ✅ |
| `/api/chat/rooms/[roomId]/voice` | GET, POST | ✅ |
| `/api/chat/rooms/create` | POST | ✅ |
| `/api/chat/rooms/pk/candidates` | GET | ✅ |
| `/api/room/[sessionId]` | GET, PATCH | ✅ |
| `/api/room/[sessionId]/messages` | GET, POST | ✅ |
| `/api/room/[sessionId]/review` | GET, POST | ✅ |
| `/api/room/[sessionId]/stream` | GET | ✅ |
| `/api/room/[sessionId]/summary` | GET | ✅ |
| `/api/room/[sessionId]/tip` | POST | ✅ |
| `/api/room/signal` | DELETE, GET, POST | ✅ |

## §8 — Hediye, Jeton & Cüzdan

**6/6** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/gift-box` | GET, POST | ✅ |
| `/api/gift-box/[boxId]/join` | POST | ✅ |
| `/api/gift-box/share` | POST | ✅ |
| `/api/gift-engine/finish` | POST | ✅ |
| `/api/jeton` | GET, POST | ✅ |
| `/api/wallet` | GET | ✅ |

## §9 — Ödeme & Faturalama

**7/7** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/billing/app-store/verify` | POST | ✅ |
| `/api/billing/google-play/verify` | POST | ✅ |
| `/api/payments/config` | GET | ✅ |
| `/api/payments/notifications/[notificationId]/dispute` | GET, POST | ✅ |
| `/api/payments/notify` | GET, POST | ✅ |
| `/api/payments/requests` | GET, POST | ✅ |
| `/api/refunds` | GET, POST | ✅ |

## §10 — Üyelik & VIP

**3/3** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/memberships/gift` | POST | ✅ |
| `/api/memberships/purchase` | POST | ✅ |
| `/api/vip/leaderboard` | GET | ✅ |

## §11 — Sosyal & Keşif

**12/12** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/hashtags/[name]` | GET | ✅ |
| `/api/search/advanced` | GET | ✅ |
| `/api/share-card` | GET | ✅ |
| `/api/social/actions` | GET, POST | ✅ |
| `/api/social/discovery` | GET | ✅ |
| `/api/social/posts` | GET, POST | ✅ |
| `/api/social/posts/[postId]` | DELETE, GET | ✅ |
| `/api/social/posts/[postId]/comments` | DELETE, GET, POST | ✅ |
| `/api/social/posts/[postId]/likes` | POST | ✅ |
| `/api/social/profile` | GET | ✅ |
| `/api/teams` | GET, POST | ✅ |
| `/api/teams/[teamId]` | GET, PATCH | ✅ |

## §12 — Mesajlaşma & Bildirim

**9/9** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/messages` | GET | ✅ |
| `/api/messages/[userId]` | GET, POST | ✅ |
| `/api/messages/request` | PATCH, POST | ✅ |
| `/api/notifications` | DELETE, GET, POST | ✅ |
| `/api/notifications/stream` | GET | ✅ |
| `/api/popups` | GET | ✅ |
| `/api/support/tickets` | GET, POST | ✅ |
| `/api/support/tickets/[ticketId]` | GET, PATCH | ✅ |
| `/api/support/tickets/[ticketId]/messages` | POST | ✅ |

## §13 — Görev, Ödül & Oyun

**31/31** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/games/auto-match` | POST | ✅ |
| `/api/games/daily-reward` | GET, POST | ✅ |
| `/api/games/daily-spin` | POST | ✅ |
| `/api/games/lamba-cini` | GET, POST | ✅ |
| `/api/games/leaderboard` | GET | ✅ |
| `/api/games/lobby` | GET | ✅ |
| `/api/games/play` | POST | ✅ |
| `/api/games/profile` | GET | ✅ |
| `/api/games/quests` | GET, POST | ✅ |
| `/api/games/room` | GET, POST | ✅ |
| `/api/games/room/[roomId]` | DELETE, GET, PATCH, POST | ✅ |
| `/api/games/room/[roomId]/chat` | GET, PATCH, POST | ✅ |
| `/api/games/room/[roomId]/replace-ai` | POST | ✅ |
| `/api/games/room/[roomId]/viewers` | DELETE, GET, POST | ✅ |
| `/api/games/sos` | GET, POST | ✅ |
| `/api/games/sos/[gameId]` | DELETE, GET, PATCH, POST | ✅ |
| `/api/games/sos/[gameId]/chat` | GET, PATCH, POST | ✅ |
| `/api/games/sos/[gameId]/viewers` | DELETE, GET, POST | ✅ |
| `/api/gifts/battles` | GET, POST | ✅ |
| `/api/gifts/catalog` | GET | ✅ |
| `/api/gifts/check-reciprocal` | POST | ✅ |
| `/api/gifts/goals` | GET, POST | ✅ |
| `/api/gifts/insights/me/badge` | GET | ✅ |
| `/api/gifts/insights/me/history` | GET | ✅ |
| `/api/gifts/insights/me/recommendations` | GET | ✅ |
| `/api/gifts/lucky/config` | GET | ✅ |
| `/api/gifts/lucky/history` | GET | ✅ |
| `/api/gifts/lucky/send` | POST | ✅ |
| `/api/gifts/missions/[missionId]/claim` | POST | ✅ |
| `/api/gifts/missions/me` | GET | ✅ |
| `/api/gifts/send` | POST | ✅ |

## §15 — Ajans

**15/15** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/agency/applicant-score/[userId]` | GET | ✅ |
| `/api/agency/apply` | POST | ✅ |
| `/api/agency/earnings` | GET | ✅ |
| `/api/agency/growth` | GET | ✅ |
| `/api/agency/invite` | GET, POST | ✅ |
| `/api/agency/invite-earnings` | GET | ✅ |
| `/api/agency/join` | POST | ✅ |
| `/api/agency/leave` | DELETE, POST | ✅ |
| `/api/agency/live-status` | GET | ✅ |
| `/api/agency/members` | DELETE, GET, POST | ✅ |
| `/api/agency/my` | GET, PATCH | ✅ |
| `/api/agency/tasks` | GET | ✅ |
| `/api/agency/wallet` | GET | ✅ |
| `/api/agency/wallet/transfer` | POST | ✅ |
| `/api/agency/withdrawals` | GET, POST | ✅ |

## §16 — Kozmetik & Bana Özel

**2/2** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/bana-ozel` | GET | ✅ |
| `/api/bana-ozel/open` | POST | ✅ |

## §17 — İçerik & CMS

**20/20** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/blog/comments` | DELETE, GET, POST | ✅ |
| `/api/blog/favorite` | POST | ✅ |
| `/api/blog/interactions` | GET | ✅ |
| `/api/blog/like` | POST | ✅ |
| `/api/short-videos` | GET | ✅ |
| `/api/short-videos/[id]` | DELETE, GET | ✅ |
| `/api/short-videos/[id]/comments` | GET, POST | ✅ |
| `/api/short-videos/[id]/comments/[commentId]/like` | POST | ✅ |
| `/api/short-videos/[id]/comments/[commentId]/pin` | POST | ✅ |
| `/api/short-videos/[id]/duets` | GET | ✅ |
| `/api/short-videos/[id]/like` | POST | ✅ |
| `/api/short-videos/[id]/save` | POST | ✅ |
| `/api/short-videos/[id]/share` | POST | ✅ |
| `/api/short-videos/[id]/view` | POST | ✅ |
| `/api/short-videos/explore` | GET | ✅ |
| `/api/short-videos/profile/[userId]` | GET | ✅ |
| `/api/short-videos/register` | POST | ✅ |
| `/api/short-videos/upload` | POST | ✅ |
| `/api/short-videos/upload-url` | POST | ✅ |
| `/api/short-videos/user/[userId]` | GET | ✅ |

## §18 — Altyapı & Sistem

**34/34** path izi mobil `lib/` içinde bulundu.

| Path | Metotlar | Mobil iz |
|------|----------|----------|
| `/api/ads/placement` | GET, POST | ✅ |
| `/api/ads/reward` | POST | ✅ |
| `/api/animations/me` | GET | ✅ |
| `/api/animations/resolve` | GET | ✅ |
| `/api/bootstrap` | GET | ✅ |
| `/api/broadcast-images` | GET | ✅ |
| `/api/cache` | GET, POST | ✅ |
| `/api/cfc-arena/join` | POST | ✅ |
| `/api/daily-login` | GET, POST | ✅ |
| `/api/daily-missions` | GET, POST | ✅ |
| `/api/dream-diary` | DELETE, GET, POST | ✅ |
| `/api/dream-stats` | GET | ✅ |
| `/api/effects/resolve` | GET | ✅ |
| `/api/favorite-tellers` | GET, POST | ✅ |
| `/api/leaderboards` | GET | ✅ |
| `/api/leaderboards/top100` | GET | ✅ |
| `/api/music/search` | GET | ✅ |
| `/api/pk/me/invites` | GET | ✅ |
| `/api/profile-frames` | GET, POST | ✅ |
| `/api/referral` | GET | ✅ |
| `/api/room-themes/catalog` | GET | ✅ |
| `/api/rtc/telemetry` | POST | ✅ |
| `/api/stories` | DELETE, GET, POST | ✅ |
| `/api/supporter-levels` | GET | ✅ |
| `/api/teller-chat` | GET | ✅ |
| `/api/teller-chat/[sessionId]` | GET, POST | ✅ |
| `/api/teller/analytics` | GET | ✅ |
| `/api/teller/level` | GET | ✅ |
| `/api/teller/verification` | GET, POST | ✅ |
| `/api/tournaments` | GET | ✅ |
| `/api/trends/[slug]/like` | POST | ✅ |
| `/api/weekly-dream-report` | GET, POST | ✅ |
| `/api/withdrawals` | GET, POST | ✅ |
| `/api/youtube/search` | GET | ✅ |

## Sonraki agent işleri (öncelik)

1. §11 Sosyal — `social_abacus_remote_datasource` (discovery, actions, profile, share-card, teams, hashtags)
2. §2 — `/api/me/membership*` VIP yetenek paketi
3. §6–§7 — video-streams/chat eksik sync/guest uçları (BÖLÜM 22)
4. §13 — games/missions eksikleri
5. Her bölüm bitiminde: `flutter test` + contract test
