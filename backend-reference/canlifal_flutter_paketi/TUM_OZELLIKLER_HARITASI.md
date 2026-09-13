# CanlıFal — Tüm Özellikler Haritası (Flutter)

Bu belge sitedeki **her özellik alanını** (yönetim paneli dahil) Flutter tarafında karşılanacak
uç noktalarla eşler. Sayılar canlı kaynak kod taramasından üretilmiştir.

Toplam: **612** rota · **953** uç (path+method)

Sınıf anlamları: `FLUTTER_READY` mobil JWT kabul eder · `PUBLIC` açık · `ADMIN_ONLY` yalnız yönetim · `WEB_ONLY` yalnız web oturumu · `DEPRECATED_ALIAS` takma ad.

İlgili belgeler: uç ayrıntısı `ENDPOINTS.md` · sınıflandırma `endpoint_classification.md` · yönetim yetkileri `admin_permissions.md` · gerçek zamanlı olaylar `websocket_events.md` · BÖLÜM 22 `BOLUM22_MULTIGUEST_PK_GIFTBOX.md`.

## Özet tablo

| # | Özellik alanı | Rota | Mobil kullanılabilir | Yalnız admin |
|---:|---|---:|---:|---:|
| 1 | Kimlik & Oturum | 28 | 25 | 0 |
| 2 | Kullanıcı Profili & Ayarlar | 54 | 54 | 0 |
| 3 | Fal & Falcılar | 38 | 37 | 1 |
| 4 | Rüya Dünyası | 19 | 17 | 1 |
| 5 | Astroloji & Uyum | 3 | 3 | 0 |
| 6 | Canlı Yayın (Video) | 76 | 71 | 5 |
| 7 | Sesli Oda / Sohbet Odası | 45 | 37 | 5 |
| 8 | Hediye, Jeton & Cüzdan | 39 | 39 | 0 |
| 9 | Ödeme & Faturalama | 8 | 8 | 0 |
| 10 | Üyelik & VIP | 9 | 8 | 0 |
| 11 | Sosyal & Keşif | 16 | 16 | 0 |
| 12 | Mesajlaşma & Bildirim | 12 | 10 | 2 |
| 13 | Görev, Ödül & Oyunlaştırma | 33 | 33 | 0 |
| 14 | Sıralama & Turnuva | 3 | 3 | 0 |
| 15 | Ajans | 16 | 16 | 0 |
| 16 | Kozmetik & Bana Özel | 15 | 15 | 0 |
| 17 | İçerik & CMS | 24 | 24 | 0 |
| 18 | Altyapı & Sistem | 13 | 11 | 0 |
| 19 | Yönetim Paneli (Admin) | 161 | 0 | 161 |

## 1. Kimlik & Oturum

Kayıt, giriş (e-posta/Google/Apple), JWT yenileme, şifre sıfırlama, telefon/e-posta doğrulama, cihaz yönetimi, hesap silme

**28 rota** — mobil: 25, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/auth/[...nextauth]` | GET, POST | PUBLIC |
| `/api/auth/change-password` | POST | FLUTTER_READY |
| `/api/auth/email/send-verification` | POST | FLUTTER_READY |
| `/api/auth/email/verify` | GET, POST | PUBLIC |
| `/api/auth/forgot-password` | POST | PUBLIC |
| `/api/auth/logout` | POST | FLUTTER_READY |
| `/api/auth/logout-all` | POST | FLUTTER_READY |
| `/api/auth/mobile-apple` | POST | FLUTTER_READY |
| `/api/auth/mobile-google` | POST | FLUTTER_READY |
| `/api/auth/mobile-login` | POST | FLUTTER_READY |
| `/api/auth/mobile-refresh` | POST | FLUTTER_READY |
| `/api/auth/mobile-register` | POST | FLUTTER_READY |
| `/api/auth/mobile-tiktok` | POST | FLUTTER_READY |
| `/api/auth/phone/send-otp` | POST | FLUTTER_READY |
| `/api/auth/phone/verify-otp` | POST | FLUTTER_READY |
| `/api/auth/reclaim-device` | POST | MISSING_MOBILE_SUPPORT |
| `/api/auth/reset-password` | POST | PUBLIC |
| `/api/auth/sessions` | DELETE, GET | FLUTTER_READY |
| `/api/auth/verify-device` | GET | WEB_ONLY |
| `/api/devices/fcm` | DELETE, POST | FLUTTER_READY |
| `/api/mobile/config` | GET | PUBLIC |
| `/api/mobile/fortune-menu` | GET | FLUTTER_READY |
| `/api/mobile/home` | GET | FLUTTER_READY |
| `/api/mobile/user-profile/[userId]` | GET | FLUTTER_READY |
| `/api/signup` | POST | PUBLIC |
| `/api/user/account` | DELETE, POST | FLUTTER_READY |
| `/api/user/account/delete` | POST | DEPRECATED_ALIAS |
| `/api/verification` | GET, POST | FLUTTER_READY |

## 2. Kullanıcı Profili & Ayarlar

Profil, avatar, dil, gizlilik, engelleme, konum, sosyal ayarlar, ziyaretçiler, çeviriler

**54 rota** — mobil: 54, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/activities` | GET | FLUTTER_READY |
| `/api/me` | GET, PATCH | FLUTTER_READY |
| `/api/me/admin-capabilities` | GET | FLUTTER_READY |
| `/api/me/membership` | GET | FLUTTER_READY |
| `/api/me/membership-events` | GET | FLUTTER_READY |
| `/api/me/membership-history` | GET, PUT | FLUTTER_READY |
| `/api/me/profile-visitors` | GET, POST | FLUTTER_READY |
| `/api/me/vip-identity` | GET, PUT | FLUTTER_READY |
| `/api/me/vip-preferences` | GET, PUT | FLUTTER_READY |
| `/api/me/vip-xp` | GET, POST | FLUTTER_READY |
| `/api/presence` | GET, POST | FLUTTER_READY |
| `/api/presence/online-events` | GET | PUBLIC |
| `/api/presence/sections` | GET | PUBLIC |
| `/api/settings/ads` | GET | PUBLIC |
| `/api/settings/canlidark-hero` | GET | PUBLIC |
| `/api/settings/public` | GET | PUBLIC |
| `/api/settings/themes` | GET | PUBLIC |
| `/api/translations` | GET | PUBLIC |
| `/api/upload/get-url` | GET, POST | FLUTTER_READY |
| `/api/upload/presigned` | POST | FLUTTER_READY |
| `/api/user/[userId]/achievements` | GET | FLUTTER_READY |
| `/api/user/[userId]/follow` | DELETE, POST | FLUTTER_READY |
| `/api/user/[userId]/follow-status` | GET | FLUTTER_READY |
| `/api/user/achievements` | GET | FLUTTER_READY |
| `/api/user/active-sessions` | GET | FLUTTER_READY |
| `/api/user/activity` | GET, PATCH | FLUTTER_READY |
| `/api/user/block` | GET, POST | FLUTTER_READY |
| `/api/user/blocked` | DELETE, GET | FLUTTER_READY |
| `/api/user/broadcast-history` | GET | FLUTTER_READY |
| `/api/user/co-broadcast-invites` | GET | FLUTTER_READY |
| `/api/user/credits` | GET | FLUTTER_READY |
| `/api/user/followers` | GET | FLUTTER_READY |
| `/api/user/following` | GET | FLUTTER_READY |
| `/api/user/fortunes` | GET | FLUTTER_READY |
| `/api/user/fortunes/[fortuneId]` | PATCH | FLUTTER_READY |
| `/api/user/likers` | GET | FLUTTER_READY |
| `/api/user/location` | GET, POST | FLUTTER_READY |
| `/api/user/profile` | GET, PATCH | FLUTTER_READY |
| `/api/user/received-gifts` | GET | FLUTTER_READY |
| `/api/user/referral-earnings` | GET | FLUTTER_READY |
| `/api/user/report` | POST | FLUTTER_READY |
| `/api/user/social-settings` | GET, PUT | FLUTTER_READY |
| `/api/user/statistics` | GET | FLUTTER_READY |
| `/api/user/stats` | GET, POST | FLUTTER_READY |
| `/api/user/theme` | GET, PATCH | FLUTTER_READY |
| `/api/user/wallet` | GET | FLUTTER_READY |
| `/api/user/watch-ad` | GET, POST | FLUTTER_READY |
| `/api/user/xp` | GET | FLUTTER_READY |
| `/api/users/[userId]` | GET | FLUTTER_READY |
| `/api/users/[userId]/follow` | GET, POST | FLUTTER_READY |
| `/api/users/[userId]/posts` | GET | FLUTTER_READY |
| `/api/users/lookup/[username]` | GET | FLUTTER_READY |
| `/api/users/online` | GET | PUBLIC |
| `/api/users/search` | GET | FLUTTER_READY |

