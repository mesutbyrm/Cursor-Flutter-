# CanlıFal — Tam Endpoint Envanteri

Toplam endpoint (path+method): **852**  ·  Toplam route dosyası: **549**  ·  Grup sayısı: **110**

Kimlik doğrulama kodları: `mobile-jwt` = Bearer JWT (`Authorization: Bearer <token>`), `web-session` = tarayıcı oturum çerezi, `rbac` = rol/izin denetimi, `admin-helper` = admin yardımcı guard, `public` = açık.

> Flutter istemcisi tüm çağrıları `mobile-jwt` ile yapar. `/api/v1/...` öneki middleware tarafından `/api/...` adresine yönlendirilir.

## /[...unmatched]  (7 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| DELETE | `/api/[...unmatched]` | public |  |  | — |
| GET | `/api/[...unmatched]` | public |  |  | — |
| HEAD | `/api/[...unmatched]` | public |  |  | — |
| OPTIONS | `/api/[...unmatched]` | public |  |  | — |
| PATCH | `/api/[...unmatched]` | public |  |  | — |
| POST | `/api/[...unmatched]` | public |  |  | — |
| PUT | `/api/[...unmatched]` | public |  |  | — |

## /activities  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/activities` | admin-helper/mobile-jwt | ✔ |  | — |

