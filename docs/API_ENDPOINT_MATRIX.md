# API Endpoint Matrix
Date: 2026-08-08
Source: uploaded `endpoints_index__1__8c3d.json`, `openapi__2__605a.json`, Flutter `api_endpoints.dart`.
Status legend: CONNECTED = normalized Flutter path exists; MISSING = backend endpoint has no matching Flutter endpoint constant; WRONG = Flutter endpoint path is not in backend index; PARTIAL = connected but auth/body/runtime still needs feature test; DEPRECATED = documented old/removed path.

Summary: backend handlers `690`, unique backend paths `438`, Flutter normalized paths `436`, connected normalized paths `256`, Flutter-only normalized paths `180`.

## Backend -> Flutter matrix (all backend handlers)
| Backend Endpoint | Method | Auth | Flutter Service | Flutter Method | Request Model | Response Model | SSE | Status |
|---|---:|---|---|---|---|---|---|---|
| `/api/activities` | GET | dual | `activities` | `activities` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/admin/activity-feed` | GET | session | `adminActivityFeed` | `adminActivityFeed` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/activity-feed` | POST | session | `adminActivityFeed` | `adminActivityFeed` | `isEnabled, maxItems, specificUserIds, visibleToAdmin, visibleToBasic, visibleToD` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/ad-networks` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/ad-networks` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/ad-networks` | POST | session | `-` | `-` | `adCode, adUnitId, appId, id, isActive, name, provider, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/agencies` | DELETE | session | `-` | `-` | `agencyId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/agencies` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/agencies` | PATCH | session | `-` | `-` | `action, agencyId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/announcement-sections` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/announcement-sections` | POST | session | `-` | `-` | `categoryConfig, categoryKey, categorySettings, giftAnnouncementSettings` | OpenAPI/docs | NO | MISSING |
| `/api/admin/awards` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/awards` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/awards` | POST | session | `-` | `-` | `awardType, endDate, startDate, tellerId, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/backup` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/badges` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/badges` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/badges` | POST | session | `-` | `-` | `bgColor, color, description, icon, name, tier, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/badges` | PUT | session | `-` | `-` | `bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bana-ozel` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bana-ozel` | PATCH | session | `-` | `-` | `id` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bana-ozel` | POST | session | `-` | `-` | `category, icon, jetonCost, nameEn, nameTr, slug, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog` | POST | session | `-` | `-` | `authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGene` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/analytics` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/bulk-category` | PATCH | session | `-` | `-` | `category, postIds` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/bulk-delete` | POST | session | `-` | `-` | `postIds` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/bulk-generate` | POST | session | `-` | `-` | `autoPublish, category, topics, zodiacSign` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/bulk-import` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/bulk-publish` | PATCH | session | `-` | `-` | `isPublished, postIds` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/categories` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/categories` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/categories` | POST | session | `-` | `-` | `nameEn, nameTr, slug` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/comments` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/comments` | PATCH | session | `-` | `-` | `action, commentId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/generate` | POST | session | `-` | `-` | `keywords, mode, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/import` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/schedule-publish` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/{postId}` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/{postId}` | PATCH | session | `-` | `-` | `authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGene` | OpenAPI/docs | NO | MISSING |
| `/api/admin/blog/{postId}` | PUT | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots` | PATCH | session | `-` | `-` | `action, activityLevel, botIds, isActive, personality` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate` | POST | session | `-` | `-` | `action, roomId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate-fortune` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate-fortune` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate-master` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate-master` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate-social` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/bots/simulate-social` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/broadcast-images` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/broadcast-images` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/broadcast-images` | PATCH | session | `-` | `-` | `id, imageUrl, isActive, name, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/broadcast-images` | POST | session | `-` | `-` | `imageUrl, name, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/button-order` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/button-order` | POST | session | `-` | `-` | `order` | OpenAPI/docs | NO | MISSING |
| `/api/admin/cache` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/cache` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/cfc-payment-requests` | GET | session | `adminCfcPaymentRequests, adminCfcPaymentPatch` | `adminCfcPaymentRequests, adminCfcPaymentPatch` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/cfc-payment-requests` | PATCH | session | `adminCfcPaymentRequests, adminCfcPaymentPatch` | `adminCfcPaymentRequests, adminCfcPaymentPatch` | `action, requestId, reviewNote` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/cfc-settings` | GET | session | `adminCfcSettings` | `adminCfcSettings` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/cfc-settings` | POST | session | `adminCfcSettings` | `adminCfcSettings` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/chat-rooms` | DELETE | session | `-` | `-` | `roomId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/chat-rooms` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/chat-rooms` | POST | session | `-` | `-` | `description, icon, name, roomType` | OpenAPI/docs | NO | MISSING |
| `/api/admin/chat-rooms` | PUT | session | `-` | `-` | `backgroundImage, descEn, descTr, giftCommissionPercent, icon, isActive, isMuted,` | OpenAPI/docs | NO | MISSING |
| `/api/admin/contests` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/contests` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/contests` | PATCH | session | `-` | `-` | `description, dreamPrompt, endDate, id, isActive, startDate, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/contests` | POST | session | `-` | `-` | `description, dreamPrompt, endDate, startDate, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/credit-packages` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/credit-packages` | POST | session | `-` | `-` | `bonusCredits, credits, currency, isFeatured, name, nameEn, price, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/credit-packages/{packageId}` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/credit-packages/{packageId}` | PATCH | session | `-` | `-` | `bonusCredits, credits, currency, isActive, isFeatured, name, nameEn, price, sort` | OpenAPI/docs | NO | MISSING |
| `/api/admin/credits` | POST | session | `adminCredits` | `adminCredits` | `amount, currency, userId` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/currency-config` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/currency-config` | POST | session | `-` | `-` | `area, areaName, cost, currencyType, id, isActive` | OpenAPI/docs | NO | MISSING |
| `/api/admin/currency-config` | PUT | session | `-` | `-` | `configs` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams` | POST | session | `-` | `-` | `category, content, isPublished, keywords, metaDescription, summary, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams` | PUT | session | `-` | `-` | `category, content, id, isPublished, keywords, metaDescription, summary, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams/bulk-category` | PATCH | session | `-` | `-` | `category, dreamIds` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams/bulk-delete` | POST | session | `-` | `-` | `dreamIds` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams/bulk-import` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams/bulk-publish` | PATCH | session | `-` | `-` | `dreamIds, isPublished` | OpenAPI/docs | NO | MISSING |
| `/api/admin/dreams/generate` | POST | session | `-` | `-` | `title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/finance` | GET | session | `adminFinance` | `adminFinance` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/finance` | POST | session | `adminFinance` | `adminFinance` | `action, amount, currency, key, reason, userId, value` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/fortune-request-types` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/fortune-request-types` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/fortune-request-types` | PATCH | session | `-` | `-` | `description, icon, id, isActive, jetonCost, name, nameEn, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/fortune-request-types` | POST | session | `-` | `-` | `description, icon, jetonCost, name, nameEn, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/fortunes` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games` | POST | session | `-` | `-` | `config, description, entryFee, icon, isActive, maxReward, minReward, slug, sortO` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games` | PUT | session | `-` | `-` | `config, description, entryFee, icon, id, isActive, maxReward, minReward, sortOrd` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games/rooms` | DELETE | session | `-` | `-` | `roomId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games/rooms` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games/settings` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/games/settings` | PUT | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/gift-collections` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/gift-collections` | PATCH | session | `-` | `-` | `description, iconCloudPath, iconEmoji, iconUrl, id, isActive, name, nameEn, slug` | OpenAPI/docs | NO | MISSING |
| `/api/admin/gift-collections` | POST | session | `-` | `-` | `description, iconCloudPath, iconEmoji, iconUrl, isActive, name, nameEn, slug, so` | OpenAPI/docs | NO | MISSING |
| `/api/admin/gift-upload` | POST | session | `-` | `-` | `contentType, fileName, purpose` | OpenAPI/docs | NO | MISSING |
| `/api/admin/gifts` | GET | session | `adminGifts` | `adminGifts` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/gifts` | POST | session | `adminGifts` | `adminGifts` | `animEndPoint, animStartPoint, animation, animationDurationMs, animationType, ass` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/gifts/stats` | GET | session | `adminGiftsStats` | `adminGiftsStats` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/gifts/{giftId}` | DELETE | session | `adminGift` | `adminGift` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/gifts/{giftId}` | GET | session | `adminGift` | `adminGift` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/gifts/{giftId}` | PATCH | session | `adminGift` | `adminGift` | `animationType, assetMimeType, assetType, assetUrl, cloudStoragePath, collectionI` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/homepage-buttons` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-buttons` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-buttons` | PATCH | session | `-` | `-` | `href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-buttons` | POST | session | `-` | `-` | `href, icon, label, specialBehavior` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-fortune-cards` | DELETE | session | `-` | `-` | `id` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-fortune-cards` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-fortune-cards` | PATCH | session | `-` | `-` | `key, settings, value` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-fortune-cards` | POST | session | `-` | `-` | `href, icon, id, image, isActive, name, sortOrder` | OpenAPI/docs | NO | MISSING |
| `/api/admin/homepage-fortune-cards` | PUT | session | `-` | `-` | `id` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers` | POST | session | `-` | `-` | `bio, displayName, isVerified, pricePerSession, specialties, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}` | PUT | session | `-` | `-` | `bio, displayName, isActive, isVerified, pricePerSession, specialties` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/approve` | POST | session | `-` | `-` | `action, note` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/ban` | POST | session | `-` | `-` | `action, reason` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/bonus` | POST | session | `-` | `-` | `amount, reason` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/freeze` | POST | session | `-` | `-` | `action, reason` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/permissions` | PUT | session | `-` | `-` | `adminNotes, canChat, canEditProfile, canGoOnline, canSetPrice, canStartSession, ` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/warning` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/live-tellers/{tellerId}/warning` | POST | session | `-` | `-` | `reason` | OpenAPI/docs | NO | MISSING |
| `/api/admin/lucky-gifts/tiers` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/lucky-gifts/tiers` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/lucky-gifts/tiers` | PATCH | session | `-` | `-` | `id` | OpenAPI/docs | NO | MISSING |
| `/api/admin/lucky-gifts/tiers` | POST | session | `-` | `-` | `color, icon, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight` | OpenAPI/docs | NO | MISSING |
| `/api/admin/membership-badges` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/membership-badges` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/membership-badges` | PATCH | session | `-` | `-` | `id, imageUrl, isActive, name, sortOrder, tier` | OpenAPI/docs | NO | MISSING |
| `/api/admin/membership-badges` | POST | session | `-` | `-` | `imageUrl, isActive, name, sortOrder, tier` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships` | POST | session | `-` | `-` | `bonusJetons, currency, description, descriptionEn, discountPercent, durationDays` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships` | PUT | session | `-` | `-` | `id` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships/purchases` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships/purchases` | PATCH | session | `-` | `-` | `action, extendDays, purchaseId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/memberships/purchases` | POST | session | `-` | `-` | `customTier, durationDays, freeGrant, planId, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/moderation` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/moderation` | POST | session | `-` | `-` | `action, reason, targetId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/notifications` | DELETE | session | `adminNotifications` | `adminNotifications` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/notifications` | GET | session | `adminNotifications` | `adminNotifications` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/notifications` | POST | session | `adminNotifications` | `adminNotifications` | `imageUrl, message, scheduledAt, targetType, targetValue, title, url` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/online-fal/buttons` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/online-fal/buttons` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/online-fal/buttons` | PATCH | session | `-` | `-` | `bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor` | OpenAPI/docs | NO | MISSING |
| `/api/admin/online-fal/buttons` | POST | session | `-` | `-` | `bgColor, borderColor, href, icon, label, textColor` | OpenAPI/docs | NO | MISSING |
| `/api/admin/online-fal/sections` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/online-fal/sections` | PATCH | session | `-` | `-` | `icon, id, isVisible, sortOrder, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/online-fal/sections` | POST | session | `-` | `-` | `order` | OpenAPI/docs | NO | MISSING |
| `/api/admin/payment-methods` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/payment-methods` | POST | session | `-` | `-` | `config, description, descriptionEn, isActive, name, nameEn, sortOrder, type` | OpenAPI/docs | NO | MISSING |
| `/api/admin/payments` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/payments` | PATCH | session | `-` | `-` | `action, jetonAmount, notificationId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/payments` | POST | session | `-` | `-` | `jetonAmount, reason, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/pending-counts` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/popups` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/popups` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/popups` | POST | session | `-` | `-` | `buttons, isActive, maxShowCount, message, popupType, priority, showDelaySeconds,` | OpenAPI/docs | NO | MISSING |
| `/api/admin/popups` | PUT | session | `-` | `-` | `action, buttons, id, isActive, maxShowCount, message, popupType, priority, showD` | OpenAPI/docs | NO | MISSING |
| `/api/admin/profile-frames` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/profile-frames` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/profile-frames` | POST | session | `-` | `-` | `id, imageUrl, isActive, name, sortOrder, tier` | OpenAPI/docs | NO | MISSING |
| `/api/admin/profile-frames/assign` | POST | session | `-` | `-` | `frameId, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/room-themes/backgrounds` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/room-themes/backgrounds` | PATCH | session | `-` | `-` | `backgroundUrl, cloudStoragePath, id, soundCloudPath, soundUrl, thumbnailCloudPat` | OpenAPI/docs | NO | MISSING |
| `/api/admin/room-themes/backgrounds` | POST | session | `-` | `-` | `activeFrom, activeTo, animationSpeed, assetType, backgroundUrl, blurAmount, cate` | OpenAPI/docs | NO | MISSING |
| `/api/admin/rooms` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/rooms` | PATCH | session | `-` | `-` | `giftBeneficiaryId, giftCommissionPercent, roomId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/seo-settings` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/seo-settings` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/settings` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/settings` | POST | session | `-` | `-` | `description, key, value` | OpenAPI/docs | NO | MISSING |
| `/api/admin/site-pages` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/site-pages` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/site-pages` | POST | session | `-` | `-` | `content, contentEn, isPublished, showInFooter, showInHeader, slug, sortOrder, ti` | OpenAPI/docs | NO | MISSING |
| `/api/admin/site-pages` | PUT | session | `-` | `-` | `content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader,` | OpenAPI/docs | NO | MISSING |
| `/api/admin/statistics` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/teller-levels` | POST | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/teller-performance` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/teller-verification` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/teller-verification` | POST | session | `-` | `-` | `action, note, tellerId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/ticker-messages` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/ticker-messages` | POST | session | `-` | `-` | `icon, text` | OpenAPI/docs | NO | MISSING |
| `/api/admin/ticker-messages/{messageId}` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/ticker-messages/{messageId}` | PATCH | session | `-` | `-` | `icon, isActive, sortOrder, text` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-categories` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-categories` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-categories` | PATCH | session | `-` | `-` | `description, id, isActive, sortOrder, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-categories` | POST | session | `-` | `-` | `description, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-videos` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-videos` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-videos` | PATCH | session | `-` | `-` | `categoryId, id, isActive, sortOrder, title` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-videos` | POST | session | `-` | `-` | `categoryId, tiktokUrl, tiktokUrls` | OpenAPI/docs | NO | MISSING |
| `/api/admin/tiktok-videos` | PUT | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/trend-videos` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/trend-videos` | POST | session | `-` | `-` | `action, categoryId, channelName, description, duration, id, isActive, sortOrder,` | OpenAPI/docs | NO | MISSING |
| `/api/admin/trend-videos/youtube` | POST | session | `-` | `-` | `action, maxResults, query, urls` | OpenAPI/docs | NO | MISSING |
| `/api/admin/trends` | DELETE | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/trends` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/trends` | POST | session | `-` | `-` | `id` | OpenAPI/docs | NO | MISSING |
| `/api/admin/users` | GET | session | `adminUsers` | `adminUsers` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/users/search` | GET | session | `adminUsersSearch` | `adminUsersSearch` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/users/withdrawal-limit` | POST | session | `-` | `-` | `limit, userId` | OpenAPI/docs | NO | MISSING |
| `/api/admin/users/{userId}` | DELETE | session | `adminUser` | `adminUser` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/users/{userId}` | GET | session | `adminUser` | `adminUser` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/users/{userId}` | PATCH | session | `adminUser` | `adminUser` | `action, amount, banReason, credits, email, image, membership, membershipExpiresA` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/video-streams` | DELETE | session | `-` | `-` | `streamId` | OpenAPI/docs | YES | MISSING |
| `/api/admin/video-streams` | GET | session | `-` | `-` | `-` | OpenAPI/docs | YES | MISSING |
| `/api/admin/video-streams` | PATCH | session | `-` | `-` | `action, streamId` | OpenAPI/docs | YES | MISSING |
| `/api/admin/visitor-stats` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/admin/withdrawals` | GET | session | `adminWithdrawals` | `adminWithdrawals` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/admin/withdrawals` | POST | session | `adminWithdrawals` | `adminWithdrawals` | `action, adminNote, requestId` | OpenAPI/docs | NO | PARTIAL |
| `/api/ads/active` | GET | public | `adsActive` | `adsActive` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/ads/reward` | POST | dual | `adsReward` | `adsReward` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/apply` | POST | dual | `agencyApply` | `agencyApply` | `contactEmail, contactPhone, description, name` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/earnings` | GET | dual | `agencyEarnings` | `agencyEarnings` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/invite` | GET | dual | `agencyInvite` | `agencyInvite` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/invite` | POST | dual | `agencyInvite` | `agencyInvite` | `expiresInDays, maxUses` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/join` | POST | dual | `agencyJoin` | `agencyJoin` | `inviteCode` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/leaderboard` | GET | public | `agencyLeaderboard` | `agencyLeaderboard` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/leave` | DELETE | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/agency/leave` | POST | dual | `-` | `-` | `action, reason, requestId, reviewNote` | OpenAPI/docs | NO | MISSING |
| `/api/agency/members` | DELETE | dual | `agencyMembers` | `agencyMembers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/members` | GET | dual | `agencyMembers` | `agencyMembers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/members` | POST | dual | `agencyMembers` | `agencyMembers` | `username` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/my` | GET | dual | `agencyMy` | `agencyMy` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/my` | PATCH | dual | `agencyMy` | `agencyMy` | `description, name` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/tasks` | GET | dual | `agencyTasks` | `agencyTasks` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/withdrawals` | GET | dual | `agencyWithdrawals` | `agencyWithdrawals` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/agency/withdrawals` | POST | dual | `agencyWithdrawals` | `agencyWithdrawals` | `action, note, requestId` | OpenAPI/docs | NO | CONNECTED |
| `/api/announcements` | GET | dual | `announcements` | `announcements` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/announcements` | POST | dual | `announcements` | `announcements` | `path, section` | OpenAPI/docs | NO | CONNECTED |
| `/api/announcements/event` | POST | dual | `-` | `-` | `details, eventType` | OpenAPI/docs | NO | MISSING |
| `/api/anonymous` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/anonymous` | POST | public | `-` | `-` | `deviceId, username` | OpenAPI/docs | NO | MISSING |
| `/api/anonymous/watch-ad` | POST | public | `-` | `-` | `deviceId` | OpenAPI/docs | NO | MISSING |
| `/api/astrology-panel` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/auth/change-password` | POST | dual | `authChangePassword` | `authChangePassword` | `currentPassword, newPassword` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/forgot-password` | POST | public | `authForgotPassword` | `authForgotPassword` | `email` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/logout` | POST | dual | `authLogout` | `authLogout` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/mobile-apple` | POST | public | `authMobileApple` | `authMobileApple` | `fullName, identityToken, referralCode` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/mobile-google` | POST | public | `authMobileGoogle` | `authMobileGoogle` | `idToken, referralCode` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/mobile-login` | POST | public | `authMobileLogin` | `authMobileLogin` | `email, password, username` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/mobile-refresh` | POST | public | `authMobileRefresh` | `authMobileRefresh` | `refreshToken` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/mobile-register` | POST | public | `authMobileRegister` | `authMobileRegister` | `birthDate, birthTime, email, name, password, preferredLanguage, referralCode, us` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/mobile-tiktok` | POST | public | `authMobileTiktok` | `authMobileTiktok` | `code, redirectUri, referralCode` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/reclaim-device` | POST | session | `authReclaimDevice` | `authReclaimDevice` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/auth/reset-password` | POST | public | `authResetPassword` | `authResetPassword` | `password, token` | OpenAPI/docs | NO | CONNECTED |
| `/api/auth/verify-device` | GET | session | `authVerifyDevice` | `authVerifyDevice` | `-` | OpenAPI/docs | NO | PARTIAL |
| `/api/auth/{nextauth}` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/auth/{nextauth}` | POST | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/bana-ozel` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/bana-ozel/open` | POST | dual | `-` | `-` | `slug` | OpenAPI/docs | NO | MISSING |
| `/api/blog` | GET | public | `blog` | `blog` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/categories` | GET | public | `blogCategories` | `blogCategories` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/comments` | DELETE | dual | `blogComments` | `blogComments` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/comments` | GET | dual | `blogComments` | `blogComments` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/comments` | POST | dual | `blogComments` | `blogComments` | `content, parentId, postId` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/favorite` | POST | dual | `blogFavorite` | `blogFavorite` | `postId` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/interactions` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/blog/like` | POST | dual | `blogLike` | `blogLike` | `postId` | OpenAPI/docs | NO | CONNECTED |
| `/api/blog/related` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/blog/zodiac` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/broadcast-images` | GET | dual | `broadcastImages` | `broadcastImages` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/cache` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/cache` | POST | dual | `-` | `-` | `channel, data, field, key, member, members, message, op, prefix, score, ttl, val` | OpenAPI/docs | NO | MISSING |
| `/api/chat/broadcast-images` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/chat/cleanup` | DELETE | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/chat/cleanup` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/chat/cleanup` | POST | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/chat/rooms` | GET | public | `chatRooms` | `chatRooms` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/backgrounds` | GET | public | `chatRoomBackgrounds` | `chatRoomBackgrounds` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/create` | POST | dual | `chatRoomCreate` | `chatRoomCreate` | `description, icon, name, paymentType, roomType` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/pk-list` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/chat/rooms/{roomId}/dj` | GET | dual | `chatRoomDj` | `chatRoomDj` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/dj` | POST | dual | `chatRoomDj` | `chatRoomDj` | `action, userId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/gifts` | GET | dual | `chatRoomGifts` | `chatRoomGifts` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/gifts` | POST | dual | `chatRoomGifts` | `chatRoomGifts` | `battleId, giftTypeId, platform, quantity, receiverName, senderName, side, stream` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/messages` | DELETE | dual | `chatRoomMessages` | `chatRoomMessages` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/messages` | GET | dual | `chatRoomMessages` | `chatRoomMessages` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/messages` | POST | dual | `chatRoomMessages` | `chatRoomMessages` | `content, nickname` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/moderation` | GET | dual | `chatRoomModeration` | `chatRoomModeration` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/moderation` | POST | dual | `chatRoomModeration` | `chatRoomModeration` | `action, duration, message, reason, role, targetUserId, ttl` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/music` | DELETE | dual | `chatRoomMusic` | `chatRoomMusic` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/music` | GET | dual | `chatRoomMusic` | `chatRoomMusic` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/music` | POST | dual | `chatRoomMusic` | `chatRoomMusic` | `duration, title, videoId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/music-queue` | GET | dual | `chatRoomMusicQueue` | `chatRoomMusicQueue` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/music/stop` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/chat/rooms/{roomId}/pk` | GET | dual | `chatRoomPk` | `chatRoomPk` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/pk` | POST | dual | `chatRoomPk` | `chatRoomPk` | `action, battleId, duration, targetRoomId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/pk/score` | POST | dual | `chatRoomPkScore` | `chatRoomPkScore` | `amount, battleId, side` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/presence` | DELETE | dual | `chatRoomPresence` | `chatRoomPresence` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/presence` | GET | dual | `chatRoomPresence` | `chatRoomPresence` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/presence` | POST | dual | `chatRoomPresence` | `chatRoomPresence` | `nickname, password, seatIndex` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/seats` | GET | dual | `chatRoomSeats` | `chatRoomSeats` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/seats` | PATCH | dual | `chatRoomSeats` | `chatRoomSeats` | `forceAssign, forceThrone, seatIndex, targetUserId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/settings` | GET | dual | `chatRoomSettings` | `chatRoomSettings` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/settings` | PATCH | dual | `chatRoomSettings` | `chatRoomSettings` | `backgroundImage, bannedWords, bannerImage, descEn, descTr, giftCommissionPercent` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/song-request` | GET | dual | `chatRoomSongRequest` | `chatRoomSongRequest` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/song-request` | PATCH | dual | `chatRoomSongRequest` | `chatRoomSongRequest` | `requestId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/song-request` | POST | dual | `chatRoomSongRequest` | `chatRoomSongRequest` | `dedication, duration, note, priority, requestType, title, videoId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/state` | GET | dual | `chatRoomState` | `chatRoomState` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/stream` | GET | dual | `chatRoomStream` | `chatRoomStream` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/chat/rooms/{roomId}/transfer-ownership` | POST | dual | `chatRoomTransferOwnership` | `chatRoomTransferOwnership` | `newOwnerId` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/typing` | GET | dual | `chatRoomTyping` | `chatRoomTyping` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/typing` | POST | dual | `chatRoomTyping` | `chatRoomTyping` | `isTyping` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/voice` | GET | dual | `chatRoomVoice` | `chatRoomVoice` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/rooms/{roomId}/voice` | POST | dual | `chatRoomVoice` | `chatRoomVoice` | `type` | OpenAPI/docs | NO | CONNECTED |
| `/api/chat/youtube-stream` | GET | public | `chatYoutubeStream` | `chatYoutubeStream` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/compatibility` | POST | public | `-` | `-` | `moonSign1, moonSign2, risingSign1, risingSign2, sign1, sign2` | OpenAPI/docs | NO | MISSING |
| `/api/contact` | POST | public | `-` | `-` | `email, message, name` | OpenAPI/docs | NO | MISSING |
| `/api/credit-packages` | GET | public | `creditPackages` | `creditPackages` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/daily-login` | GET | dual | `dailyLogin` | `dailyLogin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/daily-login` | POST | dual | `dailyLogin` | `dailyLogin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/daily-missions` | GET | dual | `dailyMissions` | `dailyMissions` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/daily-missions` | POST | dual | `dailyMissions` | `dailyMissions` | `taskType` | OpenAPI/docs | NO | CONNECTED |
| `/api/devices/fcm` | DELETE | dual | `registerFcmDevice` | `registerFcmDevice` | `token` | OpenAPI/docs | NO | CONNECTED |
| `/api/devices/fcm` | POST | dual | `registerFcmDevice` | `registerFcmDevice` | `appVersion, platform, token` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-contest` | GET | dual | `dreamContest` | `dreamContest` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-contest/{contestId}/entries` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dream-contest/{contestId}/entries` | POST | dual | `-` | `-` | `interpretation` | OpenAPI/docs | NO | MISSING |
| `/api/dream-contest/{contestId}/vote` | POST | dual | `-` | `-` | `entryId` | OpenAPI/docs | NO | MISSING |
| `/api/dream-diary` | DELETE | dual | `dreamDiary` | `dreamDiary` | `id` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-diary` | GET | dual | `dreamDiary` | `dreamDiary` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-diary` | POST | dual | `dreamDiary` | `dreamDiary` | `analyzeWithAI, content, dreamDate, lucidity, mood, symbols, title` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-stats` | GET | dual | `dreamStats` | `dreamStats` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-symbols` | GET | public | `dreamSymbols` | `dreamSymbols` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/dream-symbols/{slug}` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams` | GET | public | `dreams` | `dreams` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/dreams/favorites` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/generate` | POST | public | `-` | `-` | `query` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/interpret` | POST | dual | `-` | `-` | `dreamText` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/morning-reminder` | POST | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/recommendations` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/trends` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}/comments` | DELETE | dual | `-` | `-` | `commentId` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}/comments` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}/comments` | POST | dual | `-` | `-` | `content, didComeTrue, experienceType` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}/favorite` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}/favorite` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/dreams/{slug}/view` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/favorite-tellers` | GET | dual | `favoriteTellers` | `favoriteTellers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/favorite-tellers` | POST | dual | `favoriteTellers` | `favoriteTellers` | `tellerId` | OpenAPI/docs | NO | CONNECTED |
| `/api/football` | GET | public | `football` | `football` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-access/check` | POST | dual | `fortuneAccessCheck` | `fortuneAccessCheck` | `adWatched, fortuneType` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-access/ip-status` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/fortune-request-types` | GET | public | `fortuneRequestTypes` | `fortuneRequestTypes` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers` | GET | dual | `fortuneTellers` | `fortuneTellers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers` | POST | dual | `fortuneTellers` | `fortuneTellers` | `bio, displayName, pricePerSession, specialties` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/apply` | POST | dual | `fortuneTellerApply` | `fortuneTellerApply` | `applicationNote, bio, displayName, specialties` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/awards` | GET | public | `fortuneTellerAwards` | `fortuneTellerAwards` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/gifts` | GET | public | `fortuneTellerGifts` | `fortuneTellerGifts` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/my-profile` | GET | dual | `fortuneTellerMyProfile` | `fortuneTellerMyProfile` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/session` | GET | dual | `fortuneTellerSession, fortuneTellerSessionQuery` | `fortuneTellerSession, fortuneTellerSessionQuery` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/session` | POST | dual | `fortuneTellerSession, fortuneTellerSessionQuery` | `fortuneTellerSession, fortuneTellerSessionQuery` | `duration, fortuneType, tellerId` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/sessions` | GET | dual | `fortuneTellerSessions` | `fortuneTellerSessions` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/sessions/stream` | GET | dual | `fortuneTellerSessionsStream` | `fortuneTellerSessionsStream` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/fortune-tellers/sessions/{sessionId}` | PATCH | dual | `fortuneTellerSessionPatch` | `fortuneTellerSessionPatch` | `action` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/toggle-online` | GET | dual | `fortuneTellerToggleOnline` | `fortuneTellerToggleOnline` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/toggle-online` | POST | dual | `fortuneTellerToggleOnline` | `fortuneTellerToggleOnline` | `isOnline` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/{tellerId}` | GET | dual | `fortuneTeller` | `fortuneTeller` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/{tellerId}` | PATCH | dual | `fortuneTeller` | `fortuneTeller` | `avatar, bio, displayName, isActive, isOnline, isVerified, pricePerSession, speci` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/{tellerId}/reviews` | GET | public | `fortuneTellerReviews` | `fortuneTellerReviews` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/{tellerId}/session` | GET | dual | `fortuneTellerSessionFor` | `fortuneTellerSessionFor` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortune-tellers/{tellerId}/session` | POST | dual | `fortuneTellerSessionFor` | `fortuneTellerSessionFor` | `duration, fortuneType` | OpenAPI/docs | NO | CONNECTED |
| `/api/fortunes/ask-uyumu` | POST | dual | `-` | `-` | `language, partnerName, partnerSign, yourName, yourSign` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/aura-analizi` | POST | dual | `-` | `-` | `birthDate, currentMood, language, name, recentExperiences` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/burc-yorumu` | POST | dual | `-` | `-` | `language, zodiacSign` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/dogum-haritasi` | POST | dual | `-` | `-` | `birthDate, birthPlace, birthTime, language` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/el-fali` | POST | dual | `-` | `-` | `hand, language, palmImagePath` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/evet-hayir` | POST | dual | `-` | `-` | `language, question` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/istihare` | POST | dual | `-` | `-` | `language, question, situation` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/kahve-fali` | POST | dual | `-` | `-` | `description, language` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/kahve-fali-image` | POST | dual | `-` | `-` | `cupImagePath, language, saucerImagePath` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/katina` | POST | dual | `-` | `-` | `language, question` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/kursundokme` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/melek-kartlari` | POST | dual | `-` | `-` | `cardCount, language, question` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/numeroloji` | POST | dual | `-` | `-` | `birthDate, language, name` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/ruya-yorumu` | POST | dual | `-` | `-` | `dreamDescription, language` | OpenAPI/docs | NO | MISSING |
| `/api/fortunes/tarot-fali` | POST | dual | `-` | `-` | `cardCount, language, question` | OpenAPI/docs | NO | MISSING |
| `/api/games` | GET | public | `homeGames` | `homeGames` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/daily-reward` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/daily-reward` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/daily-spin` | POST | dual | `gamesDailySpin` | `gamesDailySpin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/grid-settings` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/lamba-cini` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/lamba-cini` | POST | dual | `-` | `-` | `chestIndex` | OpenAPI/docs | NO | MISSING |
| `/api/games/leaderboard` | GET | dual | `gameLeaderboard` | `gameLeaderboard` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/lobby` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/play` | POST | dual | `gamePlay` | `gamePlay` | `gameSlug, result, score` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/profile` | GET | dual | `gameProfile` | `gameProfile` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/quests` | GET | dual | `gamesQuests` | `gamesQuests` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/quests` | POST | dual | `gamesQuests` | `gamesQuests` | `questType` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room` | GET | dual | `gameRoomCreate` | `gameRoomCreate` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room` | POST | dual | `gameRoomCreate` | `gameRoomCreate` | `betAmount, betCurrency, gameType, gridSize, isAI, turnTimer` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}` | DELETE | dual | `gameRoom, gameRoomJoin` | `gameRoom, gameRoomJoin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}` | GET | dual | `gameRoom, gameRoomJoin` | `gameRoom, gameRoomJoin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}` | PATCH | dual | `gameRoom, gameRoomJoin` | `gameRoom, gameRoomJoin` | `action, currentTurn, fullState, player1Score, player2Score, state, status, winne` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}` | POST | dual | `gameRoom, gameRoomJoin` | `gameRoom, gameRoomJoin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}/chat` | GET | dual | `gameRoomChat` | `gameRoomChat` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}/chat` | PATCH | dual | `gameRoomChat` | `gameRoomChat` | `chatEnabled` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}/chat` | POST | dual | `gameRoomChat` | `gameRoomChat` | `message` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}/replace-ai` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/room/{roomId}/viewers` | DELETE | dual | `gameRoomViewers` | `gameRoomViewers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}/viewers` | GET | dual | `gameRoomViewers` | `gameRoomViewers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/room/{roomId}/viewers` | POST | dual | `gameRoomViewers` | `gameRoomViewers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/games/sos` | POST | dual | `-` | `-` | `betAmount, betCurrency, gridSize, isAI, turnTimer` | OpenAPI/docs | NO | MISSING |
| `/api/games/sos/{gameId}` | DELETE | dual | `gameSos` | `gameSos` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}` | GET | dual | `gameSos` | `gameSos` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}` | PATCH | dual | `gameSos` | `gameSos` | `action, aiMoves, col, letter, row` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}` | POST | dual | `gameSos` | `gameSos` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}/chat` | GET | dual | `gameSosChat` | `gameSosChat` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}/chat` | PATCH | dual | `gameSosChat` | `gameSosChat` | `chatEnabled` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}/chat` | POST | dual | `gameSosChat` | `gameSosChat` | `message` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}/viewers` | DELETE | dual | `gameSosViewers` | `gameSosViewers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}/viewers` | GET | dual | `gameSosViewers` | `gameSosViewers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/games/sos/{gameId}/viewers` | POST | dual | `gameSosViewers` | `gameSosViewers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/gift-engine/finish` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/gift-engine/gifts` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/gift-engine/queue` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/gifts/catalog` | GET | dual | `giftsCatalogCms` | `giftsCatalogCms` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/check-reciprocal` | POST | dual | `giftsCheckReciprocal` | `giftsCheckReciprocal` | `recipientId` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/lucky/config` | GET | dual | `giftsLuckyConfig` | `giftsLuckyConfig` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/lucky/history` | GET | dual | `giftsLuckyHistory` | `giftsLuckyHistory` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/lucky/send` | POST | dual | `giftsLuckySend` | `giftsLuckySend` | `context, contextId, giftTypeId, quantity` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/recent-big` | GET | public | `giftsRecentBig` | `giftsRecentBig` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/send` | POST | dual | `giftsSend` | `giftsSend` | `giftTypeId, jetonAmount, recipientUsername, type` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/types` | GET | public | `giftsTypes` | `giftsTypes` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/gifts/version` | GET | public | `giftsVersion` | `giftsVersion` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/hashtags/search` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/hashtags/trending` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/hashtags/{name}` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/homepage-buttons` | GET | public | `homepageButtons` | `homepageButtons` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/homepage-fortune-cards` | GET | public | `homepageFortuneCards` | `homepageFortuneCards` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/homepage-ticker` | GET | public | `homepageTicker` | `homepageTicker` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/horoscope/daily` | GET | dual | `horoscopeDaily` | `horoscopeDaily` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/jeton` | GET | dual | `jetonCatalog` | `jetonCatalog` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/jeton` | POST | dual | `jetonCatalog` | `jetonCatalog` | `action` | OpenAPI/docs | NO | CONNECTED |
| `/api/leaderboards` | GET | dual | `leaderboards` | `leaderboards` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/legal/child-safety` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/live/create-room` | POST | dual | `liveCreateRoom` | `liveCreateRoom` | `category, coverUrl, description, thumbnailUrl, title` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/gift-types` | GET | dual | `liveGiftTypes` | `liveGiftTypes` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/gift/send` | POST | dual | `liveGiftSend` | `liveGiftSend` | `giftTypeId, quantity, recipientId, roomId, roomType` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/heartbeat` | POST | dual | `liveHeartbeat` | `liveHeartbeat` | `roomId, roomType` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/join-room` | POST | dual | `liveJoinRoom` | `liveJoinRoom` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/leave-room` | POST | dual | `liveLeaveRoom` | `liveLeaveRoom` | `roomId, roomType` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/message` | GET | dual | `liveMessage` | `liveMessage` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/message` | POST | dual | `liveMessage` | `liveMessage` | `content, roomId, roomType` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/online-users` | GET | dual | `liveOnlineUsers` | `liveOnlineUsers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/pk` | GET | dual | `livePk` | `livePk` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/pk` | POST | dual | `livePk` | `livePk` | `action, battleId, duration, roomId, targetRoomId` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/pk/score` | POST | dual | `livePkScore` | `livePkScore` | `amount, battleId, roomId, side` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/rooms` | GET | dual | `liveRooms` | `liveRooms` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/seats` | GET | dual | `liveSeats` | `liveSeats` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/live/seats` | POST | dual | `liveSeats` | `liveSeats` | `action, roomId, seatIndex, targetUserId` | OpenAPI/docs | NO | CONNECTED |
| `/api/me` | GET | dual | `me` | `me` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/me` | PATCH | dual | `me` | `me` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/membership-badges` | GET | public | `membershipBadges` | `membershipBadges` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/memberships` | GET | public | `membershipsCatalog` | `membershipsCatalog` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/memberships/packages` | GET | public | `membershipPackages` | `membershipPackages` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/memberships/purchase` | POST | dual | `membershipPurchase, membershipsPurchase` | `membershipPurchase, membershipsPurchase` | `paymentMethod, planId` | OpenAPI/docs | NO | CONNECTED |
| `/api/messages` | GET | dual | `messages` | `messages` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/messages/request` | PATCH | dual | `messagesRequest` | `messagesRequest` | `action, requestId` | OpenAPI/docs | NO | CONNECTED |
| `/api/messages/request` | POST | dual | `messagesRequest` | `messagesRequest` | `message, receiverId` | OpenAPI/docs | NO | CONNECTED |
| `/api/messages/{userId}` | GET | dual | `messagesWithUser` | `messagesWithUser` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/messages/{userId}` | POST | dual | `messagesWithUser` | `messagesWithUser` | `content, imageUrl` | OpenAPI/docs | NO | CONNECTED |
| `/api/mobile/config` | GET | public | `mobileConfig` | `mobileConfig` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/mobile/fortune-menu` | GET | dual | `mobileFortuneMenu` | `mobileFortuneMenu` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/mobile/home` | GET | dual | `mobileHome` | `mobileHome` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/mobile/user-profile/{userId}` | GET | dual | `mobileUserProfile` | `mobileUserProfile` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/monitoring` | GET | session | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/music/history` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/music/search` | GET | dual | `musicSearch` | `musicSearch` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/notifications` | DELETE | dual | `notifications` | `notifications` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/notifications` | GET | dual | `notifications` | `notifications` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/notifications` | POST | dual | `notifications` | `notifications` | `markAll, notificationIds` | OpenAPI/docs | NO | CONNECTED |
| `/api/notifications/stream` | GET | dual | `notificationsStream` | `notificationsStream` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/online-fal` | GET | public | `onlineFal` | `onlineFal` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/payments/config` | GET | dual | `paymentConfig` | `paymentConfig` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/payments/methods` | GET | public | `paymentMethods` | `paymentMethods` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/payments/notify` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/payments/notify` | POST | dual | `-` | `-` | `amount, notes, paymentMethod, senderName, transactionId` | OpenAPI/docs | NO | MISSING |
| `/api/payments/requests` | GET | dual | `paymentRequests, paymentRequestsCancel` | `paymentRequests, paymentRequestsCancel` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/payments/requests` | POST | dual | `paymentRequests, paymentRequestsCancel` | `paymentRequests, paymentRequestsCancel` | `amount, method, notes, senderInfo` | OpenAPI/docs | NO | CONNECTED |
| `/api/payments/settings` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/platform/commission-rate` | GET | public | `platformCommissionRate` | `platformCommissionRate` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/popups` | GET | dual | `popups` | `popups` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/presence` | GET | dual | `userPresence` | `userPresence` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/presence` | POST | dual | `userPresence` | `userPresence` | `isNewSession, path, visitorId` | OpenAPI/docs | NO | CONNECTED |
| `/api/presence/sections` | GET | public | `userPresenceSections` | `userPresenceSections` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/profile-frames` | GET | dual | `profileFrames` | `profileFrames` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/profile-frames` | POST | dual | `profileFrames` | `profileFrames` | `frameId` | OpenAPI/docs | NO | CONNECTED |
| `/api/public-stats` | GET | public | `publicStats` | `publicStats` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/public/announcement-settings` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/public/jeton-price` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/referral` | GET | dual | `referral` | `referral` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/referral/validate` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/room-themes/catalog` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/room/signal` | DELETE | dual | `liveFortuneRoomSignal` | `liveFortuneRoomSignal` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/room/signal` | GET | dual | `liveFortuneRoomSignal` | `liveFortuneRoomSignal` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/room/signal` | POST | dual | `liveFortuneRoomSignal` | `liveFortuneRoomSignal` | `receiverId, sessionId, signalData, signalType` | OpenAPI/docs | NO | CONNECTED |
| `/api/room/{sessionId}` | GET | dual | `liveFortuneRoom` | `liveFortuneRoom` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/room/{sessionId}` | PATCH | dual | `liveFortuneRoom` | `liveFortuneRoom` | `action, minutes` | OpenAPI/docs | NO | CONNECTED |
| `/api/room/{sessionId}/messages` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/room/{sessionId}/messages` | POST | dual | `-` | `-` | `message` | OpenAPI/docs | NO | MISSING |
| `/api/room/{sessionId}/review` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/room/{sessionId}/review` | POST | dual | `-` | `-` | `comment, rating` | OpenAPI/docs | NO | MISSING |
| `/api/room/{sessionId}/stream` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | YES | MISSING |
| `/api/room/{sessionId}/summary` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/room/{sessionId}/tip` | POST | dual | `-` | `-` | `amount` | OpenAPI/docs | NO | MISSING |
| `/api/search` | GET | public | `searchAll` | `searchAll` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/search/advanced` | GET | dual | `/api/search/advanced?q=$q&type=${Uri.encodeComponent(t)}, /api/search/advanced?q=$q` | `/api/search/advanced?q=$q&type=${Uri.encodeComponent(t)}, /api/search/advanced?q=$q` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/seo-settings` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/settings/ads` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/settings/canlidark-hero` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/settings/public` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/settings/themes` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/share-card` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/short-videos` | GET | dual | `shortVideos` | `shortVideos` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/explore` | GET | dual | `shortVideosExplore` | `shortVideosExplore` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/mentions/search` | GET | public | `shortVideosMentionsSearch` | `shortVideosMentionsSearch` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/music` | GET | public | `shortVideosMusic` | `shortVideosMusic` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/profile/{userId}` | GET | dual | `shortVideosProfile` | `shortVideosProfile` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/register` | POST | dual | `shortVideosRegister` | `shortVideosRegister` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/upload` | POST | dual | `shortVideosUpload` | `shortVideosUpload` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/upload-url` | POST | dual | `shortVideosUploadUrl` | `shortVideosUploadUrl` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/user/{userId}` | GET | dual | `shortVideosByUser` | `shortVideosByUser` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}` | DELETE | dual | `shortVideo, shortVideoDelete` | `shortVideo, shortVideoDelete` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}` | GET | dual | `shortVideo, shortVideoDelete` | `shortVideo, shortVideoDelete` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/comments` | GET | dual | `shortVideoComments` | `shortVideoComments` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/comments` | POST | dual | `shortVideoComments` | `shortVideoComments` | `content, parentId` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/comments/{commentId}` | DELETE | dual | `shortVideoComment` | `shortVideoComment` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/comments/{commentId}/like` | POST | dual | `shortVideoCommentLike` | `shortVideoCommentLike` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/comments/{commentId}/pin` | POST | dual | `shortVideoCommentPin` | `shortVideoCommentPin` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/duets` | GET | dual | `shortVideoDuets` | `shortVideoDuets` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/like` | POST | dual | `shortVideoLike` | `shortVideoLike` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/save` | POST | dual | `shortVideoSave` | `shortVideoSave` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/share` | POST | dual | `shortVideoShare` | `shortVideoShare` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/short-videos/{id}/view` | POST | dual | `shortVideoView` | `shortVideoView` | `watchedSec` | OpenAPI/docs | NO | CONNECTED |
| `/api/signup` | POST | public | `-` | `-` | `birthDate, birthTime, email, name, password, preferredLanguage, referralCode, us` | OpenAPI/docs | NO | MISSING |
| `/api/site-pages/{slug}` | GET | public | `sitePage` | `sitePage` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts` | GET | dual | `socialPosts, feedPosts` | `socialPosts, feedPosts` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts` | POST | dual | `socialPosts, feedPosts` | `socialPosts, feedPosts` | `content, fortuneId, fortuneType, imageUrl, isPublic, postType, youtubeUrl` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}` | DELETE | dual | `socialPost` | `socialPost` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}` | GET | dual | `socialPost` | `socialPost` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}/comments` | DELETE | dual | `socialPostComments` | `socialPostComments` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}/comments` | GET | dual | `socialPostComments` | `socialPostComments` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}/comments` | POST | dual | `socialPostComments` | `socialPostComments` | `content` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}/likes` | POST | dual | `socialPostLikes` | `socialPostLikes` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/social/posts/{postId}/view` | POST | public | `socialPostView` | `socialPostView` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/stories` | DELETE | dual | `feed` | `feed` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/stories` | GET | dual | `feed` | `feed` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/stories` | POST | dual | `feed` | `feed` | `caption, mediaType, mediaUrl` | OpenAPI/docs | NO | CONNECTED |
| `/api/teller-chat` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/teller-chat/{sessionId}` | GET | dual | `tellerChat` | `tellerChat` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/teller-chat/{sessionId}` | POST | dual | `tellerChat` | `tellerChat` | `content, imageUrl, messageType` | OpenAPI/docs | NO | CONNECTED |
| `/api/teller/analytics` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/teller/level` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/teller/verification` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/teller/verification` | POST | dual | `-` | `-` | `docUrl` | OpenAPI/docs | NO | MISSING |
| `/api/tencent/webhook` | POST | public | `-` | `-` | `CallbackTs, EventGroupId, EventInfo, EventType` | OpenAPI/docs | NO | MISSING |
| `/api/tiktok-videos` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/tiktok-videos/oembed` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/tiktok-videos/{id}` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/tmdb` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/tournaments` | GET | dual | `tournaments` | `tournaments` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/translations` | GET | public | `/api/translations?lang=${Uri.encodeComponent(lang)}` | `/api/translations?lang=${Uri.encodeComponent(lang)}` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/trend-videos` | GET | public | `trendVideos` | `trendVideos` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/trend-videos` | POST | public | `trendVideos` | `trendVideos` | `videoId` | OpenAPI/docs | NO | CONNECTED |
| `/api/trends` | GET | public | `trends` | `trends` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/trends/{slug}` | GET | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/trends/{slug}/like` | POST | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/trtc/token` | POST | dual | `trtcToken` | `trtcToken` | `role, roomId` | OpenAPI/docs | NO | CONNECTED |
| `/api/trtc/usersig` | POST | dual | `trtcUserSig` | `trtcUserSig` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/trtc/webhook` | POST | public | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/upload/get-url` | GET | dual | `uploadGetUrl` | `uploadGetUrl` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/upload/get-url` | POST | dual | `uploadGetUrl` | `uploadGetUrl` | `cloud_storage_path, isPublic` | OpenAPI/docs | NO | CONNECTED |
| `/api/upload/presigned` | POST | dual | `uploadPresigned` | `uploadPresigned` | `contentType, fileName, folder, isPublic` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/achievements` | GET | dual | `userAchievements` | `userAchievements` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/active-sessions` | GET | dual | `userActiveSessions` | `userActiveSessions` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/activity` | GET | dual | `userActivity` | `userActivity` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/activity` | PATCH | dual | `userActivity` | `userActivity` | `markAllRead, notificationIds` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/block` | GET | dual | `userBlock` | `userBlock` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/block` | POST | dual | `userBlock` | `userBlock` | `userId` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/blocked` | DELETE | dual | `userBlocked` | `userBlocked` | `id, type` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/blocked` | GET | dual | `userBlocked` | `userBlocked` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/broadcast-history` | GET | dual | `userBroadcastHistory` | `userBroadcastHistory` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/co-broadcast-invites` | GET | dual | `coBroadcastInvites` | `coBroadcastInvites` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/credits` | GET | dual | `userCredits` | `userCredits` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/followers` | GET | dual | `userFollowers` | `userFollowers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/following` | GET | dual | `userFollowing` | `userFollowing` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/fortunes` | GET | dual | `userFortunes` | `userFortunes` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/fortunes/{fortuneId}` | PATCH | dual | `userFortuneDetail` | `userFortuneDetail` | `action` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/likers` | GET | dual | `userLikers` | `userLikers` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/profile` | GET | dual | `userSiteProfile` | `userSiteProfile` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/profile` | PATCH | dual | `userSiteProfile` | `userSiteProfile` | `bio, birthDate, birthTime, email, favoriteTeam, hideProfileViews, image, message` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/received-gifts` | GET | dual | `userReceivedGifts` | `userReceivedGifts` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/report` | POST | dual | `userReport` | `userReport` | `details, reason, userId` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/statistics` | GET | dual | `userStatistics` | `userStatistics` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/stats` | GET | dual | `userStats` | `userStats` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/stats` | POST | dual | `userStats` | `userStats` | `minutesToAdd` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/theme` | GET | dual | `userTheme` | `userTheme` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/theme` | PATCH | dual | `userTheme` | `userTheme` | `theme` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/watch-ad` | GET | dual | `userWatchAd` | `userWatchAd` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/watch-ad` | POST | dual | `userWatchAd` | `userWatchAd` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/xp` | GET | dual | `userXp` | `userXp` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/{userId}/achievements` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | NO | MISSING |
| `/api/user/{userId}/follow` | DELETE | dual | `userFollow` | `userFollow` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/{userId}/follow` | POST | dual | `userFollow` | `userFollow` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/user/{userId}/follow-status` | GET | dual | `userFollowStatus` | `userFollowStatus` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/lookup/{username}` | GET | dual | `userLookup` | `userLookup` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/online` | GET | public | `usersOnline` | `usersOnline` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/search` | GET | dual | `usersSearch` | `usersSearch` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/{userId}` | GET | dual | `userProfile` | `userProfile` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/{userId}/follow` | GET | dual | `follow` | `follow` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/{userId}/follow` | POST | dual | `follow` | `follow` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/users/{userId}/posts` | GET | dual | `userPosts` | `userPosts` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/video-streams` | GET | dual | `videoStreams` | `videoStreams` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams` | POST | dual | `videoStreams` | `videoStreams` | `category, coverUrl, description, tags, thumbnailUrl, title` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/gifts` | GET | dual | `videoStreamGiftsCatalog` | `videoStreamGiftsCatalog` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/pk` | GET | dual | `videoStreamPk` | `videoStreamPk` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/pk` | POST | dual | `videoStreamPk` | `videoStreamPk` | `action, battleId, duration, opponentVoiceRoomId, streamId, targetStreamId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/pk/list` | GET | public | `videoStreamPkList` | `videoStreamPkList` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/pk/score` | POST | public | `videoStreamPkScore` | `videoStreamPkScore` | `battleId, points, streamId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/signal` | DELETE | dual | `-` | `-` | `-` | OpenAPI/docs | YES | MISSING |
| `/api/video-streams/signal` | GET | dual | `-` | `-` | `-` | OpenAPI/docs | YES | MISSING |
| `/api/video-streams/signal` | POST | dual | `-` | `-` | `data, receiverId, streamId, type` | OpenAPI/docs | YES | MISSING |
| `/api/video-streams/{streamId}` | GET | dual | `videoStream` | `videoStream` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}` | PATCH | dual | `videoStream` | `videoStream` | `backgroundUrl, broadcastImage, description, isImageMode, status, title` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/auto-close` | GET | dual | `videoStreamAutoClose` | `videoStreamAutoClose` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/auto-close` | POST | dual | `videoStreamAutoClose` | `videoStreamAutoClose` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/ban` | DELETE | dual | `videoStreamBan` | `videoStreamBan` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/ban` | GET | dual | `videoStreamBan` | `videoStreamBan` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/ban` | POST | dual | `videoStreamBan` | `videoStreamBan` | `reason, userId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/co-broadcast` | GET | dual | `videoStreamCoBroadcast` | `videoStreamCoBroadcast` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/co-broadcast` | PATCH | dual | `videoStreamCoBroadcast` | `videoStreamCoBroadcast` | `action` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/co-broadcast` | POST | dual | `videoStreamCoBroadcast` | `videoStreamCoBroadcast` | `action, userId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/co-broadcast/invite` | POST | dual | `videoStreamCoBroadcastInvite` | `videoStreamCoBroadcastInvite` | `inviteeId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/comments` | GET | dual | `videoStreamComments` | `videoStreamComments` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/comments` | POST | dual | `videoStreamComments` | `videoStreamComments` | `content, isHidden, nickname` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/end` | POST | dual | `videoStreamEnd` | `videoStreamEnd` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/fortune-requests` | DELETE | dual | `videoStreamFortuneRequests` | `videoStreamFortuneRequests` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/fortune-requests` | GET | dual | `videoStreamFortuneRequests` | `videoStreamFortuneRequests` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/fortune-requests` | PATCH | dual | `videoStreamFortuneRequests` | `videoStreamFortuneRequests` | `action, requestId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/fortune-requests` | POST | dual | `videoStreamFortuneRequests` | `videoStreamFortuneRequests` | `isHidden, nickname, question, typeId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/fortune-requests/my-status` | GET | dual | `videoStreamFortuneMyStatus` | `videoStreamFortuneMyStatus` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/gifts` | GET | dual | `videoStreamGifts` | `videoStreamGifts` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/gifts` | POST | dual | `videoStreamGifts` | `videoStreamGifts` | `giftTypeId, quantity` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/join` | DELETE | dual | `videoStreamJoin` | `videoStreamJoin` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/join` | POST | dual | `videoStreamJoin` | `videoStreamJoin` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/leave` | POST | dual | `videoStreamLeave` | `videoStreamLeave` | `viewerId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/like` | GET | dual | `videoStreamLike` | `videoStreamLike` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/like` | POST | dual | `videoStreamLike` | `videoStreamLike` | `count` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/live-started` | POST | dual | `videoStreamLiveStarted` | `videoStreamLiveStarted` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/messages` | GET | dual | `videoStreamMessages` | `videoStreamMessages` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/messages` | POST | dual | `videoStreamMessages` | `videoStreamMessages` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/moderators` | DELETE | dual | `videoStreamModerators` | `videoStreamModerators` | `userId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/moderators` | GET | dual | `videoStreamModerators` | `videoStreamModerators` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/moderators` | POST | dual | `videoStreamModerators` | `videoStreamModerators` | `userId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/mute` | DELETE | dual | `videoStreamMute` | `videoStreamMute` | `viewerId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/mute` | GET | dual | `videoStreamMute` | `videoStreamMute` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/mute` | POST | dual | `videoStreamMute` | `videoStreamMute` | `expiresAt, reason, viewerId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/pk-battle` | GET | dual | `videoStreamPkBattle` | `videoStreamPkBattle` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/pk-battle` | POST | dual | `videoStreamPkBattle` | `videoStreamPkBattle` | `action, battleId, duration, targetStreamId` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/signal` | DELETE | dual | `videoStreamSignal` | `videoStreamSignal` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/signal` | GET | dual | `videoStreamSignal` | `videoStreamSignal` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/signal` | POST | dual | `videoStreamSignal` | `videoStreamSignal` | `data, receiverId, type` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/stream` | GET | dual | `videoStreamSse` | `videoStreamSse` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/video-streams/{streamId}/viewers` | GET | public | `videoStreamViewers` | `videoStreamViewers` | `-` | OpenAPI/docs | YES | CONNECTED |
| `/api/wallet` | GET | dual | `wallet` | `wallet` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/warmup` | GET | public | `apiHealth` | `apiHealth` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/weekly-dream-report` | GET | dual | `weeklyDreamReport` | `weeklyDreamReport` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/weekly-dream-report` | POST | dual | `weeklyDreamReport` | `weeklyDreamReport` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/withdrawals` | GET | dual | `withdrawals` | `withdrawals` | `-` | OpenAPI/docs | NO | CONNECTED |
| `/api/withdrawals` | POST | dual | `withdrawals` | `withdrawals` | `accountDetails, amount, method` | OpenAPI/docs | NO | CONNECTED |
| `/api/youtube/search` | GET | dual | `youtubeSearch` | `youtubeSearch` | `-` | OpenAPI/docs | NO | CONNECTED |

## Flutter-only normalized paths (not found in backend index)
| Flutter Path | ApiEndpoints symbols | Status |
|---|---|---|
| `/api/admin/payment-notifications` | `adminPaymentNotifications` | WRONG |
| `/api/admin/payment-requests` | `adminPaymentRequests` | WRONG |
| `/api/admin/payment-requests/dismiss-pending` | `adminDismissPendingPayments` | WRONG |
| `/api/admin/payments/stream` | `adminPaymentsStream` | WRONG |
| `/api/admin/users/credits` | `adminUsersCredits` | WRONG |
| `/api/admin/users/grant-membership` | `adminUsersGrantMembership` | WRONG |
| `/api/admin/users/stats` | `adminUsersStats` | WRONG |
| `/api/admin/voice-room-backgrounds` | `adminVoiceRoomBackgrounds` | WRONG |
| `/api/admin/voice-room-finance-audit` | `adminVoiceRoomFinanceAudit` | WRONG |
| `/api/admin/voice-room-settings` | `adminVoiceRoomSettings` | WRONG |
| `/api/advisors/online` | `homeAdvisorsOnline` | WRONG |
| `/api/auth/google` | `authGoogle` | WRONG |
| `/api/auth/login` | `authLogin` | DEPRECATED |
| `/api/auth/me` | `authMe` | WRONG |
| `/api/auth/mobile-send-verification` | `authMobileSendVerification` | WRONG |
| `/api/auth/mobile-sessions` | `authMobileSessions` | WRONG |
| `/api/auth/mobile-sessions/{param}` | `authMobileSessionRevoke` | WRONG |
| `/api/auth/mobile-verify-email` | `authMobileVerifyEmail` | WRONG |
| `/api/auth/mobile/device-token` | `authMobileDeviceToken` | WRONG |
| `/api/auth/refresh` | `authRefresh` | DEPRECATED |
| `/api/auth/register` | `authRegister` | DEPRECATED |
| `/api/auth/tiktok` | `authTiktok` | WRONG |
| `/api/banners` | `homeBanners` | WRONG |
| `/api/blog/recent` | `blogRecent` | WRONG |
| `/api/blog/{param}` | `blogPost` | WRONG |
| `/api/celebrities` | `celebrities` | WRONG |
| `/api/celebrities/{param}` | `celebrity` | WRONG |
| `/api/celebrities/{param}/follow` | `celebrityFollow` | WRONG |
| `/api/celebrities/{param}/posts` | `celebrityPosts` | WRONG |
| `/api/chat/music/popular` | `chatMusicPopular` | WRONG |
| `/api/chat/rooms/{param}` | `chatRoomDetail` | WRONG |
| `/api/chat/rooms/{param}/background` | `chatRoomBackground` | WRONG |
| `/api/chat/rooms/{param}/banned-words` | `chatRoomBannedWords` | WRONG |
| `/api/chat/rooms/{param}/bans/{param}` | `chatRoomBan` | WRONG |
| `/api/chat/rooms/{param}/current-song` | `chatRoomCurrentSong` | WRONG |
| `/api/chat/rooms/{param}/dj/{param}` | `chatRoomDjUser` | WRONG |
| `/api/chat/rooms/{param}/join-seat` | `chatRoomJoinSeat` | WRONG |
| `/api/chat/rooms/{param}/kick` | `chatRoomKick` | WRONG |
| `/api/chat/rooms/{param}/mentions` | `chatRoomMentions` | WRONG |
| `/api/chat/rooms/{param}/messages/{param}` | `chatRoomMessage` | WRONG |
| `/api/chat/rooms/{param}/music-request-by-query` | `chatRoomMusicRequestByQuery` | WRONG |
| `/api/chat/rooms/{param}/music-settings` | `chatRoomMusicSettings` | WRONG |
| `/api/chat/rooms/{param}/music-stream` | `chatRoomMusicStream` | WRONG |
| `/api/chat/rooms/{param}/mute` | `chatRoomMute` | WRONG |
| `/api/chat/rooms/{param}/pk/{param}/end` | `chatRoomPkEnd` | WRONG |
| `/api/chat/rooms/{param}/pk/{param}/respond` | `chatRoomPkRespond` | WRONG |
| `/api/chat/rooms/{param}/queue` | `chatRoomSongQueue, chatRoomSongQueueClear` | WRONG |
| `/api/chat/rooms/{param}/roles` | `chatRoomRoles` | WRONG |
| `/api/chat/rooms/{param}/song/{param}` | `chatRoomSongRemove` | WRONG |
| `/api/chat/rooms/{param}/speak-request` | `chatRoomSpeakRequest` | WRONG |
| `/api/chat/rooms/{param}/speak-requests` | `chatRoomSpeakRequests` | WRONG |
| `/api/chat/rooms/{param}/speak-requests/{param}/approve` | `chatRoomSpeakRequestApprove` | WRONG |
| `/api/daily-rewards` | `homeDailyRewards` | WRONG |
| `/api/fan-clubs` | `fanClubs` | WRONG |
| `/api/fan-clubs/popular` | `fanClubsPopular` | WRONG |
| `/api/fan-clubs/{param}/join` | `fanClubJoin` | WRONG |
| `/api/fan-clubs/{param}/polls` | `fanClubPolls` | WRONG |
| `/api/fan-clubs/{param}/posts` | `fanClubPosts` | WRONG |
| `/api/fortune-access/consume` | `fortuneAccessConsume` | WRONG |
| `/api/fortune-access/settings` | `fortuneAccessSettings` | WRONG |
| `/api/fortune-tellers/session/{param}` | `fortuneTellerSessionStatus` | WRONG |
| `/api/fortune-tellers/session/{param}/respond` | `fortuneTellerSessionRespond` | WRONG |
| `/api/fortune-tellers/sessions/incoming` | `fortuneTellerIncomingSessions` | WRONG |
| `/api/fortunes/{param}` | `fortuneReading` | WRONG |
| `/api/games/auto-match` | `gameAutoMatch` | WRONG |
| `/api/games/history` | `gameHistory` | WRONG |
| `/api/games/mini-scores` | `gameMiniScores` | WRONG |
| `/api/games/quests/{param}` | `gamesQuestComplete` | WRONG |
| `/api/games/room/{param}/join` | `gameRoomJoinLegacy` | WRONG |
| `/api/games/rooms` | `gameRooms` | WRONG |
| `/api/games/sos/create` | `gameSosCreate` | WRONG |
| `/api/gifts/battles` | `giftsBattles` | WRONG |
| `/api/gifts/battles/{param}` | `giftsBattle` | WRONG |
| `/api/gifts/goals` | `giftsGoals` | WRONG |
| `/api/gifts/insights/album/{param}` | `giftsInsightsAlbum` | WRONG |
| `/api/gifts/insights/badge/{param}` | `giftsInsightsBadge` | WRONG |
| `/api/gifts/insights/collection/{param}` | `giftsInsightsCollection` | WRONG |
| `/api/gifts/insights/feed` | `giftsInsightsFeed` | WRONG |
| `/api/gifts/insights/first-gifter/{param}/{param}` | `giftsInsightsFirstGifter` | WRONG |
| `/api/gifts/insights/leaderboard` | `giftsInsightsLeaderboard` | WRONG |
| `/api/gifts/insights/map` | `giftsInsightsMap` | WRONG |
| `/api/gifts/insights/me/badge` | `giftsInsightsMeBadge` | WRONG |
| `/api/gifts/insights/me/history` | `giftsInsightsMeHistory` | WRONG |
| `/api/gifts/insights/me/recommendations` | `giftsInsightsMeRecommendations` | WRONG |
| `/api/gifts/missions` | `giftsMissions` | WRONG |
| `/api/gifts/missions/me` | `giftsMissionsMe` | WRONG |
| `/api/gifts/missions/{param}/claim` | `giftsMissionClaim` | WRONG |
| `/api/leaderboard` | `leaderboard` | WRONG |
| `/api/live` | `liveStreams` | WRONG |
| `/api/live-fal/pending` | `liveFalPending` | WRONG |
| `/api/live-fal/request/{param}/accept` | `liveFalRequestAccept` | WRONG |
| `/api/live-fal/request/{param}/reject` | `liveFalRequestReject` | WRONG |
| `/api/live/fal-request/create` | `liveFalRequestCreate` | WRONG |
| `/api/live/fal-request/{param}/complete` | `liveFalRequestComplete` | WRONG |
| `/api/live/fal-request/{param}/update` | `liveFalRequestUpdate` | WRONG |
| `/api/live/fal-requests` | `liveFalRequests` | WRONG |
| `/api/live/guest/list` | `liveGuestList` | WRONG |
| `/api/live/pk/active` | `livePkActive` | WRONG |
| `/api/live/pk/sweep` | `livePkSweep` | WRONG |
| `/api/messages/conversations` | `messagesConversations` | WRONG |
| `/api/messages/conversations/{param}/messages` | `conversationMessages` | WRONG |
| `/api/messages/conversations/{param}/stream` | `conversationStream` | WRONG |
| `/api/messages/conversations/{param}/typing` | `conversationTyping` | WRONG |
| `/api/messages/{param}/{param}` | `messageWithId` | WRONG |
| `/api/notifications/payment` | `notificationsPaymentClear` | WRONG |
| `/api/notifications/unread` | `notificationsUnread` | WRONG |
| `/api/notifications/{param}/read` | `notificationRead` | WRONG |
| `/api/pk/active` | `pkActive` | WRONG |
| `/api/pk/admin/ban` | `pkAdminBan` | WRONG |
| `/api/pk/admin/bans` | `pkAdminBans` | WRONG |
| `/api/pk/admin/unban/{param}` | `pkAdminUnban` | WRONG |
| `/api/pk/admin/{param}/force-end` | `pkAdminForceEnd` | WRONG |
| `/api/pk/admin/{param}/force-kick/{param}` | `pkAdminForceKick` | WRONG |
| `/api/pk/battles` | `pkBattles` | WRONG |
| `/api/pk/battles/{param}` | `pkBattle` | WRONG |
| `/api/pk/battles/{param}/accept` | `pkBattleAccept` | WRONG |
| `/api/pk/battles/{param}/end` | `pkBattleEnd` | WRONG |
| `/api/pk/battles/{param}/reject` | `pkBattleReject` | WRONG |
| `/api/pk/history` | `pkHistory` | WRONG |
| `/api/pk/leaderboard` | `pkLeaderboard` | WRONG |
| `/api/pk/me/history` | `pkMeHistory` | WRONG |
| `/api/pk/me/invites` | `pkMeInvites` | WRONG |
| `/api/pk/me/matches` | `pkMeMatches` | WRONG |
| `/api/pk/me/stats` | `pkMeStats` | WRONG |
| `/api/pk/request` | `pkRequest` | WRONG |
| `/api/pk/room` | `pkRoom` | WRONG |
| `/api/pk/stats/{param}` | `pkStatsUser` | WRONG |
| `/api/pk/{param}` | `pkMatch` | WRONG |
| `/api/pk/{param}/cancel` | `pkMatchCancel` | WRONG |
| `/api/pk/{param}/end` | `pkMatchEnd` | WRONG |
| `/api/pk/{param}/events` | `pkMatchEvents` | WRONG |
| `/api/pk/{param}/respond` | `pkMatchRespond` | WRONG |
| `/api/pk/{param}/seats/join` | `pkMatchSeatsJoin` | WRONG |
| `/api/pk/{param}/seats/kick` | `pkMatchSeatsKick` | WRONG |
| `/api/pk/{param}/seats/leave` | `pkMatchSeatsLeave` | WRONG |
| `/api/pk/{param}/start` | `pkMatchStart` | WRONG |
| `/api/pk/{param}/stream` | `pkMatchStream` | WRONG |
| `/api/platform-stats` | `platformStats` | WRONG |
| `/api/platform/voice-room-settings` | `platformVoiceRoomSettings` | WRONG |
| `/api/reports` | `reports` | WRONG |
| `/api/short-videos/explore/nearby` | `shortVideosExploreNearby` | WRONG |
| `/api/short-videos/hashtags/search` | `shortVideosHashtagsSearch` | WRONG |
| `/api/short-videos/hashtags/trending` | `shortVideosHashtagsTrending` | WRONG |
| `/api/short-videos/hashtags/{param}` | `shortVideosHashtag` | WRONG |
| `/api/short-videos/live-clip` | `shortVideosLiveClip` | WRONG |
| `/api/short-videos/music/recommend` | `shortVideosMusicRecommend` | WRONG |
| `/api/short-videos/recommend` | `shortVideosRecommend` | WRONG |
| `/api/short-videos/suggest-metadata` | `shortVideosSuggestMetadata` | WRONG |
| `/api/short-videos/viewed/me` | `shortVideosViewedMe` | WRONG |
| `/api/short-videos/{param}/analytics` | `shortVideoAnalytics` | WRONG |
| `/api/short-videos/{param}/gifts` | `shortVideoGifts` | WRONG |
| `/api/short-videos/{param}/stream` | `shortVideoStream` | WRONG |
| `/api/short-videos/{param}/subtitles/generate` | `shortVideoSubtitlesGenerate` | WRONG |
| `/api/social/announcements` | `socialAnnouncements` | WRONG |
| `/api/social/fortune-tellers` | `socialFortuneTellers` | WRONG |
| `/api/social/posts/auto-fortune` | `socialPostsAutoFortune` | WRONG |
| `/api/social/public-stats` | `socialPublicStats` | WRONG |
| `/api/social/stories` | `socialStories` | WRONG |
| `/api/teller/gifts` | `tellerGifts` | WRONG |
| `/api/teller/reviews` | `tellerReviews` | WRONG |
| `/api/tournaments/join` | `tournamentsJoin` | WRONG |
| `/api/user/daily-tasks` | `userDailyTasks` | WRONG |
| `/api/user/device-token` | `registerUserDeviceToken` | WRONG |
| `/api/user/favorites` | `userFavorites` | WRONG |
| `/api/user/favorites/{param}` | `userFavoriteDelete` | WRONG |
| `/api/user/fortunes/{param}/pin` | `userFortunePin` | WRONG |
| `/api/user/fortunes/{param}/rate` | `userFortuneRate` | WRONG |
| `/api/user/story` | `userStory` | WRONG |
| `/api/users/me/activity` | `meActivity` | WRONG |
| `/api/users/me/broadcast-history` | `meBroadcastHistory` | WRONG |
| `/api/users/me/profile-visitors` | `meProfileVisitors` | WRONG |
| `/api/users/me/stats` | `meStats` | WRONG |
| `/api/users/{param}/followers` | `userPublicFollowers, followers` | WRONG |
| `/api/users/{param}/following` | `following` | WRONG |
| `/api/video-streams/{param}/background` | `videoStreamBackground` | WRONG |
| `/api/video-streams/{param}/fortune-requests/{param}` | `videoStreamFortuneRequest` | WRONG |
| `/api/video-streams/{param}/gifts/leaderboard` | `videoStreamGiftLeaderboard` | WRONG |
| `/api/video-streams/{param}/image` | `videoStreamImage` | WRONG |
| `/api/video-streams/{param}/moderator` | `videoStreamModerator` | BACKEND_CONFIRMED |
| `/api/video-streams/{param}/auto-close` | `videoStreamAutoClose` | BACKEND_CONFIRMED |
| `/api/room/{param}/stream` | `liveFortuneRoomStream` | BACKEND_CONFIRMED |
| `/api/room/{param}/messages` | `liveFortuneRoomMessages` | BACKEND_CONFIRMED |
| `/api/room/signal` | `liveFortuneRoomSignal` | BACKEND_CONFIRMED |