## 3. Fal & Falcılar

Fal türleri, fal talebi, falcı listesi/profili, falcı olma, falcı analitiği, favori falcılar, online fal, falcı sohbeti

**38 rota** — mobil: 37, admin: 1

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/favorite-tellers` | GET, POST | FLUTTER_READY |
| `/api/fortune-access/check` | POST | FLUTTER_READY |
| `/api/fortune-access/ip-status` | GET | PUBLIC |
| `/api/fortune-request-types` | GET | PUBLIC |
| `/api/fortune-tellers` | GET, POST | FLUTTER_READY |
| `/api/fortune-tellers/[tellerId]` | GET, PATCH | ADMIN_ONLY |
| `/api/fortune-tellers/[tellerId]/reviews` | GET | PUBLIC |
| `/api/fortune-tellers/[tellerId]/session` | GET, POST | FLUTTER_READY |
| `/api/fortune-tellers/apply` | POST | FLUTTER_READY |
| `/api/fortune-tellers/awards` | GET | PUBLIC |
| `/api/fortune-tellers/gifts` | GET | PUBLIC |
| `/api/fortune-tellers/my-profile` | GET | FLUTTER_READY |
| `/api/fortune-tellers/session` | GET, POST | FLUTTER_READY |
| `/api/fortune-tellers/sessions` | GET | FLUTTER_READY |
| `/api/fortune-tellers/sessions/[sessionId]` | PATCH | FLUTTER_READY |
| `/api/fortune-tellers/sessions/stream` | GET | FLUTTER_READY |
| `/api/fortune-tellers/toggle-online` | GET, POST | FLUTTER_READY |
| `/api/fortunes/ask-uyumu` | POST | FLUTTER_READY |
| `/api/fortunes/aura-analizi` | POST | FLUTTER_READY |
| `/api/fortunes/burc-yorumu` | POST | FLUTTER_READY |
| `/api/fortunes/dogum-haritasi` | POST | FLUTTER_READY |
| `/api/fortunes/el-fali` | POST | FLUTTER_READY |
| `/api/fortunes/evet-hayir` | POST | FLUTTER_READY |
| `/api/fortunes/istihare` | POST | FLUTTER_READY |
| `/api/fortunes/kahve-fali` | POST | FLUTTER_READY |
| `/api/fortunes/kahve-fali-image` | POST | FLUTTER_READY |
| `/api/fortunes/katina` | POST | FLUTTER_READY |
| `/api/fortunes/kursundokme` | POST | FLUTTER_READY |
| `/api/fortunes/melek-kartlari` | POST | FLUTTER_READY |
| `/api/fortunes/numeroloji` | POST | FLUTTER_READY |
| `/api/fortunes/ruya-yorumu` | POST | FLUTTER_READY |
| `/api/fortunes/tarot-fali` | POST | FLUTTER_READY |
| `/api/online-fal` | GET | PUBLIC |
| `/api/teller-chat` | GET | FLUTTER_READY |
| `/api/teller-chat/[sessionId]` | GET, POST | FLUTTER_READY |
| `/api/teller/analytics` | GET | FLUTTER_READY |
| `/api/teller/level` | GET | FLUTTER_READY |
| `/api/teller/verification` | GET, POST | FLUTTER_READY |

## 4. Rüya Dünyası

Rüya günlüğü, rüya yorumu, sembol sözlüğü, istatistik, trend, yarışma, haftalık rapor

**19 rota** — mobil: 17, admin: 1

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/dream-contest` | GET | FLUTTER_READY |
| `/api/dream-contest/[contestId]/entries` | GET, POST | FLUTTER_READY |
| `/api/dream-contest/[contestId]/vote` | POST | FLUTTER_READY |
| `/api/dream-diary` | DELETE, GET, POST | FLUTTER_READY |
| `/api/dream-stats` | GET | FLUTTER_READY |
| `/api/dream-symbols` | GET | PUBLIC |
| `/api/dream-symbols/[slug]` | GET | PUBLIC |
| `/api/dreams` | GET | PUBLIC |
| `/api/dreams/[slug]` | GET | PUBLIC |
| `/api/dreams/[slug]/comments` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/dreams/[slug]/favorite` | GET, POST | FLUTTER_READY |
| `/api/dreams/[slug]/view` | POST | FLUTTER_READY |
| `/api/dreams/favorites` | GET | FLUTTER_READY |
| `/api/dreams/generate` | POST | PUBLIC |
| `/api/dreams/interpret` | POST | FLUTTER_READY |
| `/api/dreams/morning-reminder` | POST | INTERNAL |
| `/api/dreams/recommendations` | GET | FLUTTER_READY |
| `/api/dreams/trends` | GET | PUBLIC |
| `/api/weekly-dream-report` | GET, POST | FLUTTER_READY |

## 5. Astroloji & Uyum

Burç paneli, burç uyumu, günlük yorum

**3 rota** — mobil: 3, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/astrology-panel` | GET | FLUTTER_READY |
| `/api/compatibility` | POST | PUBLIC |
| `/api/horoscope/daily` | GET | FLUTTER_READY |