## /admin  (291 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/admin/activity-feed` | web-session | ✔ |  | — |
| POST | `/api/admin/activity-feed` | web-session | ✔ |  | — |
| DELETE | `/api/admin/ad-networks` | web-session | ✔ |  | — |
| GET | `/api/admin/ad-networks` | web-session | ✔ |  | — |
| POST | `/api/admin/ad-networks` | web-session | ✔ |  | — |
| GET | `/api/admin/ad-placements` | admin-helper | ✔ |  | — |
| POST | `/api/admin/ad-placements` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/ad-placements/[id]` | admin-helper | ✔ |  | — |
| GET | `/api/admin/ad-placements/[id]` | admin-helper | ✔ |  | — |
| PATCH | `/api/admin/ad-placements/[id]` | admin-helper | ✔ |  | — |
| GET | `/api/admin/ad-placements/stats` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/agencies` | rbac | ✔ |  | agencyId |
| GET | `/api/admin/agencies` | rbac | ✔ |  | agencyId |
| PATCH | `/api/admin/agencies` | rbac | ✔ |  | agencyId |
| POST | `/api/admin/agencies` | rbac | ✔ |  | agencyId |
| GET | `/api/admin/animations` | admin-helper | ✔ |  | — |
| POST | `/api/admin/animations` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/animations/[id]` | admin-helper | ✔ |  | — |
| GET | `/api/admin/animations/[id]` | admin-helper | ✔ |  | — |
| PATCH | `/api/admin/animations/[id]` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/animations/assignments` | admin-helper | ✔ |  | — |
| GET | `/api/admin/animations/assignments` | admin-helper | ✔ |  | — |
| PATCH | `/api/admin/animations/assignments` | admin-helper | ✔ |  | — |
| POST | `/api/admin/animations/assignments` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/animations/membership-defaults` | admin-helper | ✔ |  | — |
| GET | `/api/admin/animations/membership-defaults` | admin-helper | ✔ |  | — |
| POST | `/api/admin/animations/membership-defaults` | admin-helper | ✔ |  | — |
| GET | `/api/admin/animations/stats` | admin-helper | ✔ |  | — |
| GET | `/api/admin/announcement-sections` | web-session | ✔ |  | — |
| POST | `/api/admin/announcement-sections` | web-session | ✔ |  | — |
| GET | `/api/admin/audit-logs` | web-session | ✔ |  | — |
| GET | `/api/admin/avatar-accessories` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/awards` | web-session | ✔ |  | awardType, endDate, startDate, tellerId, title |
| GET | `/api/admin/awards` | web-session | ✔ |  | awardType, endDate, startDate, tellerId, title |
| POST | `/api/admin/awards` | web-session | ✔ |  | awardType, endDate, startDate, tellerId, title |
| GET | `/api/admin/backup` | web-session | ✔ |  | — |
| DELETE | `/api/admin/badges` | web-session | ✔ |  | — |
| GET | `/api/admin/badges` | web-session | ✔ |  | — |
| POST | `/api/admin/badges` | web-session | ✔ |  | — |
| PUT | `/api/admin/badges` | web-session | ✔ |  | — |
| GET | `/api/admin/bana-ozel` | web-session | ✔ |  | — |
| PATCH | `/api/admin/bana-ozel` | web-session | ✔ |  | — |
| POST | `/api/admin/bana-ozel` | web-session | ✔ |  | — |
| GET | `/api/admin/blog` | web-session | ✔ |  | — |
| POST | `/api/admin/blog` | web-session | ✔ |  | — |
| DELETE | `/api/admin/blog/[postId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/blog/[postId]` | web-session | ✔ |  | — |
| PUT | `/api/admin/blog/[postId]` | web-session | ✔ |  | — |
| GET | `/api/admin/blog/analytics` | web-session | ✔ |  | — |
| PATCH | `/api/admin/blog/bulk-category` | web-session | ✔ |  | category, postIds |
| POST | `/api/admin/blog/bulk-delete` | web-session | ✔ |  | postIds |
| POST | `/api/admin/blog/bulk-generate` | web-session | ✔ |  | autoPublish, category, topics, zodiacSign |
| POST | `/api/admin/blog/bulk-import` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/blog/bulk-publish` | web-session | ✔ |  | isPublished, postIds |
| DELETE | `/api/admin/blog/categories` | web-session | ✔ |  | nameEn, nameTr, slug |
| GET | `/api/admin/blog/categories` | web-session | ✔ |  | nameEn, nameTr, slug |
| POST | `/api/admin/blog/categories` | web-session | ✔ |  | nameEn, nameTr, slug |
| GET | `/api/admin/blog/comments` | web-session | ✔ |  | action, commentId |
| PATCH | `/api/admin/blog/comments` | web-session | ✔ |  | action, commentId |
| POST | `/api/admin/blog/generate` | web-session | ✔ |  | — |
| POST | `/api/admin/blog/import` | web-session | ✔ |  | — |
| POST | `/api/admin/blog/schedule-publish` | web-session | ✔ |  | — |
| GET | `/api/admin/bots` | web-session | ✔ |  | — |
| PATCH | `/api/admin/bots` | web-session | ✔ |  | — |
| GET | `/api/admin/bots/simulate` | web-session | ✔ |  | — |
| POST | `/api/admin/bots/simulate` | web-session | ✔ |  | — |
| GET | `/api/admin/bots/simulate-fortune` | web-session | ✔ |  | — |
| POST | `/api/admin/bots/simulate-fortune` | web-session | ✔ |  | — |
| GET | `/api/admin/bots/simulate-master` | web-session | ✔ |  | — |
| POST | `/api/admin/bots/simulate-master` | web-session | ✔ |  | — |
| GET | `/api/admin/bots/simulate-social` | web-session | ✔ |  | — |
| POST | `/api/admin/bots/simulate-social` | web-session | ✔ |  | — |
| DELETE | `/api/admin/broadcast-images` | web-session | ✔ |  | id, imageUrl, isActive, name, sortOrder |
| GET | `/api/admin/broadcast-images` | web-session | ✔ |  | id, imageUrl, isActive, name, sortOrder |
| PATCH | `/api/admin/broadcast-images` | web-session | ✔ |  | id, imageUrl, isActive, name, sortOrder |
| POST | `/api/admin/broadcast-images` | web-session | ✔ |  | id, imageUrl, isActive, name, sortOrder |
| GET | `/api/admin/button-order` | web-session | ✔ |  | — |
| POST | `/api/admin/button-order` | web-session | ✔ |  | — |
| DELETE | `/api/admin/cache` | web-session | ✔ |  | — |
| GET | `/api/admin/cache` | web-session | ✔ |  | — |
| GET | `/api/admin/cfc-payment-requests` | rbac | ✔ |  | — |
| PATCH | `/api/admin/cfc-payment-requests` | rbac | ✔ |  | — |
| GET | `/api/admin/cfc-settings` | web-session | ✔ |  | — |
| POST | `/api/admin/cfc-settings` | web-session | ✔ |  | — |
| GET | `/api/admin/chat-bubbles` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/chat-rooms` | web-session | ✔ |  | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId |
| GET | `/api/admin/chat-rooms` | web-session | ✔ |  | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId |
| POST | `/api/admin/chat-rooms` | web-session | ✔ |  | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId |
| PUT | `/api/admin/chat-rooms` | web-session | ✔ |  | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId |
| DELETE | `/api/admin/contests` | web-session | ✔ |  | — |
| GET | `/api/admin/contests` | web-session | ✔ |  | — |
| PATCH | `/api/admin/contests` | web-session | ✔ |  | — |
| POST | `/api/admin/contests` | web-session | ✔ |  | — |
| GET | `/api/admin/credit-packages` | web-session | ✔ |  | — |
| POST | `/api/admin/credit-packages` | web-session | ✔ |  | — |
| DELETE | `/api/admin/credit-packages/[packageId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/credit-packages/[packageId]` | web-session | ✔ |  | — |
| POST | `/api/admin/credits` | web-session | ✔ |  | — |
| GET | `/api/admin/currency-config` | web-session | ✔ |  | — |
| POST | `/api/admin/currency-config` | web-session | ✔ |  | — |
| PUT | `/api/admin/currency-config` | web-session | ✔ |  | — |
| GET | `/api/admin/currency-settings` | web-session | ✔ |  | — |
| PATCH | `/api/admin/currency-settings` | web-session | ✔ |  | — |
| DELETE | `/api/admin/dreams` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/dreams` | admin-helper/web-session | ✔ |  | — |
| POST | `/api/admin/dreams` | admin-helper/web-session | ✔ |  | — |
| PUT | `/api/admin/dreams` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/dreams/bulk-category` | web-session | ✔ |  | category, dreamIds |
| POST | `/api/admin/dreams/bulk-delete` | web-session | ✔ |  | dreamIds |
| POST | `/api/admin/dreams/bulk-import` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/dreams/bulk-publish` | web-session | ✔ |  | dreamIds, isPublished |
| POST | `/api/admin/dreams/generate` | web-session | ✔ |  | title |
| GET | `/api/admin/effect-rules` | rbac | ✔ |  | — |
| POST | `/api/admin/effect-rules` | rbac | ✔ |  | — |
| DELETE | `/api/admin/effect-rules/[ruleId]` | rbac | ✔ |  | — |
| PATCH | `/api/admin/effect-rules/[ruleId]` | rbac | ✔ |  | — |
| GET | `/api/admin/emoji-packs` | admin-helper | ✔ |  | — |
| GET | `/api/admin/entrance-effects` | admin-helper | ✔ |  | — |
| GET | `/api/admin/feature-flags` | web-session | ✔ |  | — |
| POST | `/api/admin/feature-flags` | web-session | ✔ |  | — |
| DELETE | `/api/admin/feature-flags/[flagId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/feature-flags/[flagId]` | web-session | ✔ |  | — |
| GET | `/api/admin/finance` | web-session | ✔ |  | — |
| POST | `/api/admin/finance` | web-session | ✔ |  | — |
| DELETE | `/api/admin/fortune-request-types` | web-session | ✔ |  | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| GET | `/api/admin/fortune-request-types` | web-session | ✔ |  | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| PATCH | `/api/admin/fortune-request-types` | web-session | ✔ |  | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| POST | `/api/admin/fortune-request-types` | web-session | ✔ |  | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| GET | `/api/admin/fortunes` | web-session | ✔ |  | — |
| DELETE | `/api/admin/games` | web-session | ✔ |  | — |
| GET | `/api/admin/games` | web-session | ✔ |  | — |
| POST | `/api/admin/games` | web-session | ✔ |  | — |
| PUT | `/api/admin/games` | web-session | ✔ |  | — |
| DELETE | `/api/admin/games/rooms` | web-session | ✔ |  | roomId |
| GET | `/api/admin/games/rooms` | web-session | ✔ |  | roomId |
| GET | `/api/admin/games/settings` | web-session | ✔ |  | — |
| PUT | `/api/admin/games/settings` | web-session | ✔ |  | — |
| GET | `/api/admin/gift-collections` | web-session | ✔ |  | — |
| PATCH | `/api/admin/gift-collections` | web-session | ✔ |  | — |
| POST | `/api/admin/gift-collections` | web-session | ✔ |  | — |
| POST | `/api/admin/gift-upload` | web-session | ✔ |  | — |
| GET | `/api/admin/gifts` | web-session | ✔ |  | — |
| POST | `/api/admin/gifts` | web-session | ✔ |  | — |
| DELETE | `/api/admin/gifts/[giftId]` | web-session | ✔ |  | — |
| GET | `/api/admin/gifts/[giftId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/gifts/[giftId]` | web-session | ✔ |  | — |
| GET | `/api/admin/gifts/stats` | web-session | ✔ |  | — |
| DELETE | `/api/admin/homepage-buttons` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/homepage-buttons` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/homepage-buttons` | admin-helper/web-session | ✔ |  | — |
| POST | `/api/admin/homepage-buttons` | admin-helper/web-session | ✔ |  | — |
| DELETE | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ✔ |  | — |
| POST | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ✔ |  | — |
| PUT | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/leaderboards` | web-session | ✔ |  | — |
| POST | `/api/admin/leaderboards` | web-session | ✔ |  | — |
| GET | `/api/admin/ledger` | web-session | ✔ |  | — |
| GET | `/api/admin/live-tellers` | web-session | ✔ |  | bio, displayName, isVerified, pricePerSession, specialties, userId |
| POST | `/api/admin/live-tellers` | web-session | ✔ |  | bio, displayName, isVerified, pricePerSession, specialties, userId |
| DELETE | `/api/admin/live-tellers/[tellerId]` | web-session | ✔ |  | — |
| GET | `/api/admin/live-tellers/[tellerId]` | web-session | ✔ |  | — |
| PUT | `/api/admin/live-tellers/[tellerId]` | web-session | ✔ |  | — |
| POST | `/api/admin/live-tellers/[tellerId]/approve` | web-session | ✔ |  | action, note |
| POST | `/api/admin/live-tellers/[tellerId]/ban` | web-session | ✔ |  | action, reason |
| POST | `/api/admin/live-tellers/[tellerId]/bonus` | web-session | ✔ |  | amount, reason |
| POST | `/api/admin/live-tellers/[tellerId]/freeze` | web-session | ✔ |  | action, reason |
| PUT | `/api/admin/live-tellers/[tellerId]/permissions` | web-session | ✔ |  | — |
| DELETE | `/api/admin/live-tellers/[tellerId]/warning` | web-session | ✔ |  | reason |
| POST | `/api/admin/live-tellers/[tellerId]/warning` | web-session | ✔ |  | reason |
| DELETE | `/api/admin/lucky-gifts/tiers` | web-session | ✔ |  | — |
| GET | `/api/admin/lucky-gifts/tiers` | web-session | ✔ |  | — |
| PATCH | `/api/admin/lucky-gifts/tiers` | web-session | ✔ |  | — |
| POST | `/api/admin/lucky-gifts/tiers` | web-session | ✔ |  | — |
| DELETE | `/api/admin/membership-badges` | web-session | ✔ |  | — |
| GET | `/api/admin/membership-badges` | web-session | ✔ |  | — |
| PATCH | `/api/admin/membership-badges` | web-session | ✔ |  | — |
| POST | `/api/admin/membership-badges` | web-session | ✔ |  | — |
| DELETE | `/api/admin/memberships` | web-session | ✔ |  | — |
| GET | `/api/admin/memberships` | web-session | ✔ |  | — |
| POST | `/api/admin/memberships` | web-session | ✔ |  | — |
| PUT | `/api/admin/memberships` | web-session | ✔ |  | — |
| GET | `/api/admin/memberships/purchases` | web-session | ✔ |  | — |
| PATCH | `/api/admin/memberships/purchases` | web-session | ✔ |  | — |
| POST | `/api/admin/memberships/purchases` | web-session | ✔ |  | — |
| GET | `/api/admin/mic-frames` | admin-helper | ✔ |  | — |
| GET | `/api/admin/moderation` | web-session | ✔ |  | — |
| POST | `/api/admin/moderation` | web-session | ✔ |  | — |
| GET | `/api/admin/name-effects` | admin-helper | ✔ |  | — |
| DELETE | `/api/admin/notifications` | web-session | ✔ |  | — |
| GET | `/api/admin/notifications` | web-session | ✔ |  | — |
| POST | `/api/admin/notifications` | web-session | ✔ |  | — |
| DELETE | `/api/admin/online-fal/buttons` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/online-fal/buttons` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/online-fal/buttons` | admin-helper/web-session | ✔ |  | — |
| POST | `/api/admin/online-fal/buttons` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/online-fal/sections` | admin-helper/web-session | ✔ |  | — |
| PATCH | `/api/admin/online-fal/sections` | admin-helper/web-session | ✔ |  | — |
| POST | `/api/admin/online-fal/sections` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/payment-methods` | web-session | ✔ |  | — |
| POST | `/api/admin/payment-methods` | web-session | ✔ |  | — |
| GET | `/api/admin/payments` | rbac | ✔ |  | — |
| POST | `/api/admin/payments` | rbac | ✔ |  | — |
| GET | `/api/admin/pending-counts` | web-session | ✔ |  | — |
| DELETE | `/api/admin/popups` | web-session | ✔ |  | — |
| GET | `/api/admin/popups` | web-session | ✔ |  | — |
| POST | `/api/admin/popups` | web-session | ✔ |  | — |
| PUT | `/api/admin/popups` | web-session | ✔ |  | — |
| GET | `/api/admin/premium-entrance` | rbac | ✔ |  | — |
| POST | `/api/admin/premium-entrance` | rbac | ✔ |  | — |
| DELETE | `/api/admin/profile-frames` | web-session | ✔ |  | — |
| GET | `/api/admin/profile-frames` | web-session | ✔ |  | — |
| POST | `/api/admin/profile-frames` | web-session | ✔ |  | — |
| POST | `/api/admin/profile-frames/assign` | web-session | ✔ |  | frameId, userId |
| GET | `/api/admin/referral-commission` | web-session | ✔ |  | — |
| GET | `/api/admin/referral-commission/settings` | web-session | ✔ |  | — |
| PATCH | `/api/admin/referral-commission/settings` | web-session | ✔ |  | — |
| GET | `/api/admin/remote-config` | web-session | ✔ |  | — |
| POST | `/api/admin/remote-config` | web-session | ✔ |  | — |
| DELETE | `/api/admin/remote-config/[configId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/remote-config/[configId]` | web-session | ✔ |  | — |
| GET | `/api/admin/risk-events` | rbac | ✔ |  | — |
| PATCH | `/api/admin/risk-events/[eventId]` | rbac | ✔ |  | — |
| GET | `/api/admin/roles` | web-session | ✔ |  | — |
| POST | `/api/admin/roles` | web-session | ✔ |  | — |
| DELETE | `/api/admin/roles/[roleId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/roles/[roleId]` | web-session | ✔ |  | — |
| GET | `/api/admin/room-themes` | admin-helper | ✔ |  | — |
| GET | `/api/admin/room-themes/backgrounds` | web-session | ✔ |  | — |
| PATCH | `/api/admin/room-themes/backgrounds` | web-session | ✔ |  | — |
| POST | `/api/admin/room-themes/backgrounds` | web-session | ✔ |  | — |
| GET | `/api/admin/rooms` | web-session | ✔ |  | giftBeneficiaryId, giftCommissionPercent, roomId |
| PATCH | `/api/admin/rooms` | web-session | ✔ |  | giftBeneficiaryId, giftCommissionPercent, roomId |
| GET | `/api/admin/rtc-telemetry` | rbac | ✔ |  | — |
| GET | `/api/admin/seo-settings` | admin-helper/web-session | ✔ |  | — |
| POST | `/api/admin/seo-settings` | admin-helper/web-session | ✔ |  | — |
| GET | `/api/admin/settings` | web-session | ✔ |  | — |
| POST | `/api/admin/settings` | web-session | ✔ |  | — |
| DELETE | `/api/admin/site-pages` | web-session | ✔ |  | — |
| GET | `/api/admin/site-pages` | web-session | ✔ |  | — |
| POST | `/api/admin/site-pages` | web-session | ✔ |  | — |
| PUT | `/api/admin/site-pages` | web-session | ✔ |  | — |
| GET | `/api/admin/statistics` | web-session | ✔ |  | — |
| GET | `/api/admin/support` | rbac | ✔ |  | — |
| GET | `/api/admin/system-stats` | rbac | ✔ |  | — |
| POST | `/api/admin/teller-levels` | web-session | ✔ |  | — |
| GET | `/api/admin/teller-performance` | web-session | ✔ |  | — |
| GET | `/api/admin/teller-verification` | web-session | ✔ |  | action, note, tellerId |
| POST | `/api/admin/teller-verification` | web-session | ✔ |  | action, note, tellerId |
| GET | `/api/admin/ticker-messages` | web-session | ✔ |  | icon, text |
| POST | `/api/admin/ticker-messages` | web-session | ✔ |  | icon, text |
| DELETE | `/api/admin/ticker-messages/[messageId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/ticker-messages/[messageId]` | web-session | ✔ |  | — |
| DELETE | `/api/admin/tiktok-categories` | web-session | ✔ |  | description, id, isActive, sortOrder, title |
| GET | `/api/admin/tiktok-categories` | web-session | ✔ |  | description, id, isActive, sortOrder, title |
| PATCH | `/api/admin/tiktok-categories` | web-session | ✔ |  | description, id, isActive, sortOrder, title |
| POST | `/api/admin/tiktok-categories` | web-session | ✔ |  | description, id, isActive, sortOrder, title |
| DELETE | `/api/admin/tiktok-videos` | web-session | ✔ |  | — |
| GET | `/api/admin/tiktok-videos` | web-session | ✔ |  | — |
| PATCH | `/api/admin/tiktok-videos` | web-session | ✔ |  | — |
| POST | `/api/admin/tiktok-videos` | web-session | ✔ |  | — |
| PUT | `/api/admin/tiktok-videos` | web-session | ✔ |  | — |
| GET | `/api/admin/topup-bonus-tiers` | web-session | ✔ |  | — |
| POST | `/api/admin/topup-bonus-tiers` | web-session | ✔ |  | — |
| DELETE | `/api/admin/topup-bonus-tiers/[id]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/topup-bonus-tiers/[id]` | web-session | ✔ |  | — |
| GET | `/api/admin/tournaments` | web-session | ✔ |  | — |
| POST | `/api/admin/tournaments` | web-session | ✔ |  | — |
| GET | `/api/admin/trend-videos` | web-session | ✔ |  | — |
| POST | `/api/admin/trend-videos` | web-session | ✔ |  | — |
| POST | `/api/admin/trend-videos/youtube` | web-session | ✔ |  | — |
| DELETE | `/api/admin/trends` | web-session | ✔ |  | — |
| GET | `/api/admin/trends` | web-session | ✔ |  | — |
| POST | `/api/admin/trends` | web-session | ✔ |  | — |
| GET | `/api/admin/users` | web-session | ✔ |  | — |
| DELETE | `/api/admin/users/[userId]` | web-session | ✔ |  | — |
| GET | `/api/admin/users/[userId]` | web-session | ✔ |  | — |
| PATCH | `/api/admin/users/[userId]` | web-session | ✔ |  | — |
| GET | `/api/admin/users/[userId]/manage` | rbac | ✔ |  | — |
| POST | `/api/admin/users/[userId]/manage` | rbac | ✔ |  | — |
| GET | `/api/admin/users/search` | web-session | ✔ |  | — |
| POST | `/api/admin/users/withdrawal-limit` | web-session | ✔ |  | limit, userId |
| GET | `/api/admin/verification` | rbac | ✔ |  | — |
| PATCH | `/api/admin/verification` | rbac | ✔ |  | — |
| DELETE | `/api/admin/video-streams` | web-session | ✔ |  | action, streamId |
| GET | `/api/admin/video-streams` | web-session | ✔ |  | action, streamId |
| PATCH | `/api/admin/video-streams` | web-session | ✔ |  | action, streamId |
| GET | `/api/admin/visitor-stats` | web-session | ✔ |  | — |
| GET | `/api/admin/withdrawals` | web-session | ✔ |  | action, adminNote, requestId |
| POST | `/api/admin/withdrawals` | web-session | ✔ |  | action, adminNote, requestId |

## /ads  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/ads/active` | public |  |  | — |
| GET | `/api/ads/placement` | mobile-jwt/web-session |  |  | — |
| POST | `/api/ads/placement` | mobile-jwt/web-session |  |  | — |
| POST | `/api/ads/reward` | mobile-jwt |  |  | — |

## /agency  (17 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/agency/apply` | mobile-jwt |  |  | contactEmail, contactPhone, description, name |
| GET | `/api/agency/earnings` | mobile-jwt |  |  | — |
| GET | `/api/agency/invite` | mobile-jwt |  |  | expiresInDays, maxUses |
| POST | `/api/agency/invite` | mobile-jwt |  |  | expiresInDays, maxUses |
| GET | `/api/agency/invite-earnings` | web-session |  |  | — |
| POST | `/api/agency/join` | mobile-jwt |  |  | inviteCode |
| GET | `/api/agency/leaderboard` | public |  |  | — |
| DELETE | `/api/agency/leave` | mobile-jwt |  |  | — |
| POST | `/api/agency/leave` | mobile-jwt |  |  | — |
| DELETE | `/api/agency/members` | mobile-jwt |  |  | — |
| GET | `/api/agency/members` | mobile-jwt |  |  | — |
| POST | `/api/agency/members` | mobile-jwt |  |  | — |
| GET | `/api/agency/my` | mobile-jwt |  |  | — |
| PATCH | `/api/agency/my` | mobile-jwt |  |  | — |
| GET | `/api/agency/tasks` | mobile-jwt |  |  | — |
| GET | `/api/agency/withdrawals` | mobile-jwt/web-session |  |  | action, note, requestId |
| POST | `/api/agency/withdrawals` | mobile-jwt/web-session |  |  | action, note, requestId |

## /animations  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/animations/manifest` | public |  |  | — |
| GET | `/api/animations/me` | mobile-jwt |  |  | — |
| GET | `/api/animations/resolve` | mobile-jwt |  |  | — |

## /announcements  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/announcements` | admin-helper/mobile-jwt | ✔ |  | — |
| POST | `/api/announcements` | admin-helper/mobile-jwt | ✔ |  | — |
| POST | `/api/announcements/event` | mobile-jwt | ✔ |  | — |

## /anonymous  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/anonymous` | public |  |  | deviceId, username |
| POST | `/api/anonymous` | public |  |  | deviceId, username |
| POST | `/api/anonymous/watch-ad` | public |  |  | deviceId |

## /astrology-panel  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/astrology-panel` | mobile-jwt |  |  | — |

## /auth  (14 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/auth/[...nextauth]` | public |  |  | — |
| POST | `/api/auth/[...nextauth]` | public |  |  | — |
| POST | `/api/auth/change-password` | mobile-jwt |  |  | currentPassword, newPassword |
| POST | `/api/auth/forgot-password` | public |  |  | email |
| POST | `/api/auth/logout` | mobile-jwt |  |  | — |
| POST | `/api/auth/mobile-apple` | public |  |  | — |
| POST | `/api/auth/mobile-google` | public |  |  | — |
| POST | `/api/auth/mobile-login` | public |  |  | — |
| POST | `/api/auth/mobile-refresh` | public |  |  | — |
| POST | `/api/auth/mobile-register` | public |  |  | — |
| POST | `/api/auth/mobile-tiktok` | public |  |  | — |
| POST | `/api/auth/reclaim-device` | web-session |  |  | — |
| POST | `/api/auth/reset-password` | public |  |  | password, token |
| GET | `/api/auth/verify-device` | web-session |  |  | — |

## /avatar-accessories  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/avatar-accessories` | public-handler |  |  | — |

## /bana-ozel  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/bana-ozel` | mobile-jwt |  |  | — |
| POST | `/api/bana-ozel/open` | mobile-jwt |  |  | — |

## /blog  (10 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/blog` | public |  |  | — |
| GET | `/api/blog/categories` | public |  |  | — |
| DELETE | `/api/blog/comments` | admin-helper/mobile-jwt | ✔ |  | — |
| GET | `/api/blog/comments` | admin-helper/mobile-jwt | ✔ |  | — |
| POST | `/api/blog/comments` | admin-helper/mobile-jwt | ✔ |  | — |
| POST | `/api/blog/favorite` | mobile-jwt |  |  | postId |
| GET | `/api/blog/interactions` | mobile-jwt |  |  | — |
| POST | `/api/blog/like` | mobile-jwt |  |  | postId |
| GET | `/api/blog/related` | public |  |  | — |
| GET | `/api/blog/zodiac` | public |  |  | — |

## /bootstrap  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/bootstrap` | rbac |  |  | — |

## /broadcast-images  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/broadcast-images` | mobile-jwt |  |  | — |

## /cache  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/cache` | mobile-jwt | ✔ |  | — |
| POST | `/api/cache` | mobile-jwt | ✔ |  | — |

## /chat  (59 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/chat/broadcast-images` | public |  |  | — |
| DELETE | `/api/chat/cleanup` | public |  |  | — |
| GET | `/api/chat/cleanup` | public |  |  | — |
| POST | `/api/chat/cleanup` | public |  |  | — |
| GET | `/api/chat/rooms` | public |  |  | — |
| GET | `/api/chat/rooms/[roomId]/dj` | mobile-jwt/web-session | ✔ |  | action, userId |
| POST | `/api/chat/rooms/[roomId]/dj` | mobile-jwt/web-session | ✔ |  | action, userId |
| GET | `/api/chat/rooms/[roomId]/gifts` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/chat/rooms/[roomId]/gifts` | mobile-jwt/web-session | ✔ |  | — |
| DELETE | `/api/chat/rooms/[roomId]/messages` | mobile-jwt/web-session |  |  | content, nickname |
| GET | `/api/chat/rooms/[roomId]/messages` | mobile-jwt/web-session |  |  | content, nickname |
| POST | `/api/chat/rooms/[roomId]/messages` | mobile-jwt/web-session |  |  | content, nickname |
| GET | `/api/chat/rooms/[roomId]/moderation` | mobile-jwt/web-session |  |  | action, duration, message, reason, role, targetUserId, ttl |
| POST | `/api/chat/rooms/[roomId]/moderation` | mobile-jwt/web-session |  |  | action, duration, message, reason, role, targetUserId, ttl |
| DELETE | `/api/chat/rooms/[roomId]/music` | mobile-jwt/web-session |  |  | duration, title, videoId |
| GET | `/api/chat/rooms/[roomId]/music` | mobile-jwt/web-session |  |  | duration, title, videoId |
| POST | `/api/chat/rooms/[roomId]/music` | mobile-jwt/web-session |  |  | duration, title, videoId |
| GET | `/api/chat/rooms/[roomId]/music-queue` | mobile-jwt/web-session |  |  | — |
| POST | `/api/chat/rooms/[roomId]/music/stop` | mobile-jwt/web-session |  |  | — |
| GET | `/api/chat/rooms/[roomId]/pk` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/chat/rooms/[roomId]/pk` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/chat/rooms/[roomId]/pk/score` | mobile-jwt/web-session |  |  | — |
| DELETE | `/api/chat/rooms/[roomId]/presence` | admin-helper/mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/chat/rooms/[roomId]/presence` | admin-helper/mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/chat/rooms/[roomId]/presence` | admin-helper/mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/chat/rooms/[roomId]/seats` | mobile-jwt/web-session |  |  | — |
| PATCH | `/api/chat/rooms/[roomId]/seats` | mobile-jwt/web-session |  |  | — |
| GET | `/api/chat/rooms/[roomId]/settings` | mobile-jwt/web-session |  |  | — |
| PATCH | `/api/chat/rooms/[roomId]/settings` | mobile-jwt/web-session |  |  | — |
| GET | `/api/chat/rooms/[roomId]/song-request` | mobile-jwt/web-session | ✔ |  | requestId |
| PATCH | `/api/chat/rooms/[roomId]/song-request` | mobile-jwt/web-session | ✔ |  | requestId |
| POST | `/api/chat/rooms/[roomId]/song-request` | mobile-jwt/web-session | ✔ |  | requestId |
| DELETE | `/api/chat/rooms/[roomId]/speak-request` | mobile-jwt/web-session |  |  | — |
| GET | `/api/chat/rooms/[roomId]/speak-request` | mobile-jwt/web-session |  |  | — |
| POST | `/api/chat/rooms/[roomId]/speak-request` | mobile-jwt/web-session |  |  | — |
| DELETE | `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | mobile-jwt/web-session |  |  | — |
| POST | `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | mobile-jwt/web-session |  |  | — |
| DELETE | `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | mobile-jwt/web-session |  |  | — |
| POST | `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | mobile-jwt/web-session |  |  | — |
| GET | `/api/chat/rooms/[roomId]/speak-requests` | mobile-jwt/web-session |  |  | — |
| POST | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | mobile-jwt/web-session |  |  | — |
| DELETE | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | public |  |  | — |
| POST | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | public |  |  | — |
| DELETE | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | public |  |  | — |
| POST | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | public |  |  | — |
| GET | `/api/chat/rooms/[roomId]/state` | admin-helper/mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/chat/rooms/[roomId]/stream` | admin-helper/mobile-jwt/web-session | ✔ | ✔ | — |
| POST | `/api/chat/rooms/[roomId]/transfer-ownership` | mobile-jwt/web-session | ✔ |  | newOwnerId |
| GET | `/api/chat/rooms/[roomId]/typing` | mobile-jwt/web-session |  |  | isTyping |
| POST | `/api/chat/rooms/[roomId]/typing` | mobile-jwt/web-session |  |  | isTyping |
| GET | `/api/chat/rooms/[roomId]/voice` | mobile-jwt/web-session |  |  | type |
| POST | `/api/chat/rooms/[roomId]/voice` | mobile-jwt/web-session |  |  | type |
| GET | `/api/chat/rooms/backgrounds` | public |  |  | — |
| POST | `/api/chat/rooms/create` | mobile-jwt | ✔ |  | description, icon, name, paymentType, roomType |
| GET | `/api/chat/rooms/pk-list` | public |  |  | — |
| GET | `/api/chat/rooms/pk/candidates` | mobile-jwt/web-session |  |  | — |
| GET | `/api/chat/youtube-audio` | public |  |  | — |
| POST | `/api/chat/youtube-audio` | public |  |  | — |
| GET | `/api/chat/youtube-stream` | public |  |  | — |

## /chat-bubbles  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/chat-bubbles` | public-handler |  |  | — |

## /compatibility  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/compatibility` | public |  |  | moonSign1, moonSign2, risingSign1, risingSign2, sign1, sign2 |

## /config  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/config` | public |  |  | — |

## /contact  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/contact` | public |  |  | email, message, name |

## /credit-packages  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/credit-packages` | public |  |  | — |

## /currency-branding  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/currency-branding` | public |  |  | — |

## /daily-login  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/daily-login` | mobile-jwt |  |  | — |
| POST | `/api/daily-login` | mobile-jwt |  |  | — |

## /daily-missions  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/daily-missions` | mobile-jwt |  |  | taskType |
| POST | `/api/daily-missions` | mobile-jwt |  |  | taskType |

## /deeplink  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/deeplink/resolve` | public |  |  | — |

## /devices  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| DELETE | `/api/devices/fcm` | mobile-jwt/web-session |  |  | — |
| POST | `/api/devices/fcm` | mobile-jwt/web-session |  |  | — |

## /dream-contest  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/dream-contest` | mobile-jwt |  |  | — |
| GET | `/api/dream-contest/[contestId]/entries` | mobile-jwt |  |  | interpretation |
| POST | `/api/dream-contest/[contestId]/entries` | mobile-jwt |  |  | interpretation |
| POST | `/api/dream-contest/[contestId]/vote` | mobile-jwt |  |  | entryId |

## /dream-diary  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| DELETE | `/api/dream-diary` | mobile-jwt |  |  | analyzeWithAI, content, dreamDate, id, lucidity, mood, symbols, title |
| GET | `/api/dream-diary` | mobile-jwt |  |  | analyzeWithAI, content, dreamDate, id, lucidity, mood, symbols, title |
| POST | `/api/dream-diary` | mobile-jwt |  |  | analyzeWithAI, content, dreamDate, id, lucidity, mood, symbols, title |

## /dream-stats  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/dream-stats` | mobile-jwt |  |  | — |

## /dream-symbols  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/dream-symbols` | public |  |  | — |
| GET | `/api/dream-symbols/[slug]` | public |  |  | — |

## /dreams  (14 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/dreams` | public |  |  | — |
| GET | `/api/dreams/[slug]` | public |  |  | — |
| DELETE | `/api/dreams/[slug]/comments` | admin-helper/mobile-jwt | ✔ |  | commentId, content, didComeTrue, experienceType |
| GET | `/api/dreams/[slug]/comments` | admin-helper/mobile-jwt | ✔ |  | commentId, content, didComeTrue, experienceType |
| POST | `/api/dreams/[slug]/comments` | admin-helper/mobile-jwt | ✔ |  | commentId, content, didComeTrue, experienceType |
| GET | `/api/dreams/[slug]/favorite` | mobile-jwt |  |  | — |
| POST | `/api/dreams/[slug]/favorite` | mobile-jwt |  |  | — |
| POST | `/api/dreams/[slug]/view` | mobile-jwt |  |  | — |
| GET | `/api/dreams/favorites` | mobile-jwt |  |  | — |
| POST | `/api/dreams/generate` | public |  |  | query |
| POST | `/api/dreams/interpret` | mobile-jwt | ✔ |  | dreamText |
| POST | `/api/dreams/morning-reminder` | public |  |  | — |
| GET | `/api/dreams/recommendations` | mobile-jwt |  |  | — |
| GET | `/api/dreams/trends` | public |  |  | — |

## /effects  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/effects/resolve` | rbac |  |  | — |

## /emoji-packs  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/emoji-packs` | public-handler |  |  | — |

## /entrance-effects  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/entrance-effects` | public-handler |  |  | — |

## /favorite-tellers  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/favorite-tellers` | mobile-jwt |  |  | tellerId |
| POST | `/api/favorite-tellers` | mobile-jwt |  |  | tellerId |

## /football  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/football` | public |  |  | — |

## /fortune-access  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/fortune-access/check` | mobile-jwt |  |  | — |
| GET | `/api/fortune-access/ip-status` | public |  |  | — |

## /fortune-request-types  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/fortune-request-types` | public |  |  | — |

## /fortune-tellers  (18 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/fortune-tellers` | mobile-jwt |  |  | — |
| POST | `/api/fortune-tellers` | mobile-jwt |  |  | — |
| GET | `/api/fortune-tellers/[tellerId]` | admin-helper/mobile-jwt/web-session | ✔ |  | — |
| PATCH | `/api/fortune-tellers/[tellerId]` | admin-helper/mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/fortune-tellers/[tellerId]/reviews` | public |  |  | — |
| GET | `/api/fortune-tellers/[tellerId]/session` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/fortune-tellers/[tellerId]/session` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/fortune-tellers/apply` | mobile-jwt |  |  | — |
| GET | `/api/fortune-tellers/awards` | public |  |  | — |
| GET | `/api/fortune-tellers/gifts` | public |  |  | — |
| GET | `/api/fortune-tellers/my-profile` | mobile-jwt |  |  | — |
| GET | `/api/fortune-tellers/session` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/fortune-tellers/session` | mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/fortune-tellers/sessions` | mobile-jwt/web-session |  |  | — |
| PATCH | `/api/fortune-tellers/sessions/[sessionId]` | mobile-jwt/web-session |  |  | — |
| GET | `/api/fortune-tellers/sessions/stream` | mobile-jwt/web-session |  | ✔ | — |
| GET | `/api/fortune-tellers/toggle-online` | mobile-jwt |  |  | — |
| POST | `/api/fortune-tellers/toggle-online` | mobile-jwt |  |  | — |

## /fortunes  (15 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/fortunes/ask-uyumu` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/aura-analizi` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/burc-yorumu` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/dogum-haritasi` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/el-fali` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/evet-hayir` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/istihare` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/kahve-fali` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/kahve-fali-image` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/katina` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/kursundokme` | mobile-jwt |  |  | — |
| POST | `/api/fortunes/melek-kartlari` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/numeroloji` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/ruya-yorumu` | mobile-jwt |  | ✔ | — |
| POST | `/api/fortunes/tarot-fali` | mobile-jwt |  | ✔ | — |

## /games  (40 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/games` | public |  |  | — |
| POST | `/api/games/auto-match` | mobile-jwt/web-session |  |  | — |
| GET | `/api/games/daily-reward` | mobile-jwt |  |  | — |
| POST | `/api/games/daily-reward` | mobile-jwt |  |  | — |
| POST | `/api/games/daily-spin` | mobile-jwt |  |  | — |
| GET | `/api/games/grid-settings` | public |  |  | — |
| GET | `/api/games/lamba-cini` | mobile-jwt |  |  | chestIndex |
| POST | `/api/games/lamba-cini` | mobile-jwt |  |  | chestIndex |
| GET | `/api/games/leaderboard` | mobile-jwt |  |  | — |
| GET | `/api/games/lobby` | mobile-jwt |  |  | — |
| POST | `/api/games/play` | mobile-jwt |  |  | gameSlug, result, score |
| GET | `/api/games/profile` | mobile-jwt |  |  | — |
| GET | `/api/games/quests` | mobile-jwt |  |  | questType |
| POST | `/api/games/quests` | mobile-jwt |  |  | questType |
| GET | `/api/games/room` | mobile-jwt | ✔ |  | betAmount, betCurrency, gameType, gridSize, isAI, turnTimer |
| POST | `/api/games/room` | mobile-jwt | ✔ |  | betAmount, betCurrency, gameType, gridSize, isAI, turnTimer |
| DELETE | `/api/games/room/[roomId]` | mobile-jwt | ✔ |  | — |
| GET | `/api/games/room/[roomId]` | mobile-jwt | ✔ |  | — |
| PATCH | `/api/games/room/[roomId]` | mobile-jwt | ✔ |  | — |
| POST | `/api/games/room/[roomId]` | mobile-jwt | ✔ |  | — |
| GET | `/api/games/room/[roomId]/chat` | mobile-jwt |  |  | chatEnabled, message |
| PATCH | `/api/games/room/[roomId]/chat` | mobile-jwt |  |  | chatEnabled, message |
| POST | `/api/games/room/[roomId]/chat` | mobile-jwt |  |  | chatEnabled, message |
| POST | `/api/games/room/[roomId]/replace-ai` | mobile-jwt |  |  | — |
| DELETE | `/api/games/room/[roomId]/viewers` | mobile-jwt |  |  | — |
| GET | `/api/games/room/[roomId]/viewers` | mobile-jwt |  |  | — |
| POST | `/api/games/room/[roomId]/viewers` | mobile-jwt |  |  | — |
| GET | `/api/games/rooms` | public |  |  | — |
| GET | `/api/games/sos` | mobile-jwt | ✔ |  | betAmount, betCurrency, gridSize, isAI, turnTimer |
| POST | `/api/games/sos` | mobile-jwt | ✔ |  | betAmount, betCurrency, gridSize, isAI, turnTimer |
| DELETE | `/api/games/sos/[gameId]` | mobile-jwt | ✔ |  | — |
| GET | `/api/games/sos/[gameId]` | mobile-jwt | ✔ |  | — |
| PATCH | `/api/games/sos/[gameId]` | mobile-jwt | ✔ |  | — |
| POST | `/api/games/sos/[gameId]` | mobile-jwt | ✔ |  | — |
| GET | `/api/games/sos/[gameId]/chat` | mobile-jwt |  |  | chatEnabled, message |
| PATCH | `/api/games/sos/[gameId]/chat` | mobile-jwt |  |  | chatEnabled, message |
| POST | `/api/games/sos/[gameId]/chat` | mobile-jwt |  |  | chatEnabled, message |
| DELETE | `/api/games/sos/[gameId]/viewers` | mobile-jwt |  |  | — |
| GET | `/api/games/sos/[gameId]/viewers` | mobile-jwt |  |  | — |
| POST | `/api/games/sos/[gameId]/viewers` | mobile-jwt |  |  | — |

## /gift-engine  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/gift-engine/finish` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gift-engine/gifts` | public |  |  | — |
| GET | `/api/gift-engine/queue` | public |  |  | — |

## /gifts  (27 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/gifts/battles` | mobile-jwt/web-session |  |  | — |
| POST | `/api/gifts/battles` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/battles/[battleId]` | public |  |  | — |
| GET | `/api/gifts/catalog` | mobile-jwt/web-session |  |  | — |
| POST | `/api/gifts/check-reciprocal` | mobile-jwt |  |  | recipientId |
| GET | `/api/gifts/goals` | mobile-jwt/web-session |  |  | — |
| POST | `/api/gifts/goals` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/insights/album/[userId]` | public |  |  | — |
| GET | `/api/gifts/insights/badge/[userId]` | public |  |  | — |
| GET | `/api/gifts/insights/collection/[userId]` | public |  |  | — |
| GET | `/api/gifts/insights/feed` | public |  |  | — |
| GET | `/api/gifts/insights/first-gifter/[context]/[contextId]` | public |  |  | — |
| GET | `/api/gifts/insights/leaderboard` | public |  |  | — |
| GET | `/api/gifts/insights/map` | public |  |  | — |
| GET | `/api/gifts/insights/me/badge` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/insights/me/history` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/insights/me/recommendations` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/lucky/config` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/lucky/history` | mobile-jwt/web-session |  |  | — |
| POST | `/api/gifts/lucky/send` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/missions` | public |  |  | — |
| POST | `/api/gifts/missions/[missionId]/claim` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/missions/me` | mobile-jwt/web-session |  |  | — |
| GET | `/api/gifts/recent-big` | public |  |  | — |
| POST | `/api/gifts/send` | mobile-jwt | ✔ |  | giftTypeId, jetonAmount, recipientUsername, type |
| GET | `/api/gifts/types` | public |  |  | — |
| GET | `/api/gifts/version` | public |  |  | — |

## /hashtags  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/hashtags/[name]` | mobile-jwt |  |  | — |
| GET | `/api/hashtags/search` | public |  |  | — |
| GET | `/api/hashtags/trending` | public |  |  | — |

## /health  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/health` | public |  |  | — |

## /homepage-buttons  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/homepage-buttons` | public |  |  | — |

## /homepage-fortune-cards  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/homepage-fortune-cards` | public |  |  | — |

## /homepage-ticker  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/homepage-ticker` | public |  |  | — |

## /horoscope  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/horoscope/daily` | mobile-jwt/web-session |  |  | — |

## /jeton  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/jeton` | mobile-jwt |  |  | action |
| POST | `/api/jeton` | mobile-jwt |  |  | action |

## /leaderboards  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/leaderboards` | mobile-jwt |  |  | — |
| GET | `/api/leaderboards/top100` | mobile-jwt/web-session |  |  | — |

## /legal  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/legal/child-safety` | public |  |  | — |

## /live  (19 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/live/create-room` | mobile-jwt |  |  | — |
| GET | `/api/live/gift-types` | mobile-jwt |  |  | — |
| POST | `/api/live/gift/send` | mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/live/guest` | mobile-jwt/web-session |  |  | — |
| POST | `/api/live/guest` | mobile-jwt/web-session |  |  | — |
| GET | `/api/live/guest/list` | public |  |  | — |
| POST | `/api/live/heartbeat` | mobile-jwt |  |  | — |
| POST | `/api/live/join-room` | admin-helper/mobile-jwt | ✔ |  | — |
| POST | `/api/live/leave-room` | mobile-jwt |  |  | — |
| GET | `/api/live/message` | mobile-jwt |  |  | — |
| POST | `/api/live/message` | mobile-jwt |  |  | — |
| GET | `/api/live/online-users` | mobile-jwt |  |  | — |
| GET | `/api/live/pk` | mobile-jwt |  |  | — |
| POST | `/api/live/pk` | mobile-jwt |  |  | — |
| GET | `/api/live/pk/active` | public |  |  | — |
| POST | `/api/live/pk/score` | mobile-jwt/rbac |  |  | — |
| GET | `/api/live/rooms` | mobile-jwt |  |  | — |
| GET | `/api/live/seats` | mobile-jwt |  |  | — |
| POST | `/api/live/seats` | mobile-jwt |  |  | — |

## /me  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/me` | mobile-jwt |  |  | — |
| PATCH | `/api/me` | mobile-jwt |  |  | — |

## /membership  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/membership/plans` | public |  |  | — |
| POST | `/api/membership/purchase` | public |  |  | — |

## /membership-badges  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/membership-badges` | public |  |  | — |

## /memberships  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/memberships` | public |  |  | — |
| GET | `/api/memberships/packages` | public |  |  | — |
| POST | `/api/memberships/purchase` | mobile-jwt | ✔ |  | paymentMethod, planId |

## /messages  (5 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/messages` | mobile-jwt |  |  | — |
| GET | `/api/messages/[userId]` | mobile-jwt |  |  | content, imageUrl |
| POST | `/api/messages/[userId]` | mobile-jwt |  |  | content, imageUrl |
| PATCH | `/api/messages/request` | mobile-jwt |  |  | action, message, receiverId, requestId |
| POST | `/api/messages/request` | mobile-jwt |  |  | action, message, receiverId, requestId |

## /mic-frames  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/mic-frames` | public-handler |  |  | — |

## /mobile  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/mobile/config` | public |  |  | — |
| GET | `/api/mobile/fortune-menu` | mobile-jwt |  |  | — |
| GET | `/api/mobile/home` | mobile-jwt |  |  | — |
| GET | `/api/mobile/user-profile/[userId]` | mobile-jwt |  |  | — |

## /monitoring  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/monitoring` | web-session |  |  | — |

## /music  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/music/history` | public |  |  | — |
| GET | `/api/music/search` | mobile-jwt |  |  | — |

## /name-effects  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/name-effects` | public-handler |  |  | — |

## /notifications  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| DELETE | `/api/notifications` | mobile-jwt |  |  | markAll, notificationIds |
| GET | `/api/notifications` | mobile-jwt |  |  | markAll, notificationIds |
| POST | `/api/notifications` | mobile-jwt |  |  | markAll, notificationIds |
| GET | `/api/notifications/stream` | mobile-jwt |  | ✔ | — |

## /online-fal  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/online-fal` | public |  |  | — |

## /payments  (9 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/payments/config` | mobile-jwt |  |  | — |
| GET | `/api/payments/methods` | public |  |  | — |
| GET | `/api/payments/notifications/[notificationId]/dispute` | rbac |  |  | — |
| POST | `/api/payments/notifications/[notificationId]/dispute` | rbac |  |  | — |
| GET | `/api/payments/notify` | mobile-jwt/web-session |  |  | — |
| POST | `/api/payments/notify` | mobile-jwt/web-session |  |  | — |
| GET | `/api/payments/requests` | mobile-jwt |  |  | — |
| POST | `/api/payments/requests` | mobile-jwt |  |  | — |
| GET | `/api/payments/settings` | public |  |  | — |

## /pk  (5 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/pk/[matchId]` | public |  |  | — |
| GET | `/api/pk/[matchId]/stream` | public |  | ✔ | — |
| GET | `/api/pk/active` | public |  |  | — |
| GET | `/api/pk/leaderboard` | public |  |  | — |
| GET | `/api/pk/me/invites` | mobile-jwt/web-session |  |  | — |

## /platform  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/platform/commission-rate` | public |  |  | — |

## /popups  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/popups` | mobile-jwt/web-session |  |  | — |

## /presence  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/presence` | mobile-jwt |  |  | — |
| POST | `/api/presence` | mobile-jwt |  |  | — |
| GET | `/api/presence/online-events` | public |  |  | — |
| GET | `/api/presence/sections` | public |  |  | — |

## /profile-frames  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/profile-frames` | mobile-jwt |  |  | frameId |
| POST | `/api/profile-frames` | mobile-jwt |  |  | frameId |

## /public  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/public/announcement-settings` | public |  |  | — |
| GET | `/api/public/jeton-price` | public |  |  | — |

## /public-stats  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/public-stats` | public |  |  | — |

## /referral  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/referral` | mobile-jwt/web-session |  |  | — |
| GET | `/api/referral/validate` | public |  |  | — |

## /room  (12 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/room/[sessionId]` | mobile-jwt/web-session | ✔ |  | — |
| PATCH | `/api/room/[sessionId]` | mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/room/[sessionId]/messages` | mobile-jwt/web-session |  |  | message |
| POST | `/api/room/[sessionId]/messages` | mobile-jwt/web-session |  |  | message |
| GET | `/api/room/[sessionId]/review` | mobile-jwt/web-session |  |  | — |
| POST | `/api/room/[sessionId]/review` | mobile-jwt/web-session |  |  | — |
| GET | `/api/room/[sessionId]/stream` | mobile-jwt/web-session |  | ✔ | — |
| GET | `/api/room/[sessionId]/summary` | mobile-jwt/web-session |  |  | — |
| POST | `/api/room/[sessionId]/tip` | mobile-jwt/web-session | ✔ |  | amount |
| DELETE | `/api/room/signal` | mobile-jwt/web-session |  |  | receiverId, sessionId, signalData, signalType |
| GET | `/api/room/signal` | mobile-jwt/web-session |  |  | receiverId, sessionId, signalData, signalType |
| POST | `/api/room/signal` | mobile-jwt/web-session |  |  | receiverId, sessionId, signalData, signalType |

## /room-themes  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/room-themes` | public-handler |  |  | — |
| GET | `/api/room-themes/catalog` | mobile-jwt/web-session |  |  | — |

## /rtc  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/rtc/telemetry` | rbac |  |  | — |

## /search  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/search` | public |  |  | — |
| GET | `/api/search/advanced` | mobile-jwt |  |  | — |

## /seo-settings  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/seo-settings` | public |  |  | — |

## /settings  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/settings/ads` | public |  |  | — |
| GET | `/api/settings/canlidark-hero` | public |  |  | — |
| GET | `/api/settings/public` | public |  |  | — |
| GET | `/api/settings/themes` | public |  |  | — |

## /share-card  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/share-card` | mobile-jwt |  |  | — |

## /short-videos  (21 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/short-videos` | mobile-jwt |  |  | — |
| DELETE | `/api/short-videos/[id]` | mobile-jwt | ✔ |  | — |
| GET | `/api/short-videos/[id]` | mobile-jwt | ✔ |  | — |
| GET | `/api/short-videos/[id]/comments` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/[id]/comments` | mobile-jwt |  |  | — |
| DELETE | `/api/short-videos/[id]/comments/[commentId]` | admin-helper/mobile-jwt | ✔ |  | — |
| POST | `/api/short-videos/[id]/comments/[commentId]/like` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/[id]/comments/[commentId]/pin` | mobile-jwt | ✔ |  | — |
| GET | `/api/short-videos/[id]/duets` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/[id]/like` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/[id]/save` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/[id]/share` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/[id]/view` | mobile-jwt |  |  | — |
| GET | `/api/short-videos/explore` | mobile-jwt |  |  | — |
| GET | `/api/short-videos/mentions/search` | public |  |  | — |
| GET | `/api/short-videos/music` | public |  |  | — |
| GET | `/api/short-videos/profile/[userId]` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/register` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/upload` | mobile-jwt |  |  | — |
| POST | `/api/short-videos/upload-url` | mobile-jwt |  |  | — |
| GET | `/api/short-videos/user/[userId]` | mobile-jwt |  |  | — |

## /signup  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/signup` | public |  |  | — |

## /site-pages  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/site-pages/[slug]` | public |  |  | — |

## /social  (9 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/social/posts` | mobile-jwt |  |  | content, fortuneId, fortuneType, imageUrl, isPublic, postType, youtubeUrl |
| POST | `/api/social/posts` | mobile-jwt |  |  | content, fortuneId, fortuneType, imageUrl, isPublic, postType, youtubeUrl |
| DELETE | `/api/social/posts/[postId]` | mobile-jwt | ✔ |  | — |
| GET | `/api/social/posts/[postId]` | mobile-jwt | ✔ |  | — |
| DELETE | `/api/social/posts/[postId]/comments` | mobile-jwt | ✔ |  | content |
| GET | `/api/social/posts/[postId]/comments` | mobile-jwt | ✔ |  | content |
| POST | `/api/social/posts/[postId]/comments` | mobile-jwt | ✔ |  | content |
| POST | `/api/social/posts/[postId]/likes` | mobile-jwt |  |  | — |
| POST | `/api/social/posts/[postId]/view` | public |  |  | — |

## /stories  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| DELETE | `/api/stories` | mobile-jwt |  |  | — |
| GET | `/api/stories` | mobile-jwt |  |  | — |
| POST | `/api/stories` | mobile-jwt |  |  | — |

## /support  (5 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/support/tickets` | rbac |  |  | — |
| POST | `/api/support/tickets` | rbac |  |  | — |
| GET | `/api/support/tickets/[ticketId]` | rbac |  |  | — |
| PATCH | `/api/support/tickets/[ticketId]` | rbac |  |  | — |
| POST | `/api/support/tickets/[ticketId]/messages` | rbac |  |  | — |

## /supporter-levels  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/supporter-levels` | rbac |  |  | — |

## /teams  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/teams` | rbac |  |  | — |
| POST | `/api/teams` | rbac |  |  | — |
| GET | `/api/teams/[teamId]` | rbac |  |  | — |
| PATCH | `/api/teams/[teamId]` | rbac |  |  | — |

## /teller  (4 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/teller/analytics` | mobile-jwt |  |  | — |
| GET | `/api/teller/level` | mobile-jwt/web-session |  |  | — |
| GET | `/api/teller/verification` | mobile-jwt |  |  | docUrl |
| POST | `/api/teller/verification` | mobile-jwt |  |  | docUrl |

## /teller-chat  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/teller-chat` | mobile-jwt/web-session |  |  | — |
| GET | `/api/teller-chat/[sessionId]` | mobile-jwt/web-session |  |  | — |
| POST | `/api/teller-chat/[sessionId]` | mobile-jwt/web-session |  |  | — |

## /tencent  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/tencent/webhook` | public |  |  | — |

## /tiktok-videos  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/tiktok-videos` | public |  |  | — |
| GET | `/api/tiktok-videos/[id]` | public |  |  | — |
| GET | `/api/tiktok-videos/oembed` | public |  |  | — |

## /tmdb  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/tmdb` | public |  |  | — |

## /tournaments  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/tournaments` | mobile-jwt/web-session |  |  | — |

## /translations  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/translations` | public |  |  | — |

## /trend-videos  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/trend-videos` | public |  |  | — |
| POST | `/api/trend-videos` | public |  |  | — |

## /trends  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/trends` | public |  |  | — |
| GET | `/api/trends/[slug]` | public |  |  | — |
| POST | `/api/trends/[slug]/like` | mobile-jwt |  |  | — |

## /trtc  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| POST | `/api/trtc/token` | mobile-jwt |  |  | — |
| POST | `/api/trtc/usersig` | mobile-jwt |  |  | — |
| POST | `/api/trtc/webhook` | public |  |  | — |

## /upload  (3 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/upload/get-url` | mobile-jwt |  |  | — |
| POST | `/api/upload/get-url` | mobile-jwt |  |  | — |
| POST | `/api/upload/presigned` | mobile-jwt |  |  | — |

## /user  (34 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/user/[userId]/achievements` | mobile-jwt |  |  | — |
| DELETE | `/api/user/[userId]/follow` | mobile-jwt |  |  | — |
| POST | `/api/user/[userId]/follow` | mobile-jwt |  |  | — |
| GET | `/api/user/[userId]/follow-status` | mobile-jwt |  |  | — |
| GET | `/api/user/achievements` | mobile-jwt |  |  | — |
| GET | `/api/user/active-sessions` | mobile-jwt |  |  | — |
| GET | `/api/user/activity` | mobile-jwt |  |  | — |
| PATCH | `/api/user/activity` | mobile-jwt |  |  | — |
| GET | `/api/user/block` | mobile-jwt |  |  | userId |
| POST | `/api/user/block` | mobile-jwt |  |  | userId |
| DELETE | `/api/user/blocked` | mobile-jwt |  |  | id, type |
| GET | `/api/user/blocked` | mobile-jwt |  |  | id, type |
| GET | `/api/user/broadcast-history` | mobile-jwt |  |  | — |
| GET | `/api/user/co-broadcast-invites` | mobile-jwt |  |  | — |
| GET | `/api/user/credits` | mobile-jwt |  |  | — |
| GET | `/api/user/followers` | mobile-jwt |  |  | — |
| GET | `/api/user/following` | mobile-jwt |  |  | — |
| GET | `/api/user/fortunes` | mobile-jwt |  |  | — |
| PATCH | `/api/user/fortunes/[fortuneId]` | mobile-jwt |  |  | — |
| GET | `/api/user/likers` | mobile-jwt |  |  | — |
| GET | `/api/user/profile` | mobile-jwt |  |  | — |
| PATCH | `/api/user/profile` | mobile-jwt |  |  | — |
| GET | `/api/user/received-gifts` | mobile-jwt |  |  | — |
| GET | `/api/user/referral-earnings` | web-session |  |  | — |
| POST | `/api/user/report` | mobile-jwt |  |  | details, reason, userId |
| GET | `/api/user/statistics` | mobile-jwt |  |  | — |
| GET | `/api/user/stats` | mobile-jwt |  |  | — |
| POST | `/api/user/stats` | mobile-jwt |  |  | — |
| GET | `/api/user/theme` | mobile-jwt |  |  | theme |
| PATCH | `/api/user/theme` | mobile-jwt |  |  | theme |
| GET | `/api/user/wallet` | mobile-jwt/web-session |  |  | — |
| GET | `/api/user/watch-ad` | mobile-jwt |  |  | — |
| POST | `/api/user/watch-ad` | mobile-jwt |  |  | — |
| GET | `/api/user/xp` | mobile-jwt |  |  | — |

## /users  (7 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/users/[userId]` | mobile-jwt |  |  | — |
| GET | `/api/users/[userId]/follow` | mobile-jwt |  |  | — |
| POST | `/api/users/[userId]/follow` | mobile-jwt |  |  | — |
| GET | `/api/users/[userId]/posts` | mobile-jwt |  |  | — |
| GET | `/api/users/lookup/[username]` | mobile-jwt |  |  | — |
| GET | `/api/users/online` | public |  |  | — |
| GET | `/api/users/search` | mobile-jwt |  |  | — |

## /verification  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/verification` | rbac |  |  | — |
| POST | `/api/verification` | rbac |  |  | — |

## /video-streams  (54 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/video-streams` | mobile-jwt/web-session |  |  | — |
| POST | `/api/video-streams` | mobile-jwt/web-session |  |  | — |
| GET | `/api/video-streams/[streamId]` | admin-helper/mobile-jwt/web-session | ✔ |  | backgroundUrl, broadcastImage, description, isImageMode, status, title |
| PATCH | `/api/video-streams/[streamId]` | admin-helper/mobile-jwt/web-session | ✔ |  | backgroundUrl, broadcastImage, description, isImageMode, status, title |
| GET | `/api/video-streams/[streamId]/auto-close` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/auto-close` | mobile-jwt |  |  | — |
| DELETE | `/api/video-streams/[streamId]/ban` | mobile-jwt |  |  | reason, userId |
| GET | `/api/video-streams/[streamId]/ban` | mobile-jwt |  |  | reason, userId |
| POST | `/api/video-streams/[streamId]/ban` | mobile-jwt |  |  | reason, userId |
| GET | `/api/video-streams/[streamId]/co-broadcast` | mobile-jwt |  |  | action, userId |
| PATCH | `/api/video-streams/[streamId]/co-broadcast` | mobile-jwt |  |  | action, userId |
| POST | `/api/video-streams/[streamId]/co-broadcast` | mobile-jwt |  |  | action, userId |
| POST | `/api/video-streams/[streamId]/co-broadcast/invite` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/[streamId]/comments` | mobile-jwt |  |  | content, isHidden, nickname |
| POST | `/api/video-streams/[streamId]/comments` | mobile-jwt |  |  | content, isHidden, nickname |
| POST | `/api/video-streams/[streamId]/end` | admin-helper/mobile-jwt | ✔ |  | — |
| DELETE | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | ✔ |  | action, requestId |
| GET | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | ✔ |  | action, requestId |
| PATCH | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | ✔ |  | action, requestId |
| POST | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | ✔ |  | action, requestId |
| GET | `/api/video-streams/[streamId]/fortune-requests/my-status` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/[streamId]/gifts` | mobile-jwt/web-session | ✔ |  | giftTypeId, quantity |
| POST | `/api/video-streams/[streamId]/gifts` | mobile-jwt/web-session | ✔ |  | giftTypeId, quantity |
| DELETE | `/api/video-streams/[streamId]/join` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/join` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/leave` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/[streamId]/like` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/like` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/live-started` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/media-heartbeat` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/[streamId]/messages` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/messages` | mobile-jwt |  |  | — |
| DELETE | `/api/video-streams/[streamId]/moderators` | mobile-jwt |  |  | userId |
| GET | `/api/video-streams/[streamId]/moderators` | mobile-jwt |  |  | userId |
| POST | `/api/video-streams/[streamId]/moderators` | mobile-jwt |  |  | userId |
| DELETE | `/api/video-streams/[streamId]/mute` | mobile-jwt |  |  | expiresAt, reason, viewerId |
| GET | `/api/video-streams/[streamId]/mute` | mobile-jwt |  |  | expiresAt, reason, viewerId |
| POST | `/api/video-streams/[streamId]/mute` | mobile-jwt |  |  | expiresAt, reason, viewerId |
| GET | `/api/video-streams/[streamId]/pk-battle` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/pk-battle` | mobile-jwt |  |  | — |
| DELETE | `/api/video-streams/[streamId]/signal` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/[streamId]/signal` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/[streamId]/signal` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/[streamId]/stream` | mobile-jwt |  | ✔ | — |
| GET | `/api/video-streams/[streamId]/viewers` | public |  |  | — |
| GET | `/api/video-streams/gifts` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/pk` | mobile-jwt/web-session | ✔ |  | — |
| POST | `/api/video-streams/pk` | mobile-jwt/web-session | ✔ |  | — |
| GET | `/api/video-streams/pk/candidates` | mobile-jwt/web-session |  |  | — |
| GET | `/api/video-streams/pk/list` | public |  |  | — |
| POST | `/api/video-streams/pk/score` | mobile-jwt/web-session | ✔ |  | battleId, points, streamId |
| DELETE | `/api/video-streams/signal` | mobile-jwt |  |  | — |
| GET | `/api/video-streams/signal` | mobile-jwt |  |  | — |
| POST | `/api/video-streams/signal` | mobile-jwt |  |  | — |

## /wallet  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/wallet` | mobile-jwt |  |  | — |

## /warmup  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/warmup` | public |  |  | — |

## /weekly-dream-report  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/weekly-dream-report` | mobile-jwt |  |  | — |
| POST | `/api/weekly-dream-report` | mobile-jwt |  |  | — |

## /withdrawals  (2 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/withdrawals` | mobile-jwt/web-session |  |  | accountDetails, amount, currency, method |
| POST | `/api/withdrawals` | mobile-jwt/web-session |  |  | accountDetails, amount, currency, method |

## /youtube  (1 endpoint)

| Method | Path | Auth | Admin | SSE | Body alanları |
|---|---|---|---|---|---|
| GET | `/api/youtube/search` | mobile-jwt |  |  | — |