## 6. Canlı Yayın (Video)

Yayın açma/kapatma, izleyici, hediye, çoklu misafir (multi-guest), PK/battle, TRTC/WebRTC sinyalizasyon, yayın senkronizasyonu

**76 rota** — mobil: 71, admin: 5

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/broadcast-images` | GET | FLUTTER_READY |
| `/api/live/create-room` | POST | FLUTTER_READY |
| `/api/live/gift-types` | GET | FLUTTER_READY |
| `/api/live/gift/send` | POST | FLUTTER_READY |
| `/api/live/guest` | GET, POST | FLUTTER_READY |
| `/api/live/guest/list` | GET | PUBLIC |
| `/api/live/heartbeat` | POST | FLUTTER_READY |
| `/api/live/join-room` | POST | FLUTTER_READY |
| `/api/live/leave-room` | POST | FLUTTER_READY |
| `/api/live/message` | GET, POST | FLUTTER_READY |
| `/api/live/online-users` | GET | FLUTTER_READY |
| `/api/live/pk` | GET, POST | FLUTTER_READY |
| `/api/live/pk/active` | GET | PUBLIC |
| `/api/live/pk/score` | POST | ADMIN_ONLY |
| `/api/live/rooms` | GET | FLUTTER_READY |
| `/api/live/seats` | GET, POST | FLUTTER_READY |
| `/api/pk/[matchId]` | GET | PUBLIC |
| `/api/pk/[matchId]/stream` | GET | PUBLIC |
| `/api/pk/active` | GET | PUBLIC |
| `/api/pk/leaderboard` | GET | PUBLIC |
| `/api/pk/me/invites` | GET | FLUTTER_READY |
| `/api/rtc/telemetry` | POST | FLUTTER_READY |
| `/api/short-videos` | GET | FLUTTER_READY |
| `/api/short-videos/[id]` | DELETE, GET | FLUTTER_READY |
| `/api/short-videos/[id]/comments` | GET, POST | FLUTTER_READY |
| `/api/short-videos/[id]/comments/[commentId]` | DELETE | ADMIN_ONLY |
| `/api/short-videos/[id]/comments/[commentId]/like` | POST | FLUTTER_READY |
| `/api/short-videos/[id]/comments/[commentId]/pin` | POST | FLUTTER_READY |
| `/api/short-videos/[id]/duets` | GET | FLUTTER_READY |
| `/api/short-videos/[id]/like` | POST | FLUTTER_READY |
| `/api/short-videos/[id]/save` | POST | FLUTTER_READY |
| `/api/short-videos/[id]/share` | POST | FLUTTER_READY |
| `/api/short-videos/[id]/view` | POST | FLUTTER_READY |
| `/api/short-videos/explore` | GET | FLUTTER_READY |
| `/api/short-videos/mentions/search` | GET | PUBLIC |
| `/api/short-videos/music` | GET | PUBLIC |
| `/api/short-videos/profile/[userId]` | GET | FLUTTER_READY |
| `/api/short-videos/register` | POST | FLUTTER_READY |
| `/api/short-videos/upload` | POST | FLUTTER_READY |
| `/api/short-videos/upload-url` | POST | FLUTTER_READY |
| `/api/short-videos/user/[userId]` | GET | FLUTTER_READY |
| `/api/stories` | DELETE, GET, POST | FLUTTER_READY |
| `/api/tencent/webhook` | POST | PUBLIC |
| `/api/trtc/token` | POST | FLUTTER_READY |
| `/api/trtc/usersig` | POST | FLUTTER_READY |
| `/api/trtc/webhook` | POST | PUBLIC |
| `/api/video-streams` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]` | GET, PATCH | ADMIN_ONLY |
| `/api/video-streams/[streamId]/auto-close` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/ban` | DELETE, GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/co-broadcast` | GET, PATCH, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/co-broadcast/invite` | POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/comments` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/end` | POST | ADMIN_ONLY |
| `/api/video-streams/[streamId]/fortune-requests` | DELETE, GET, PATCH, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/fortune-requests/my-status` | GET | FLUTTER_READY |
| `/api/video-streams/[streamId]/gifts` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/join` | DELETE, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/leave` | POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/like` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/live-started` | POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/media-heartbeat` | POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/messages` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/moderators` | DELETE, GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/mute` | DELETE, GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/pk-battle` | GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/signal` | DELETE, GET, POST | FLUTTER_READY |
| `/api/video-streams/[streamId]/stream` | GET | FLUTTER_READY |
| `/api/video-streams/[streamId]/sync` | GET | FLUTTER_READY |
| `/api/video-streams/[streamId]/viewers` | GET | PUBLIC |
| `/api/video-streams/gifts` | GET | FLUTTER_READY |
| `/api/video-streams/pk` | GET, POST | ADMIN_ONLY |
| `/api/video-streams/pk/candidates` | GET | FLUTTER_READY |
| `/api/video-streams/pk/list` | GET | PUBLIC |
| `/api/video-streams/pk/score` | POST | FLUTTER_READY |
| `/api/video-streams/signal` | DELETE, GET, POST | FLUTTER_READY |

## 7. Sesli Oda / Sohbet Odası

Oda oluşturma, koltuk, mikrofon isteği, moderasyon, müzik/DJ, oda içi PK, mesaj sabitleme, oda senkronizasyonu

**45 rota** — mobil: 37, admin: 5

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/chat/broadcast-images` | GET | PUBLIC |
| `/api/chat/cleanup` | DELETE, GET, POST | INTERNAL |
| `/api/chat/rooms` | GET | PUBLIC |
| `/api/chat/rooms/[roomId]/dj` | GET, POST | ADMIN_ONLY |
| `/api/chat/rooms/[roomId]/gifts` | GET, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/messages` | DELETE, GET, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/moderation` | GET, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/music` | DELETE, GET, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/music-queue` | GET | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/music/stop` | POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/pin-message` | POST | PUBLIC |
| `/api/chat/rooms/[roomId]/pk` | GET, POST | ADMIN_ONLY |
| `/api/chat/rooms/[roomId]/pk/score` | POST | ADMIN_ONLY |
| `/api/chat/rooms/[roomId]/presence` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/chat/rooms/[roomId]/seats` | GET, PATCH | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/settings` | GET, PATCH | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/song-request` | GET, PATCH, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/speak-request` | DELETE, GET, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | DELETE, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | DELETE, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/speak-requests` | GET | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | DELETE, POST | DEPRECATED_ALIAS |
| `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | DELETE, POST | DEPRECATED_ALIAS |
| `/api/chat/rooms/[roomId]/state` | GET | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/stream` | GET | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/sync` | GET | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/transfer-ownership` | POST | ADMIN_ONLY |
| `/api/chat/rooms/[roomId]/typing` | GET, POST | FLUTTER_READY |
| `/api/chat/rooms/[roomId]/voice` | GET, POST | FLUTTER_READY |
| `/api/chat/rooms/backgrounds` | GET | PUBLIC |
| `/api/chat/rooms/create` | POST | FLUTTER_READY |
| `/api/chat/rooms/pk-list` | GET | PUBLIC |
| `/api/chat/rooms/pk/candidates` | GET | FLUTTER_READY |
| `/api/chat/youtube-audio` | GET, POST | PUBLIC |
| `/api/chat/youtube-stream` | GET | PUBLIC |
| `/api/music/history` | GET | PUBLIC |
| `/api/music/search` | GET | FLUTTER_READY |
| `/api/room/[sessionId]` | GET, PATCH | FLUTTER_READY |
| `/api/room/[sessionId]/messages` | GET, POST | FLUTTER_READY |
| `/api/room/[sessionId]/review` | GET, POST | FLUTTER_READY |
| `/api/room/[sessionId]/stream` | GET | FLUTTER_READY |
| `/api/room/[sessionId]/summary` | GET | FLUTTER_READY |
| `/api/room/[sessionId]/tip` | POST | FLUTTER_READY |
| `/api/room/signal` | DELETE, GET, POST | FLUTTER_READY |

## 8. Hediye, Jeton & Cüzdan

Hediye gönderimi, hediye kutusu (gift box), hediye motoru, jeton paketleri, cüzdan, defter (ledger), çekim talepleri, iade

**39 rota** — mobil: 39, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/credit-packages` | GET | PUBLIC |
| `/api/currency-branding` | GET | PUBLIC |
| `/api/gift-box` | GET, POST | FLUTTER_READY |
| `/api/gift-box/[boxId]` | GET | PUBLIC |
| `/api/gift-box/[boxId]/join` | POST | FLUTTER_READY |
| `/api/gift-box/share` | POST | FLUTTER_READY |
| `/api/gift-engine/finish` | POST | FLUTTER_READY |
| `/api/gift-engine/gifts` | GET | PUBLIC |
| `/api/gift-engine/queue` | GET | PUBLIC |
| `/api/gifts/battles` | GET, POST | FLUTTER_READY |
| `/api/gifts/battles/[battleId]` | GET | PUBLIC |
| `/api/gifts/catalog` | GET | FLUTTER_READY |
| `/api/gifts/check-reciprocal` | POST | FLUTTER_READY |
| `/api/gifts/goals` | GET, POST | FLUTTER_READY |
| `/api/gifts/insights/album/[userId]` | GET | PUBLIC |
| `/api/gifts/insights/badge/[userId]` | GET | PUBLIC |
| `/api/gifts/insights/collection/[userId]` | GET | PUBLIC |
| `/api/gifts/insights/feed` | GET | PUBLIC |
| `/api/gifts/insights/first-gifter/[context]/[contextId]` | GET | PUBLIC |
| `/api/gifts/insights/leaderboard` | GET | PUBLIC |
| `/api/gifts/insights/map` | GET | PUBLIC |
| `/api/gifts/insights/me/badge` | GET | FLUTTER_READY |
| `/api/gifts/insights/me/history` | GET | FLUTTER_READY |
| `/api/gifts/insights/me/recommendations` | GET | FLUTTER_READY |
| `/api/gifts/lucky/config` | GET | FLUTTER_READY |
| `/api/gifts/lucky/history` | GET | FLUTTER_READY |
| `/api/gifts/lucky/send` | POST | FLUTTER_READY |
| `/api/gifts/missions` | GET | PUBLIC |
| `/api/gifts/missions/[missionId]/claim` | POST | FLUTTER_READY |
| `/api/gifts/missions/me` | GET | FLUTTER_READY |
| `/api/gifts/recent-big` | GET | PUBLIC |
| `/api/gifts/send` | POST | FLUTTER_READY |
| `/api/gifts/types` | GET | PUBLIC |
| `/api/gifts/version` | GET | PUBLIC |
| `/api/jeton` | GET, POST | FLUTTER_READY |
| `/api/refunds` | GET, POST | FLUTTER_READY |
| `/api/supporter-levels` | GET | FLUTTER_READY |
| `/api/wallet` | GET | FLUTTER_READY |
| `/api/withdrawals` | GET, POST | FLUTTER_READY |

## 9. Ödeme & Faturalama

Ödeme yöntemleri, Google Play / App Store satın alma doğrulama, satın alma geçmişi

**8 rota** — mobil: 8, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/billing/app-store/verify` | POST | FLUTTER_READY |
| `/api/billing/google-play/verify` | POST | FLUTTER_READY |
| `/api/payments/config` | GET | FLUTTER_READY |
| `/api/payments/methods` | GET | PUBLIC |
| `/api/payments/notifications/[notificationId]/dispute` | GET, POST | FLUTTER_READY |
| `/api/payments/notify` | GET, POST | FLUTTER_READY |
| `/api/payments/requests` | GET, POST | FLUTTER_READY |
| `/api/payments/settings` | GET | PUBLIC |

## 10. Üyelik & VIP

Üyelik kademeleri, satın alma, hediye üyelik, VIP kimlik/XP/tercihler, üyelik olayları, rozetler

**9 rota** — mobil: 8, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/membership-badges` | GET | PUBLIC |
| `/api/membership/plans` | GET | PUBLIC |
| `/api/membership/purchase` | POST | DEPRECATED_ALIAS |
| `/api/memberships` | GET | PUBLIC |
| `/api/memberships/comparison` | GET | PUBLIC |
| `/api/memberships/gift` | POST | FLUTTER_READY |
| `/api/memberships/packages` | GET | PUBLIC |
| `/api/memberships/purchase` | POST | FLUTTER_READY |
| `/api/vip/leaderboard` | GET | FLUTTER_READY |

## 11. Sosyal & Keşif

Takip, arkadaşlık, keşfet, tanış-kaynaş, profil ziyaretçileri, sosyal aksiyonlar, arama, paylaşım kartı

**16 rota** — mobil: 16, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/hashtags/[name]` | GET | FLUTTER_READY |
| `/api/hashtags/search` | GET | PUBLIC |
| `/api/hashtags/trending` | GET | PUBLIC |
| `/api/search` | GET | PUBLIC |
| `/api/search/advanced` | GET | FLUTTER_READY |
| `/api/share-card` | GET | FLUTTER_READY |
| `/api/social/actions` | GET, POST | FLUTTER_READY |
| `/api/social/discovery` | GET | FLUTTER_READY |
| `/api/social/posts` | GET, POST | FLUTTER_READY |
| `/api/social/posts/[postId]` | DELETE, GET | FLUTTER_READY |
| `/api/social/posts/[postId]/comments` | DELETE, GET, POST | FLUTTER_READY |
| `/api/social/posts/[postId]/likes` | POST | FLUTTER_READY |
| `/api/social/posts/[postId]/view` | POST | PUBLIC |
| `/api/social/profile` | GET | FLUTTER_READY |
| `/api/teams` | GET, POST | FLUTTER_READY |
| `/api/teams/[teamId]` | GET, PATCH | FLUTTER_READY |

## 12. Mesajlaşma & Bildirim

Özel mesaj, bildirim listesi, FCM push, duyuru, popup, ticker

**12 rota** — mobil: 10, admin: 2

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/announcements` | GET, POST | ADMIN_ONLY |
| `/api/announcements/event` | POST | ADMIN_ONLY |
| `/api/homepage-ticker` | GET | PUBLIC |
| `/api/messages` | GET | FLUTTER_READY |
| `/api/messages/[userId]` | GET, POST | FLUTTER_READY |
| `/api/messages/request` | PATCH, POST | FLUTTER_READY |
| `/api/notifications` | DELETE, GET, POST | FLUTTER_READY |
| `/api/notifications/stream` | GET | FLUTTER_READY |
| `/api/popups` | GET | FLUTTER_READY |
| `/api/support/tickets` | GET, POST | FLUTTER_READY |
| `/api/support/tickets/[ticketId]` | GET, PATCH | FLUTTER_READY |
| `/api/support/tickets/[ticketId]/messages` | POST | FLUTTER_READY |

## 13. Görev, Ödül & Oyunlaştırma

Günlük giriş, günlük görev, başarım, rozet, davet/referans, reklam ödülü, CFC Arena, oyunlar

**33 rota** — mobil: 33, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/ads/active` | GET | PUBLIC |
| `/api/ads/placement` | GET, POST | FLUTTER_READY |
| `/api/ads/reward` | POST | FLUTTER_READY |
| `/api/anonymous` | GET, POST | PUBLIC |
| `/api/anonymous/watch-ad` | POST | PUBLIC |
| `/api/cfc-arena` | GET | PUBLIC |
| `/api/cfc-arena/[contestId]` | GET | PUBLIC |
| `/api/cfc-arena/join` | POST | FLUTTER_READY |
| `/api/daily-login` | GET, POST | FLUTTER_READY |
| `/api/daily-missions` | GET, POST | FLUTTER_READY |
| `/api/games` | GET | PUBLIC |
| `/api/games/auto-match` | POST | FLUTTER_READY |
| `/api/games/daily-reward` | GET, POST | FLUTTER_READY |
| `/api/games/daily-spin` | POST | FLUTTER_READY |
| `/api/games/grid-settings` | GET | PUBLIC |
| `/api/games/lamba-cini` | GET, POST | FLUTTER_READY |
| `/api/games/leaderboard` | GET | FLUTTER_READY |
| `/api/games/lobby` | GET | FLUTTER_READY |
| `/api/games/play` | POST | FLUTTER_READY |
| `/api/games/profile` | GET | FLUTTER_READY |
| `/api/games/quests` | GET, POST | FLUTTER_READY |
| `/api/games/room` | GET, POST | FLUTTER_READY |
| `/api/games/room/[roomId]` | DELETE, GET, PATCH, POST | FLUTTER_READY |
| `/api/games/room/[roomId]/chat` | GET, PATCH, POST | FLUTTER_READY |
| `/api/games/room/[roomId]/replace-ai` | POST | FLUTTER_READY |
| `/api/games/room/[roomId]/viewers` | DELETE, GET, POST | FLUTTER_READY |
| `/api/games/rooms` | GET | PUBLIC |
| `/api/games/sos` | GET, POST | FLUTTER_READY |
| `/api/games/sos/[gameId]` | DELETE, GET, PATCH, POST | FLUTTER_READY |
| `/api/games/sos/[gameId]/chat` | GET, PATCH, POST | FLUTTER_READY |
| `/api/games/sos/[gameId]/viewers` | DELETE, GET, POST | FLUTTER_READY |
| `/api/referral` | GET | FLUTTER_READY |
| `/api/referral/validate` | GET | PUBLIC |

## 14. Sıralama & Turnuva

Liderlik tabloları, haftalık/aylık sıralama, turnuvalar, ajans sıralaması

**3 rota** — mobil: 3, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/leaderboards` | GET | FLUTTER_READY |
| `/api/leaderboards/top100` | GET | FLUTTER_READY |
| `/api/tournaments` | GET | FLUTTER_READY |

## 15. Ajans

Ajans başvurusu, üyeler, davet, kazanç, cüzdan/transfer, komisyon, büyüme, canlı durum

**16 rota** — mobil: 16, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/agency/applicant-score/[userId]` | GET | FLUTTER_READY |
| `/api/agency/apply` | POST | FLUTTER_READY |
| `/api/agency/earnings` | GET | FLUTTER_READY |
| `/api/agency/growth` | GET | FLUTTER_READY |
| `/api/agency/invite` | GET, POST | FLUTTER_READY |
| `/api/agency/invite-earnings` | GET | FLUTTER_READY |
| `/api/agency/join` | POST | FLUTTER_READY |
| `/api/agency/leaderboard` | GET | PUBLIC |
| `/api/agency/leave` | DELETE, POST | FLUTTER_READY |
| `/api/agency/live-status` | GET | FLUTTER_READY |
| `/api/agency/members` | DELETE, GET, POST | FLUTTER_READY |
| `/api/agency/my` | GET, PATCH | FLUTTER_READY |
| `/api/agency/tasks` | GET | FLUTTER_READY |
| `/api/agency/wallet` | GET | FLUTTER_READY |
| `/api/agency/wallet/transfer` | POST | FLUTTER_READY |
| `/api/agency/withdrawals` | GET, POST | FLUTTER_READY |

## 16. Kozmetik & Bana Özel

Avatar aksesuarı, giriş efekti, mikrofon çerçevesi, profil çerçevesi, isim efekti, sohbet balonu, emoji paketi, tema, animasyon

**15 rota** — mobil: 15, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/animations/manifest` | GET | PUBLIC |
| `/api/animations/me` | GET | FLUTTER_READY |
| `/api/animations/resolve` | GET | FLUTTER_READY |
| `/api/avatar-accessories` | GET | PUBLIC |
| `/api/bana-ozel` | GET | FLUTTER_READY |
| `/api/bana-ozel/open` | POST | FLUTTER_READY |
| `/api/chat-bubbles` | GET | PUBLIC |
| `/api/effects/resolve` | GET | FLUTTER_READY |
| `/api/emoji-packs` | GET | PUBLIC |
| `/api/entrance-effects` | GET | PUBLIC |
| `/api/mic-frames` | GET | PUBLIC |
| `/api/name-effects` | GET | PUBLIC |
| `/api/profile-frames` | GET, POST | FLUTTER_READY |
| `/api/room-themes` | GET | PUBLIC |
| `/api/room-themes/catalog` | GET | FLUTTER_READY |

## 17. İçerik & CMS

Blog, site sayfaları, SSS, iletişim, trendler, video/TikTok/YouTube içerikleri, futbol/dizi-film, SEO, yasal

**24 rota** — mobil: 24, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/blog` | GET | PUBLIC |
| `/api/blog/categories` | GET | PUBLIC |
| `/api/blog/comments` | DELETE, GET, POST | FLUTTER_READY |
| `/api/blog/favorite` | POST | FLUTTER_READY |
| `/api/blog/interactions` | GET | FLUTTER_READY |
| `/api/blog/like` | POST | FLUTTER_READY |
| `/api/blog/related` | GET | PUBLIC |
| `/api/blog/zodiac` | GET | PUBLIC |
| `/api/contact` | POST | PUBLIC |
| `/api/football` | GET | PUBLIC |
| `/api/homepage-buttons` | GET | PUBLIC |
| `/api/homepage-fortune-cards` | GET | PUBLIC |
| `/api/legal/child-safety` | GET | PUBLIC |
| `/api/seo-settings` | GET | PUBLIC |
| `/api/site-pages/[slug]` | GET | PUBLIC |
| `/api/tiktok-videos` | GET | PUBLIC |
| `/api/tiktok-videos/[id]` | GET | PUBLIC |
| `/api/tiktok-videos/oembed` | GET | PUBLIC |
| `/api/tmdb` | GET | PUBLIC |
| `/api/trend-videos` | GET, POST | PUBLIC |
| `/api/trends` | GET | PUBLIC |
| `/api/trends/[slug]` | GET | PUBLIC |
| `/api/trends/[slug]/like` | POST | FLUTTER_READY |
| `/api/youtube/search` | GET | FLUTTER_READY |

## 18. Altyapı & Sistem

Bootstrap, config, deeplink, önbellek, sağlık kontrolü, izleme, cron görevleri, yükleme, platform, public

**13 rota** — mobil: 11, admin: 0

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/[...unmatched]` | DELETE, GET, HEAD, OPTIONS, PATCH, POST, PUT | PUBLIC |
| `/api/bootstrap` | GET | FLUTTER_READY |
| `/api/cache` | GET, POST | FLUTTER_READY |
| `/api/config` | GET | PUBLIC |
| `/api/cron/membership-expiry` | GET, POST | INTERNAL |
| `/api/deeplink/resolve` | GET | PUBLIC |
| `/api/health` | GET | PUBLIC |
| `/api/monitoring` | GET | WEB_ONLY |
| `/api/platform/commission-rate` | GET | PUBLIC |
| `/api/public-stats` | GET | PUBLIC |
| `/api/public/announcement-settings` | GET | PUBLIC |
| `/api/public/jeton-price` | GET | PUBLIC |
| `/api/warmup` | GET | PUBLIC |

## 19. Yönetim Paneli (Admin)

Kullanıcı, finans, çekim, moderasyon, içerik, reklam, kozmetik, üyelik, entegrasyon, raporlar, RBAC, yedekleme

**161 rota** — mobil: 0, admin: 161

| Yol | Metotlar | Sınıf |
|---|---|---|
| `/api/admin/activity-feed` | GET, POST | ADMIN_ONLY |
| `/api/admin/ad-networks` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/ad-placements` | GET, POST | ADMIN_ONLY |
| `/api/admin/ad-placements/[id]` | DELETE, GET, PATCH | ADMIN_ONLY |
| `/api/admin/ad-placements/stats` | GET | ADMIN_ONLY |
| `/api/admin/agencies` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/agencies/[agencyId]/commission` | GET, PUT | ADMIN_ONLY |
| `/api/admin/agencies/[agencyId]/wallet` | GET, POST | ADMIN_ONLY |
| `/api/admin/agency-applicant-config` | GET, PUT | ADMIN_ONLY |
| `/api/admin/agency-finance` | GET, PUT | ADMIN_ONLY |
| `/api/admin/animations` | GET, POST | ADMIN_ONLY |
| `/api/admin/animations/[id]` | DELETE, GET, PATCH | ADMIN_ONLY |
| `/api/admin/animations/assignments` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/animations/membership-defaults` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/animations/stats` | GET | ADMIN_ONLY |
| `/api/admin/announcement-sections` | GET, POST | ADMIN_ONLY |
| `/api/admin/audit-logs` | GET | ADMIN_ONLY |
| `/api/admin/avatar-accessories` | GET | ADMIN_ONLY |
| `/api/admin/awards` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/backup` | GET | ADMIN_ONLY |
| `/api/admin/badges` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/bana-ozel` | GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/blog` | GET, POST | ADMIN_ONLY |
| `/api/admin/blog/[postId]` | DELETE, PATCH, PUT | ADMIN_ONLY |
| `/api/admin/blog/analytics` | GET | ADMIN_ONLY |
| `/api/admin/blog/bulk-category` | PATCH | ADMIN_ONLY |
| `/api/admin/blog/bulk-delete` | POST | ADMIN_ONLY |
| `/api/admin/blog/bulk-generate` | POST | ADMIN_ONLY |
| `/api/admin/blog/bulk-import` | POST | ADMIN_ONLY |
| `/api/admin/blog/bulk-publish` | PATCH | ADMIN_ONLY |
| `/api/admin/blog/categories` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/blog/comments` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/blog/generate` | POST | ADMIN_ONLY |
| `/api/admin/blog/import` | POST | ADMIN_ONLY |
| `/api/admin/blog/schedule-publish` | POST | ADMIN_ONLY |
| `/api/admin/bots` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/bots/simulate` | GET, POST | ADMIN_ONLY |
| `/api/admin/bots/simulate-fortune` | GET, POST | ADMIN_ONLY |
| `/api/admin/bots/simulate-master` | GET, POST | ADMIN_ONLY |
| `/api/admin/bots/simulate-social` | GET, POST | ADMIN_ONLY |
| `/api/admin/broadcast-images` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/button-order` | GET, POST | ADMIN_ONLY |
| `/api/admin/cache` | DELETE, GET | ADMIN_ONLY |
| `/api/admin/cfc-arena` | GET, POST | ADMIN_ONLY |
| `/api/admin/cfc-arena/[contestId]` | GET | ADMIN_ONLY |
| `/api/admin/cfc-payment-requests` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/cfc-settings` | GET, POST | ADMIN_ONLY |
| `/api/admin/chat-bubbles` | GET | ADMIN_ONLY |
| `/api/admin/chat-rooms` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/contests` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/credit-packages` | GET, POST | ADMIN_ONLY |
| `/api/admin/credit-packages/[packageId]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/credits` | POST | ADMIN_ONLY |
| `/api/admin/currency-config` | GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/currency-settings` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/dreams` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/dreams/bulk-category` | PATCH | ADMIN_ONLY |
| `/api/admin/dreams/bulk-delete` | POST | ADMIN_ONLY |
| `/api/admin/dreams/bulk-import` | POST | ADMIN_ONLY |
| `/api/admin/dreams/bulk-publish` | PATCH | ADMIN_ONLY |
| `/api/admin/dreams/generate` | POST | ADMIN_ONLY |
| `/api/admin/effect-rules` | GET, POST | ADMIN_ONLY |
| `/api/admin/effect-rules/[ruleId]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/emoji-packs` | GET | ADMIN_ONLY |
| `/api/admin/entrance-effects` | GET | ADMIN_ONLY |
| `/api/admin/feature-flags` | GET, POST | ADMIN_ONLY |
| `/api/admin/feature-flags/[flagId]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/finance` | GET, POST | ADMIN_ONLY |
| `/api/admin/fortune-request-types` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/fortunes` | GET | ADMIN_ONLY |
| `/api/admin/games` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/games/rooms` | DELETE, GET | ADMIN_ONLY |
| `/api/admin/games/settings` | GET, PUT | ADMIN_ONLY |
| `/api/admin/gift-collections` | GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/gift-upload` | POST | ADMIN_ONLY |
| `/api/admin/gifts` | GET, POST | ADMIN_ONLY |
| `/api/admin/gifts/[giftId]` | DELETE, GET, PATCH | ADMIN_ONLY |
| `/api/admin/gifts/stats` | GET | ADMIN_ONLY |
| `/api/admin/global-search` | GET | ADMIN_ONLY |
| `/api/admin/homepage-buttons` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/homepage-fortune-cards` | DELETE, GET, PATCH, POST, PUT | ADMIN_ONLY |
| `/api/admin/integrations/apple` | DELETE, GET, PUT | ADMIN_ONLY |
| `/api/admin/integrations/google-play` | DELETE, GET, PUT | ADMIN_ONLY |
| `/api/admin/integrations/sms` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/integrations/sms/[providerKey]` | DELETE, PATCH, PUT | ADMIN_ONLY |
| `/api/admin/integrations/sms/[providerKey]/test` | POST | ADMIN_ONLY |
| `/api/admin/leaderboards` | GET, POST | ADMIN_ONLY |
| `/api/admin/ledger` | GET | ADMIN_ONLY |
| `/api/admin/live-tellers` | GET, POST | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]` | DELETE, GET, PUT | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]/approve` | POST | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]/ban` | POST | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]/bonus` | POST | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]/freeze` | POST | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]/permissions` | PUT | ADMIN_ONLY |
| `/api/admin/live-tellers/[tellerId]/warning` | DELETE, POST | ADMIN_ONLY |
| `/api/admin/lucky-gifts/tiers` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/membership-badges` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/membership-events` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/membership-features` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/membership-grants` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/membership-reports` | GET | ADMIN_ONLY |
| `/api/admin/membership-tiers` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/memberships` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/memberships/purchases` | GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/mic-frames` | GET | ADMIN_ONLY |
| `/api/admin/moderation` | GET, POST | ADMIN_ONLY |
| `/api/admin/name-effects` | GET | ADMIN_ONLY |
| `/api/admin/notifications` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/online-fal/buttons` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/online-fal/sections` | GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/payment-methods` | GET, POST | ADMIN_ONLY |
| `/api/admin/payments` | GET, POST | ADMIN_ONLY |
| `/api/admin/pending-counts` | GET | ADMIN_ONLY |
| `/api/admin/platform-analytics` | GET | ADMIN_ONLY |
| `/api/admin/popups` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/premium-entrance` | GET, POST | ADMIN_ONLY |
| `/api/admin/profile-frames` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/profile-frames/assign` | POST | ADMIN_ONLY |
| `/api/admin/referral-commission` | GET | ADMIN_ONLY |
| `/api/admin/referral-commission/settings` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/refunds` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/remote-config` | GET, POST | ADMIN_ONLY |
| `/api/admin/remote-config/[configId]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/risk-events` | GET | ADMIN_ONLY |
| `/api/admin/risk-events/[eventId]` | PATCH | ADMIN_ONLY |
| `/api/admin/roles` | GET, POST | ADMIN_ONLY |
| `/api/admin/roles/[roleId]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/room-themes` | GET | ADMIN_ONLY |
| `/api/admin/room-themes/backgrounds` | GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/rooms` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/rtc-telemetry` | GET | ADMIN_ONLY |
| `/api/admin/seo-settings` | GET, POST | ADMIN_ONLY |
| `/api/admin/settings` | GET, POST | ADMIN_ONLY |
| `/api/admin/site-pages` | DELETE, GET, POST, PUT | ADMIN_ONLY |
| `/api/admin/statistics` | GET | ADMIN_ONLY |
| `/api/admin/support` | GET | ADMIN_ONLY |
| `/api/admin/system-stats` | GET | ADMIN_ONLY |
| `/api/admin/teller-levels` | POST | ADMIN_ONLY |
| `/api/admin/teller-performance` | GET | ADMIN_ONLY |
| `/api/admin/teller-verification` | GET, POST | ADMIN_ONLY |
| `/api/admin/ticker-messages` | GET, POST | ADMIN_ONLY |
| `/api/admin/ticker-messages/[messageId]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/tiktok-categories` | DELETE, GET, PATCH, POST | ADMIN_ONLY |
| `/api/admin/tiktok-videos` | DELETE, GET, PATCH, POST, PUT | ADMIN_ONLY |
| `/api/admin/topup-bonus-tiers` | GET, POST | ADMIN_ONLY |
| `/api/admin/topup-bonus-tiers/[id]` | DELETE, PATCH | ADMIN_ONLY |
| `/api/admin/tournaments` | GET, POST | ADMIN_ONLY |
| `/api/admin/trend-videos` | GET, POST | ADMIN_ONLY |
| `/api/admin/trend-videos/youtube` | POST | ADMIN_ONLY |
| `/api/admin/trends` | DELETE, GET, POST | ADMIN_ONLY |
| `/api/admin/users` | GET | ADMIN_ONLY |
| `/api/admin/users/[userId]` | DELETE, GET, PATCH | ADMIN_ONLY |
| `/api/admin/users/[userId]/360` | GET | ADMIN_ONLY |
| `/api/admin/users/[userId]/manage` | GET, POST | ADMIN_ONLY |
| `/api/admin/users/search` | GET | ADMIN_ONLY |
| `/api/admin/users/withdrawal-limit` | POST | ADMIN_ONLY |
| `/api/admin/verification` | GET, PATCH | ADMIN_ONLY |
| `/api/admin/video-streams` | DELETE, GET, PATCH | ADMIN_ONLY |
| `/api/admin/visitor-stats` | GET | ADMIN_ONLY |
| `/api/admin/withdrawals` | GET, POST | ADMIN_ONLY |
