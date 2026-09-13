# CanlıFal — Tam Endpoint Envanteri

Toplam endpoint (path+method): **953**  ·  Toplam route dosyası: **612**  ·  Grup sayısı: **116**

Kimlik doğrulama kodları: `mobile-jwt` = Bearer JWT (`Authorization: Bearer <token>`), `web-session` = tarayıcı oturum çerezi, `rbac` = rol/izin denetimi, `admin-helper` = admin yardımcı guard, `cron-secret` = zamanlanmış görev anahtarı, `public` = açık.

> Flutter istemcisi tüm çağrıları `mobile-jwt` ile yapar. `/api/v1/...` öneki middleware tarafından `/api/...` adresine yönlendirilir.
> Sınıf sütunu: `FLUTTER_READY` / `PUBLIC` = mobil kullanabilir, `ADMIN_ONLY` = yalnız yönetim paneli.

## /[...unmatched]  (7 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| DELETE | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |
| GET | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |
| HEAD | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |
| OPTIONS | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |
| PATCH | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |
| POST | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |
| PUT | `/api/[...unmatched]` | public | PUBLIC |  |  | — | — |

## /activities  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/activities` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /admin  (335 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/admin/activity-feed` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/activity-feed` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | isEnabled, maxItems, specificUserIds, visibleToAdmin, visibleToBasic, visibleToDiamond, visibleToGold, visibleToGuests, visibleToModerator, visibleToPremium |
| DELETE | `/api/admin/ad-networks` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | adCode, adUnitId, appId, id, isActive, name, provider, sortOrder |
| GET | `/api/admin/ad-networks` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/ad-networks` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | adCode, adUnitId, appId, id, isActive, name, provider, sortOrder |
| GET | `/api/admin/ad-placements` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/ad-placements` | admin-helper | ADMIN_ONLY | ✔ |  | — | action, adNetworkId, customCode, description, frequencyCap, position, sortOrder |
| DELETE | `/api/admin/ad-placements/[id]` | admin-helper | ADMIN_ONLY | ✔ |  | — | adNetworkId, adType, customCode, description, frequencyCap, isActive, name, platform, position, resetStats, sortOrder, targeting |
| GET | `/api/admin/ad-placements/[id]` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/ad-placements/[id]` | admin-helper | ADMIN_ONLY | ✔ |  | — | adNetworkId, adType, customCode, description, frequencyCap, isActive, name, platform, position, resetStats, sortOrder, targeting |
| GET | `/api/admin/ad-placements/stats` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/agencies` | rbac | ADMIN_ONLY | ✔ |  | — | action, agencyId, commissionRate, contactEmail, contactPhone, description, fromAgencyId, logoUrl, name, newOwnerId, ownerId, ownerName, role, toAgencyId, userId |
| GET | `/api/admin/agencies` | rbac | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/agencies` | rbac | ADMIN_ONLY | ✔ |  | — | action, agencyId, commissionRate, contactEmail, contactPhone, description, fromAgencyId, logoUrl, name, newOwnerId, ownerId, ownerName, role, toAgencyId, userId |
| POST | `/api/admin/agencies` | rbac | ADMIN_ONLY | ✔ |  | — | action, agencyId, commissionRate, contactEmail, contactPhone, description, fromAgencyId, logoUrl, name, newOwnerId, ownerId, ownerName, role, toAgencyId, userId |
| GET | `/api/admin/agencies/[agencyId]/commission` | public | ADMIN_ONLY | ✔ |  | — | — |
| PUT | `/api/admin/agencies/[agencyId]/commission` | public | ADMIN_ONLY | ✔ |  | — | baseCommissionRate, rules |
| GET | `/api/admin/agencies/[agencyId]/wallet` | public | ADMIN_ONLY | ✔ |  | limit, page, type | — |
| POST | `/api/admin/agencies/[agencyId]/wallet` | public | ADMIN_ONLY | ✔ |  | limit, page, type | action, amount, confirm, idempotencyKey, jetonAmount, level, reason, tlAmount |
| GET | `/api/admin/agency-applicant-config` | public | ADMIN_ONLY | ✔ |  | — | — |
| PUT | `/api/admin/agency-applicant-config` | public | ADMIN_ONLY | ✔ |  | — | weights |
| GET | `/api/admin/agency-finance` | public | ADMIN_ONLY | ✔ |  | — | — |
| PUT | `/api/admin/agency-finance` | public | ADMIN_ONLY | ✔ |  | — | bonus_rules, global_commission_rules, settings |
| GET | `/api/admin/animations` | admin-helper | ADMIN_ONLY | ✔ |  | category, limit, membership, offset, q, status | — |
| POST | `/api/admin/animations` | admin-helper | ADMIN_ONLY | ✔ |  | category, limit, membership, offset, q, status | name, slug |
| DELETE | `/api/admin/animations/[id]` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/animations/[id]` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/animations/[id]` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/animations/assignments` | admin-helper | ADMIN_ONLY | ✔ |  | animationId, category, id, onlyActive, userId | assignmentType, context, duration, endDate, isActive, note, priority, startDate |
| GET | `/api/admin/animations/assignments` | admin-helper | ADMIN_ONLY | ✔ |  | animationId, category, id, onlyActive, userId | — |
| PATCH | `/api/admin/animations/assignments` | admin-helper | ADMIN_ONLY | ✔ |  | animationId, category, id, onlyActive, userId | assignmentType, context, duration, endDate, isActive, note, priority, startDate |
| POST | `/api/admin/animations/assignments` | admin-helper | ADMIN_ONLY | ✔ |  | animationId, category, id, onlyActive, userId | assignmentType, context, duration, endDate, isActive, note, priority, startDate |
| DELETE | `/api/admin/animations/membership-defaults` | admin-helper | ADMIN_ONLY | ✔ |  | id | isActive |
| GET | `/api/admin/animations/membership-defaults` | admin-helper | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/animations/membership-defaults` | admin-helper | ADMIN_ONLY | ✔ |  | id | isActive |
| GET | `/api/admin/animations/stats` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/announcement-sections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/announcement-sections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | categoryConfig, categoryKey, categorySettings, giftAnnouncementSettings |
| GET | `/api/admin/audit-logs` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | action, actorId, cursor, limit, targetType | — |
| GET | `/api/admin/avatar-accessories` | public | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/awards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | awardType, endDate, startDate, tellerId, title |
| GET | `/api/admin/awards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/awards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | awardType, endDate, startDate, tellerId, title |
| GET | `/api/admin/backup` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | table, type | — |
| DELETE | `/api/admin/badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId |
| GET | `/api/admin/badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId |
| PUT | `/api/admin/badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bgColor, color, description, icon, id, isActive, name, sortOrder, tier, userId |
| GET | `/api/admin/bana-ozel` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/bana-ozel` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | category, icon, id, jetonCost, nameEn, nameTr, slug, sortOrder |
| POST | `/api/admin/bana-ozel` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | category, icon, id, jetonCost, nameEn, nameTr, slug, sortOrder |
| GET | `/api/admin/blog` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/blog` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign |
| DELETE | `/api/admin/blog/[postId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign |
| PATCH | `/api/admin/blog/[postId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign |
| PUT | `/api/admin/blog/[postId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | authorName, category, contentEn, contentTr, coverImage, descEn, descTr, isAiGenerated, isEditorPick, isFeatured, isPremium, isPublished, isTrending, keywords, metaDescription, publishedAt, readTime, scheduledAt, slug, titleEn, titleTr, zodiacSign |
| GET | `/api/admin/blog/analytics` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/blog/bulk-category` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | category, postIds |
| POST | `/api/admin/blog/bulk-delete` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | postIds |
| POST | `/api/admin/blog/bulk-generate` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | autoPublish, category, topics, zodiacSign |
| POST | `/api/admin/blog/bulk-import` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/blog/bulk-publish` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | isPublished, postIds |
| DELETE | `/api/admin/blog/categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | nameEn, nameTr, slug |
| GET | `/api/admin/blog/categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/blog/categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | nameEn, nameTr, slug |
| GET | `/api/admin/blog/comments` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, page, status | — |
| PATCH | `/api/admin/blog/comments` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, page, status | action, commentId |
| POST | `/api/admin/blog/generate` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | keywords, mode, title |
| POST | `/api/admin/blog/import` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/blog/schedule-publish` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/bots` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | active, personality, search | — |
| PATCH | `/api/admin/bots` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | active, personality, search | action, activityLevel, botIds, isActive, personality |
| GET | `/api/admin/bots/simulate` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/bots/simulate` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | action, roomId |
| GET | `/api/admin/bots/simulate-fortune` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/bots/simulate-fortune` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/bots/simulate-master` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/bots/simulate-master` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/bots/simulate-social` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/bots/simulate-social` | admin-helper/cron-secret/web-session | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/broadcast-images` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder |
| GET | `/api/admin/broadcast-images` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/broadcast-images` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder |
| POST | `/api/admin/broadcast-images` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder |
| GET | `/api/admin/button-order` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/button-order` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | order |
| DELETE | `/api/admin/cache` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | key, prefix | — |
| GET | `/api/admin/cache` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | key, prefix | — |
| GET | `/api/admin/cfc-arena` | public | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/cfc-arena` | public | ADMIN_ONLY | ✔ |  | — | action, agencyId, badgeEmoji, bannerImage, captainId, color, commissionRate, contestId, description, displayName, endsAt, entryRequirements, isActive, isFeatured, isPublic, maxParticipants, minParticipants, name, participantId, registrationEndsAt, rewards, roomId, rules, scope, scoringMetrics, seasonId, startsAt, teamId, type, userId |
| GET | `/api/admin/cfc-arena/[contestId]` | public | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/cfc-payment-requests` | rbac | ADMIN_ONLY | ✔ |  | limit, page, status | — |
| PATCH | `/api/admin/cfc-payment-requests` | rbac | ADMIN_ONLY | ✔ |  | limit, page, status | action, requestId, reviewNote |
| GET | `/api/admin/cfc-settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/cfc-settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/chat-bubbles` | public | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/chat-rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | roomId | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId, roomId, roomType |
| GET | `/api/admin/chat-rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | roomId | — |
| POST | `/api/admin/chat-rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | roomId | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId, roomId, roomType |
| PUT | `/api/admin/chat-rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | roomId | backgroundImage, descEn, descTr, description, giftCommissionPercent, icon, isActive, isMuted, name, nameEn, nameTr, ownerId, roomId, roomType |
| DELETE | `/api/admin/contests` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, dreamPrompt, endDate, id, isActive, startDate, title |
| GET | `/api/admin/contests` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/contests` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, dreamPrompt, endDate, id, isActive, startDate, title |
| POST | `/api/admin/contests` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, dreamPrompt, endDate, id, isActive, startDate, title |
| GET | `/api/admin/credit-packages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/credit-packages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bonusCredits, credits, currency, isFeatured, name, nameEn, price, sortOrder |
| DELETE | `/api/admin/credit-packages/[packageId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bonusCredits, credits, currency, isActive, isFeatured, name, nameEn, price, sortOrder |
| PATCH | `/api/admin/credit-packages/[packageId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bonusCredits, credits, currency, isActive, isFeatured, name, nameEn, price, sortOrder |
| POST | `/api/admin/credits` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | amount, currency, userId |
| GET | `/api/admin/currency-config` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/currency-config` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | area, areaName, configs, cost, currencyType, id, isActive |
| PUT | `/api/admin/currency-config` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | area, areaName, configs, cost, currencyType, id, isActive |
| GET | `/api/admin/currency-settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/currency-settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/dreams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id, limit, page, publish, search | category, content, id, isPublished, keywords, metaDescription, summary, title |
| GET | `/api/admin/dreams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id, limit, page, publish, search | — |
| POST | `/api/admin/dreams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id, limit, page, publish, search | category, content, id, isPublished, keywords, metaDescription, summary, title |
| PUT | `/api/admin/dreams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id, limit, page, publish, search | category, content, id, isPublished, keywords, metaDescription, summary, title |
| PATCH | `/api/admin/dreams/bulk-category` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | category, dreamIds |
| POST | `/api/admin/dreams/bulk-delete` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | dreamIds |
| POST | `/api/admin/dreams/bulk-import` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/dreams/bulk-publish` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | dreamIds, isPublished |
| POST | `/api/admin/dreams/generate` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | title |
| GET | `/api/admin/effect-rules` | rbac | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/effect-rules` | rbac | ADMIN_ONLY | ✔ |  | — | conditionType, conditionValue, description, effectRefId, effectType, isActive, key, name, priority, threshold |
| DELETE | `/api/admin/effect-rules/[ruleId]` | rbac | ADMIN_ONLY | ✔ |  | — | conditionType, conditionValue, description, effectRefId, effectType, isActive, name, priority, threshold |
| PATCH | `/api/admin/effect-rules/[ruleId]` | rbac | ADMIN_ONLY | ✔ |  | — | conditionType, conditionValue, description, effectRefId, effectType, isActive, name, priority, threshold |
| GET | `/api/admin/emoji-packs` | public | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/entrance-effects` | public | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/feature-flags` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/feature-flags` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, enabled, key, metadata, percentage, platform |
| DELETE | `/api/admin/feature-flags/[flagId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, enabled, metadata, percentage, platform |
| PATCH | `/api/admin/feature-flags/[flagId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, enabled, metadata, percentage, platform |
| GET | `/api/admin/finance` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | from, page, period, section, to, userId | — |
| POST | `/api/admin/finance` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | from, page, period, section, to, userId | action, amount, currency, key, reason, userId, value |
| DELETE | `/api/admin/fortune-request-types` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| GET | `/api/admin/fortune-request-types` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/fortune-request-types` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| POST | `/api/admin/fortune-request-types` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, icon, id, isActive, jetonCost, name, nameEn, sortOrder |
| GET | `/api/admin/fortunes` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | type, userId | — |
| DELETE | `/api/admin/games` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | config, description, entryFee, icon, id, isActive, maxReward, minReward, slug, sortOrder, title |
| GET | `/api/admin/games` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/games` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | config, description, entryFee, icon, id, isActive, maxReward, minReward, slug, sortOrder, title |
| PUT | `/api/admin/games` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | config, description, entryFee, icon, id, isActive, maxReward, minReward, slug, sortOrder, title |
| DELETE | `/api/admin/games/rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | gameType, limit, page, status | roomId |
| GET | `/api/admin/games/rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | gameType, limit, page, status | — |
| GET | `/api/admin/games/settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PUT | `/api/admin/games/settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/gift-collections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/gift-collections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, iconCloudPath, iconEmoji, iconUrl, id, isActive, name, nameEn, slug, sortOrder |
| POST | `/api/admin/gift-collections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, iconCloudPath, iconEmoji, iconUrl, id, isActive, name, nameEn, slug, sortOrder |
| POST | `/api/admin/gift-upload` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | contentType, fileName, purpose |
| GET | `/api/admin/gifts` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, collectionId, displayType, isActive, limit, maxPrice, minPrice, page, search, sortBy, sortDir | — |
| POST | `/api/admin/gifts` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, collectionId, displayType, isActive, limit, maxPrice, minPrice, page, search, sortBy, sortDir | animEndPoint, animStartPoint, animation, animationDurationMs, animationType, assetDurationMs, assetHeight, assetMimeType, assetType, assetUrl, assetWidth, campaignEnd, campaignStart, category, cloudStoragePath, collectionId, comboEnabled, comboWindowMs, dailySendLimit, description, displayArea, displayDurationMs, displayType, effectColor, eventOnly, hasColorChange, hasVibration, icon, iconImageCloudPath, iconImageUrl, isActive, isFeatured, isFullscreen, isHidden, isLucky, isNew, isPopular, isPremium, isReusable, isSeasonal, isSpecialEvent, liveOnly, musicCloudPath, musicUrl, name, nameEn, newUserOnly, particleEffect, pkOnly, price, priority, repeatCount, requiresVip, screenPosition, seasonEnd, seasonStart, seatEffect, seatEffectEnabled, sortOrder, soundCloudPath, soundEffectEnabled, soundUrl, startDelayMs, thumbnailCloudPath, thumbnailUrl, tier, timedCampaign, visibleAsFullscreen, visibleAsMini, visibleInFortune, visibleInLiveStream, visibleInMessaging, visibleInNotification, visibleInPK, visibleInProfile, visibleInStories, visibleInTrend, visibleInVoiceRoom, voiceOnly, volume |
| DELETE | `/api/admin/gifts/[giftId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | animationType, assetMimeType, assetType, assetUrl, cloudStoragePath, collectionId, iconImageCloudPath, iconImageUrl, musicCloudPath, musicUrl, soundCloudPath, soundUrl, thumbnailCloudPath, thumbnailUrl |
| GET | `/api/admin/gifts/[giftId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/gifts/[giftId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | animationType, assetMimeType, assetType, assetUrl, cloudStoragePath, collectionId, iconImageCloudPath, iconImageUrl, musicCloudPath, musicUrl, soundCloudPath, soundUrl, thumbnailCloudPath, thumbnailUrl |
| GET | `/api/admin/gifts/stats` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | giftId | — |
| GET | `/api/admin/global-search` | public | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/homepage-buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior |
| GET | `/api/admin/homepage-buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/homepage-buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior |
| POST | `/api/admin/homepage-buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, isVisible, label, reorder, sortOrder, specialBehavior |
| DELETE | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value |
| GET | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value |
| POST | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value |
| PUT | `/api/admin/homepage-fortune-cards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | href, icon, id, image, isActive, key, name, settings, sortOrder, value |
| DELETE | `/api/admin/integrations/apple` | public | ADMIN_ONLY | ✔ |  | confirm | — |
| GET | `/api/admin/integrations/apple` | public | ADMIN_ONLY | ✔ |  | confirm | — |
| PUT | `/api/admin/integrations/apple` | public | ADMIN_ONLY | ✔ |  | confirm | — |
| DELETE | `/api/admin/integrations/google-play` | public | ADMIN_ONLY | ✔ |  | confirm, field | — |
| GET | `/api/admin/integrations/google-play` | public | ADMIN_ONLY | ✔ |  | confirm, field | — |
| PUT | `/api/admin/integrations/google-play` | public | ADMIN_ONLY | ✔ |  | confirm, field | — |
| GET | `/api/admin/integrations/sms` | public | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/integrations/sms` | public | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/integrations/sms/[providerKey]` | public | ADMIN_ONLY | ✔ |  | confirm, field | enabled, fields, priority |
| PATCH | `/api/admin/integrations/sms/[providerKey]` | public | ADMIN_ONLY | ✔ |  | confirm, field | enabled, fields, priority |
| PUT | `/api/admin/integrations/sms/[providerKey]` | public | ADMIN_ONLY | ✔ |  | confirm, field | enabled, fields, priority |
| POST | `/api/admin/integrations/sms/[providerKey]/test` | public | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/leaderboards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, page, periodId, periodType, scope, status, view | — |
| POST | `/api/admin/leaderboards` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, page, periodId, periodType, scope, status, view | action, configId, confirm, isEnabled, periodId, periodType, rewardConfig, scope, scoringRules, topN |
| GET | `/api/admin/ledger` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | accountId, category, cursor, limit, transactionId | — |
| GET | `/api/admin/live-tellers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | banned, frozen, status | — |
| POST | `/api/admin/live-tellers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | banned, frozen, status | bio, displayName, isVerified, pricePerSession, specialties, userId |
| DELETE | `/api/admin/live-tellers/[tellerId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bio, displayName, isActive, isVerified, pricePerSession, specialties |
| GET | `/api/admin/live-tellers/[tellerId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PUT | `/api/admin/live-tellers/[tellerId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bio, displayName, isActive, isVerified, pricePerSession, specialties |
| POST | `/api/admin/live-tellers/[tellerId]/approve` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, note |
| POST | `/api/admin/live-tellers/[tellerId]/ban` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, reason |
| POST | `/api/admin/live-tellers/[tellerId]/bonus` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | amount, reason |
| POST | `/api/admin/live-tellers/[tellerId]/freeze` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, reason |
| PUT | `/api/admin/live-tellers/[tellerId]/permissions` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | adminNotes, canChat, canEditProfile, canGoOnline, canSetPrice, canStartSession, canViewEarnings, canWithdraw, commissionRate, maxSessionsPerDay |
| DELETE | `/api/admin/live-tellers/[tellerId]/warning` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | warningId | reason |
| POST | `/api/admin/live-tellers/[tellerId]/warning` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | warningId | reason |
| DELETE | `/api/admin/lucky-gifts/tiers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | color, icon, id, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight |
| GET | `/api/admin/lucky-gifts/tiers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/lucky-gifts/tiers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | color, icon, id, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight |
| POST | `/api/admin/lucky-gifts/tiers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | color, icon, id, isActive, isJackpot, multiplier, name, nameEn, sortOrder, weight |
| DELETE | `/api/admin/membership-badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder, tier |
| GET | `/api/admin/membership-badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/membership-badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder, tier |
| POST | `/api/admin/membership-badges` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder, tier |
| DELETE | `/api/admin/membership-events` | admin-helper | ADMIN_ONLY | ✔ |  | confirm, id | allowedTiers, bannerUrl, ctaUrl, description, endsAt, isActive, minTierKey, priority, startsAt, title |
| GET | `/api/admin/membership-events` | admin-helper | ADMIN_ONLY | ✔ |  | confirm, id | — |
| POST | `/api/admin/membership-events` | admin-helper | ADMIN_ONLY | ✔ |  | confirm, id | allowedTiers, bannerUrl, ctaUrl, description, endsAt, isActive, minTierKey, priority, startsAt, title |
| PUT | `/api/admin/membership-events` | admin-helper | ADMIN_ONLY | ✔ |  | confirm, id | allowedTiers, bannerUrl, ctaUrl, description, endsAt, isActive, minTierKey, priority, startsAt, title |
| DELETE | `/api/admin/membership-features` | public | ADMIN_ONLY | ✔ |  | confirm, featureKey, tierKey | cells, description, feature, sortOrder, unit, valueType |
| GET | `/api/admin/membership-features` | public | ADMIN_ONLY | ✔ |  | confirm, featureKey, tierKey | — |
| POST | `/api/admin/membership-features` | public | ADMIN_ONLY | ✔ |  | confirm, featureKey, tierKey | cells, description, feature, sortOrder, unit, valueType |
| PUT | `/api/admin/membership-features` | public | ADMIN_ONLY | ✔ |  | confirm, featureKey, tierKey | cells, description, feature, sortOrder, unit, valueType |
| DELETE | `/api/admin/membership-grants` | admin-helper/rbac | ADMIN_ONLY | ✔ |  | confirm, limit, source, status, tierKey, userId | durationDays, giverId, note, source, transactionId |
| GET | `/api/admin/membership-grants` | admin-helper/rbac | ADMIN_ONLY | ✔ |  | confirm, limit, source, status, tierKey, userId | — |
| POST | `/api/admin/membership-grants` | admin-helper/rbac | ADMIN_ONLY | ✔ |  | confirm, limit, source, status, tierKey, userId | durationDays, giverId, note, source, transactionId |
| GET | `/api/admin/membership-reports` | admin-helper | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/membership-tiers` | public | ADMIN_ONLY | ✔ |  | confirm, key | badgeUrl, color, description, discoveryWeight, frameUrl, gradient, icon, isActive, name, nameEn, rank, sortOrder |
| GET | `/api/admin/membership-tiers` | public | ADMIN_ONLY | ✔ |  | confirm, key | — |
| POST | `/api/admin/membership-tiers` | public | ADMIN_ONLY | ✔ |  | confirm, key | badgeUrl, color, description, discoveryWeight, frameUrl, gradient, icon, isActive, name, nameEn, rank, sortOrder |
| PUT | `/api/admin/membership-tiers` | public | ADMIN_ONLY | ✔ |  | confirm, key | badgeUrl, color, description, discoveryWeight, frameUrl, gradient, icon, isActive, name, nameEn, rank, sortOrder |
| DELETE | `/api/admin/memberships` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bonusJetons, currency, description, descriptionEn, discountPercent, durationDays, exclusiveBadge, features, id, isActive, isFeatured, name, nameEn, price, priceType, prioritySupport, sortOrder, tier |
| GET | `/api/admin/memberships` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/memberships` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bonusJetons, currency, description, descriptionEn, discountPercent, durationDays, exclusiveBadge, features, id, isActive, isFeatured, name, nameEn, price, priceType, prioritySupport, sortOrder, tier |
| PUT | `/api/admin/memberships` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bonusJetons, currency, description, descriptionEn, discountPercent, durationDays, exclusiveBadge, features, id, isActive, isFeatured, name, nameEn, price, priceType, prioritySupport, sortOrder, tier |
| GET | `/api/admin/memberships/purchases` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, status, userId | — |
| PATCH | `/api/admin/memberships/purchases` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, status, userId | action, customTier, durationDays, extendDays, freeGrant, planId, purchaseId, userId |
| POST | `/api/admin/memberships/purchases` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, status, userId | action, customTier, durationDays, extendDays, freeGrant, planId, purchaseId, userId |
| GET | `/api/admin/mic-frames` | public | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/moderation` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/moderation` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, reason, targetId |
| GET | `/api/admin/name-effects` | public | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/notifications` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | action, id, limit, page | imageUrl, message, scheduledAt, targetType, targetValue, title, url |
| GET | `/api/admin/notifications` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | action, id, limit, page | — |
| POST | `/api/admin/notifications` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | action, id, limit, page | imageUrl, message, scheduledAt, targetType, targetValue, title, url |
| DELETE | `/api/admin/online-fal/buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor |
| GET | `/api/admin/online-fal/buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/online-fal/buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor |
| POST | `/api/admin/online-fal/buttons` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | bgColor, borderColor, href, icon, id, isVisible, label, sortOrder, textColor |
| GET | `/api/admin/online-fal/sections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/online-fal/sections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | icon, id, isVisible, order, sortOrder, title |
| POST | `/api/admin/online-fal/sections` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | icon, id, isVisible, order, sortOrder, title |
| GET | `/api/admin/payment-methods` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/payment-methods` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | config, description, descriptionEn, isActive, name, nameEn, sortOrder, type |
| GET | `/api/admin/payments` | rbac | ADMIN_ONLY | ✔ |  | id, limit, page, productType, sortBy, sortDir, status, userId, view | — |
| POST | `/api/admin/payments` | rbac | ADMIN_ONLY | ✔ |  | id, limit, page, productType, sortBy, sortDir, status, userId, view | action, adminNote, amount, confirm, correctedAmount, correctionReason, loadAmount, notificationId, productType, reason, userId |
| GET | `/api/admin/pending-counts` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/platform-analytics` | public | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/admin/popups` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | action, buttons, id, isActive, maxShowCount, message, popupType, priority, showDelaySeconds, showOnRefresh, showTo, title |
| GET | `/api/admin/popups` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/popups` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | action, buttons, id, isActive, maxShowCount, message, popupType, priority, showDelaySeconds, showOnRefresh, showTo, title |
| PUT | `/api/admin/popups` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | action, buttons, id, isActive, maxShowCount, message, popupType, priority, showDelaySeconds, showOnRefresh, showTo, title |
| GET | `/api/admin/premium-entrance` | rbac | ADMIN_ONLY | ✔ |  | enabled, limit, page, search | — |
| POST | `/api/admin/premium-entrance` | rbac | ADMIN_ONLY | ✔ |  | enabled, limit, page, search | action, animationType, durationMs, effectId, enabled, requireGold, userId |
| DELETE | `/api/admin/profile-frames` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder, tier |
| GET | `/api/admin/profile-frames` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| POST | `/api/admin/profile-frames` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | id, imageUrl, isActive, name, sortOrder, tier |
| POST | `/api/admin/profile-frames/assign` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | frameId, userId |
| GET | `/api/admin/referral-commission` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | from, limit, offset, q, to, type | — |
| GET | `/api/admin/referral-commission/settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/referral-commission/settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/refunds` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | — |
| PATCH | `/api/admin/refunds` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | adminNote |
| GET | `/api/admin/remote-config` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | group | — |
| POST | `/api/admin/remote-config` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | group | description, group, key, platform, value, valueType |
| DELETE | `/api/admin/remote-config/[configId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, group, platform, value, valueType |
| PATCH | `/api/admin/remote-config/[configId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, group, platform, value, valueType |
| GET | `/api/admin/risk-events` | rbac | ADMIN_ONLY | ✔ |  | category, level, limit, page, reviewed, userId | — |
| PATCH | `/api/admin/risk-events/[eventId]` | rbac | ADMIN_ONLY | ✔ |  | — | reviewNote, reviewed |
| GET | `/api/admin/roles` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/roles` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, key, level, name |
| DELETE | `/api/admin/roles/[roleId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, level, name, permissions |
| PATCH | `/api/admin/roles/[roleId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, level, name, permissions |
| GET | `/api/admin/room-themes` | public | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/room-themes/backgrounds` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, isActive, tier | — |
| PATCH | `/api/admin/room-themes/backgrounds` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, isActive, tier | activeFrom, activeTo, animationSpeed, assetType, backgroundUrl, blurAmount, category, cloudStoragePath, description, hasParallax, hasZoom, id, isActive, isEventOnly, isPremium, isVipOnly, name, nameEn, opacity, sortOrder, soundCloudPath, soundUrl, soundVolume, thumbnailCloudPath, thumbnailUrl, tier, videoLoop |
| POST | `/api/admin/room-themes/backgrounds` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, isActive, tier | activeFrom, activeTo, animationSpeed, assetType, backgroundUrl, blurAmount, category, cloudStoragePath, description, hasParallax, hasZoom, id, isActive, isEventOnly, isPremium, isVipOnly, name, nameEn, opacity, sortOrder, soundCloudPath, soundUrl, soundVolume, thumbnailCloudPath, thumbnailUrl, tier, videoLoop |
| GET | `/api/admin/rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/rooms` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | giftBeneficiaryId, giftCommissionPercent, roomId |
| GET | `/api/admin/rtc-telemetry` | rbac | ADMIN_ONLY | ✔ |  | context, contextId, hours, level, limit, page, platform, userId | — |
| GET | `/api/admin/seo-settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/seo-settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/settings` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | description, key, value |
| DELETE | `/api/admin/site-pages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | admin, id | content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader, slug, sortOrder, title, titleEn |
| GET | `/api/admin/site-pages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | admin, id | — |
| POST | `/api/admin/site-pages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | admin, id | content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader, slug, sortOrder, title, titleEn |
| PUT | `/api/admin/site-pages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | admin, id | content, contentEn, id, isPublished, items, reorder, showInFooter, showInHeader, slug, sortOrder, title, titleEn |
| GET | `/api/admin/statistics` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/support` | rbac | ADMIN_ONLY | ✔ |  | category, page, pageSize, status | — |
| GET | `/api/admin/system-stats` | rbac | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/teller-levels` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/teller-performance` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | level, q, sortBy, sortDir | — |
| GET | `/api/admin/teller-verification` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | — |
| POST | `/api/admin/teller-verification` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | action, note, tellerId |
| GET | `/api/admin/ticker-messages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/ticker-messages` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | icon, text |
| DELETE | `/api/admin/ticker-messages/[messageId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | icon, isActive, sortOrder, text |
| PATCH | `/api/admin/ticker-messages/[messageId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | icon, isActive, sortOrder, text |
| DELETE | `/api/admin/tiktok-categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, id, isActive, sortOrder, title |
| GET | `/api/admin/tiktok-categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | — |
| PATCH | `/api/admin/tiktok-categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, id, isActive, sortOrder, title |
| POST | `/api/admin/tiktok-categories` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | id | description, id, isActive, sortOrder, title |
| DELETE | `/api/admin/tiktok-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title |
| GET | `/api/admin/tiktok-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | categoryId, id, search | — |
| PATCH | `/api/admin/tiktok-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title |
| POST | `/api/admin/tiktok-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title |
| PUT | `/api/admin/tiktok-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | categoryId, id, search | categoryId, id, isActive, sortOrder, tiktokUrl, tiktokUrls, title |
| GET | `/api/admin/topup-bonus-tiers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/topup-bonus-tiers` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | currency, label, sourceType |
| DELETE | `/api/admin/topup-bonus-tiers/[id]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bonusPercent, currency, isActive, label, maxBonus, minAmount, sortOrder, sourceType |
| PATCH | `/api/admin/topup-bonus-tiers/[id]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | bonusPercent, currency, isActive, label, maxBonus, minAmount, sortOrder, sourceType |
| GET | `/api/admin/tournaments` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, limit, page, status | — |
| POST | `/api/admin/tournaments` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, limit, page, status | action, category, confirm, coverImage, description, eliminationType, endDate, endedAt, id, matchId, maxParticipants, minParticipants, name, newStatus, notes, pkBattleId, registrationEnd, registrationStart, rewards, roundCount, roundId, scoringType, side1Id, side1Name, side1Score, side2Id, side2Name, side2Score, stage, startDate, startedAt, status, title, type, visibility, weekEnd, weekStart, winnerId |
| GET | `/api/admin/trend-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/trend-videos` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, categoryId, channelName, description, duration, id, isActive, sortOrder, thumbnailUrl, title, videos, youtubeId |
| POST | `/api/admin/trend-videos/youtube` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, maxResults, query, urls |
| DELETE | `/api/admin/trends` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id | id |
| GET | `/api/admin/trends` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id | — |
| POST | `/api/admin/trends` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | category, id | id |
| GET | `/api/admin/users` | admin-helper/mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | adv, limit, membership, page, role, search, segment, sortBy, sortDir | — |
| DELETE | `/api/admin/users/[userId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, amount, banReason, credits, email, image, membership, membershipExpiresAt, name, newPassword, phone, profileEffect, role, specialBadges, streamBanReason, username |
| GET | `/api/admin/users/[userId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/admin/users/[userId]` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | action, amount, banReason, credits, email, image, membership, membershipExpiresAt, name, newPassword, phone, profileEffect, role, specialBadges, streamBanReason, username |
| GET | `/api/admin/users/[userId]/360` | public | ADMIN_ONLY | ✔ |  | limit, page, range, section | — |
| GET | `/api/admin/users/[userId]/manage` | rbac | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/admin/users/[userId]/manage` | rbac | ADMIN_ONLY | ✔ |  | — | action, granted, permissionKey |
| GET | `/api/admin/users/search` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | limit, q | — |
| POST | `/api/admin/users/withdrawal-limit` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | limit, userId |
| GET | `/api/admin/verification` | rbac | ADMIN_ONLY | ✔ |  | page, pageSize, status, type | — |
| PATCH | `/api/admin/verification` | rbac | ADMIN_ONLY | ✔ |  | page, pageSize, status, type | action, id, reviewNote |
| DELETE | `/api/admin/video-streams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | action, streamId |
| GET | `/api/admin/video-streams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | — |
| PATCH | `/api/admin/video-streams` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | action, streamId |
| GET | `/api/admin/visitor-stats` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | — | — |
| GET | `/api/admin/withdrawals` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | — |
| POST | `/api/admin/withdrawals` | admin-helper/web-session | ADMIN_ONLY | ✔ |  | status | action, adminNote, requestId |

## /ads  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/ads/active` | public | PUBLIC |  |  | — | — |
| GET | `/api/ads/placement` | mobile-jwt/web-session | FLUTTER_READY |  |  | key, platform | — |
| POST | `/api/ads/placement` | mobile-jwt/web-session | FLUTTER_READY |  |  | key, platform | — |
| POST | `/api/ads/reward` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /agency  (22 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/agency/applicant-score/[userId]` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/agency/apply` | mobile-jwt | FLUTTER_READY |  |  | — | contactEmail, contactPhone, description, name |
| GET | `/api/agency/earnings` | mobile-jwt | FLUTTER_READY |  |  | page | — |
| GET | `/api/agency/growth` | rbac | FLUTTER_READY |  |  | agencyId | — |
| GET | `/api/agency/invite` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/agency/invite` | mobile-jwt | FLUTTER_READY |  |  | — | expiresInDays, maxUses |
| GET | `/api/agency/invite-earnings` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, offset | — |
| POST | `/api/agency/join` | mobile-jwt | FLUTTER_READY |  |  | — | inviteCode |
| GET | `/api/agency/leaderboard` | public | PUBLIC |  |  | limit, period | — |
| DELETE | `/api/agency/leave` | mobile-jwt | FLUTTER_READY |  |  | — | action, reason, requestId, reviewNote |
| POST | `/api/agency/leave` | mobile-jwt | FLUTTER_READY |  |  | — | action, reason, requestId, reviewNote |
| GET | `/api/agency/live-status` | rbac | FLUTTER_READY |  |  | agencyId | — |
| DELETE | `/api/agency/members` | mobile-jwt | FLUTTER_READY |  |  | memberId | username |
| GET | `/api/agency/members` | mobile-jwt | FLUTTER_READY |  |  | memberId | — |
| POST | `/api/agency/members` | mobile-jwt | FLUTTER_READY |  |  | memberId | username |
| GET | `/api/agency/my` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/agency/my` | mobile-jwt | FLUTTER_READY |  |  | — | description, name |
| GET | `/api/agency/tasks` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/agency/wallet` | rbac | FLUTTER_READY |  |  | limit, page | — |
| POST | `/api/agency/wallet/transfer` | rbac | FLUTTER_READY |  |  | — | amount, confirm, idempotencyKey, reason, targetUserId |
| GET | `/api/agency/withdrawals` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/agency/withdrawals` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | action, note, requestId |

## /animations  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/animations/manifest` | public | PUBLIC |  |  | category | — |
| GET | `/api/animations/me` | mobile-jwt/rbac | FLUTTER_READY |  |  | context | — |
| GET | `/api/animations/resolve` | mobile-jwt/rbac | FLUTTER_READY |  |  | — | — |

## /announcements  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/announcements` | mobile-jwt | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/announcements` | mobile-jwt | ADMIN_ONLY | ✔ |  | — | path, section |
| POST | `/api/announcements/event` | mobile-jwt | ADMIN_ONLY | ✔ |  | — | details, eventType |

## /anonymous  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/anonymous` | public | PUBLIC |  |  | deviceId | — |
| POST | `/api/anonymous` | public | PUBLIC |  |  | deviceId | deviceId, username |
| POST | `/api/anonymous/watch-ad` | public | PUBLIC |  |  | — | deviceId |

## /astrology-panel  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/astrology-panel` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /auth  (22 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/auth/[...nextauth]` | public | PUBLIC |  |  | — | — |
| POST | `/api/auth/[...nextauth]` | public | PUBLIC |  |  | — | — |
| POST | `/api/auth/change-password` | mobile-jwt | FLUTTER_READY |  |  | — | currentPassword, newPassword |
| POST | `/api/auth/email/send-verification` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/auth/email/verify` | public | PUBLIC |  |  | token | — |
| POST | `/api/auth/email/verify` | public | PUBLIC |  |  | token | — |
| POST | `/api/auth/forgot-password` | public | PUBLIC |  |  | — | email |
| POST | `/api/auth/logout` | mobile-jwt | FLUTTER_READY |  |  | — | deviceToken, refreshToken |
| POST | `/api/auth/logout-all` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/auth/mobile-apple` | mobile-jwt | FLUTTER_READY |  |  | — | fullName, identityToken, referralCode |
| POST | `/api/auth/mobile-google` | mobile-jwt | FLUTTER_READY |  |  | — | email, idToken, name, picture, referralCode, sub |
| POST | `/api/auth/mobile-login` | mobile-jwt | FLUTTER_READY |  |  | — | email, password, username |
| POST | `/api/auth/mobile-refresh` | mobile-jwt | FLUTTER_READY |  |  | — | refreshToken |
| POST | `/api/auth/mobile-register` | mobile-jwt | FLUTTER_READY |  |  | — | birthDate, birthTime, email, name, password, preferredLanguage, referralCode, username |
| POST | `/api/auth/mobile-tiktok` | mobile-jwt | FLUTTER_READY |  |  | — | code, redirectUri, referralCode |
| POST | `/api/auth/phone/send-otp` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/auth/phone/verify-otp` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/auth/reclaim-device` | web-session | MISSING_MOBILE_SUPPORT |  |  | — | — |
| POST | `/api/auth/reset-password` | public | PUBLIC |  |  | — | password, token |
| DELETE | `/api/auth/sessions` | mobile-jwt | FLUTTER_READY |  |  | deviceId | — |
| GET | `/api/auth/sessions` | mobile-jwt | FLUTTER_READY |  |  | deviceId | — |
| GET | `/api/auth/verify-device` | web-session | WEB_ONLY |  |  | — | — |

## /avatar-accessories  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/avatar-accessories` | public | PUBLIC |  |  | — | — |

## /bana-ozel  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/bana-ozel` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/bana-ozel/open` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /billing  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/billing/app-store/verify` | mobile-jwt | FLUTTER_READY |  |  | — | productId, receiptData |
| POST | `/api/billing/google-play/verify` | mobile-jwt | FLUTTER_READY |  |  | — | productId, purchaseToken |

## /blog  (10 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/blog` | public | PUBLIC |  |  | category, editorPick, featured, limit, page, search, slug, trending, zodiacSign | — |
| GET | `/api/blog/categories` | public | PUBLIC |  |  | — | — |
| DELETE | `/api/blog/comments` | mobile-jwt | FLUTTER_READY |  |  | id, postId | content, parentId, postId |
| GET | `/api/blog/comments` | mobile-jwt | FLUTTER_READY |  |  | id, postId | — |
| POST | `/api/blog/comments` | mobile-jwt | FLUTTER_READY |  |  | id, postId | content, parentId, postId |
| POST | `/api/blog/favorite` | mobile-jwt | FLUTTER_READY |  |  | — | postId |
| GET | `/api/blog/interactions` | mobile-jwt | FLUTTER_READY |  |  | postId | — |
| POST | `/api/blog/like` | mobile-jwt | FLUTTER_READY |  |  | — | postId |
| GET | `/api/blog/related` | public | PUBLIC |  |  | category, limit, slug | — |
| GET | `/api/blog/zodiac` | public | PUBLIC |  |  | limit, sign | — |

## /bootstrap  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/bootstrap` | rbac | FLUTTER_READY |  |  | platform | — |

## /broadcast-images  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/broadcast-images` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /cache  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/cache` | mobile-jwt | FLUTTER_READY |  |  | field, key, member, op, pattern, start, stop | — |
| POST | `/api/cache` | mobile-jwt | FLUTTER_READY |  |  | field, key, member, op, pattern, start, stop | channel, data, field, key, member, members, message, op, prefix, score, ttl, value, values |

## /cfc-arena  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/cfc-arena` | public | PUBLIC |  |  | — | — |
| GET | `/api/cfc-arena/[contestId]` | public | PUBLIC |  |  | — | — |
| POST | `/api/cfc-arena/join` | rbac | FLUTTER_READY |  |  | — | contestId |

## /chat-bubbles  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/chat-bubbles` | public | PUBLIC |  |  | — | — |

## /chat  (61 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/chat/broadcast-images` | public | PUBLIC |  |  | — | — |
| DELETE | `/api/chat/cleanup` | cron-secret | INTERNAL |  |  | — | — |
| GET | `/api/chat/cleanup` | cron-secret | INTERNAL |  |  | — | — |
| POST | `/api/chat/cleanup` | cron-secret | INTERNAL |  |  | — | — |
| GET | `/api/chat/rooms` | public | PUBLIC |  |  | withCounts | — |
| GET | `/api/chat/rooms/[roomId]/dj` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/chat/rooms/[roomId]/dj` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | action, userId |
| GET | `/api/chat/rooms/[roomId]/gifts` | mobile-jwt/web-session | FLUTTER_READY |  |  | after | — |
| POST | `/api/chat/rooms/[roomId]/gifts` | mobile-jwt/web-session | FLUTTER_READY |  |  | after | giftTypeId, platform, quantity, receiverName, senderName |
| DELETE | `/api/chat/rooms/[roomId]/messages` | mobile-jwt/web-session | FLUTTER_READY |  |  | after, limit, messageId | content, nickname |
| GET | `/api/chat/rooms/[roomId]/messages` | mobile-jwt/web-session | FLUTTER_READY |  |  | after, limit, messageId | — |
| POST | `/api/chat/rooms/[roomId]/messages` | mobile-jwt/web-session | FLUTTER_READY |  |  | after, limit, messageId | content, nickname |
| GET | `/api/chat/rooms/[roomId]/moderation` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/moderation` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | action, duration, message, reason, role, targetUserId, ttl |
| DELETE | `/api/chat/rooms/[roomId]/music` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | duration, title, videoId |
| GET | `/api/chat/rooms/[roomId]/music` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/music` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | duration, title, videoId |
| GET | `/api/chat/rooms/[roomId]/music-queue` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/music/stop` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/pin-message` | public | PUBLIC |  |  | — | text, ttl |
| GET | `/api/chat/rooms/[roomId]/pk` | admin-helper/mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/chat/rooms/[roomId]/pk` | admin-helper/mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | opponentUserId, side1UserIds, side2UserIds |
| POST | `/api/chat/rooms/[roomId]/pk/score` | admin-helper/mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | amount, battleId, side |
| DELETE | `/api/chat/rooms/[roomId]/presence` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | _delete, leave | nickname, password, seatIndex |
| GET | `/api/chat/rooms/[roomId]/presence` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | _delete, leave | — |
| POST | `/api/chat/rooms/[roomId]/presence` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | _delete, leave | nickname, password, seatIndex |
| GET | `/api/chat/rooms/[roomId]/seats` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/chat/rooms/[roomId]/seats` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | forceAssign, forceThrone, seatIndex, targetUserId |
| GET | `/api/chat/rooms/[roomId]/settings` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/chat/rooms/[roomId]/settings` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | backgroundImage, bannedWords, bannerImage, descEn, descTr, giftCommissionPercent, icon, isActive, isMuted, nameEn, nameTr, password, pinnedAnnouncement, roomType, seatCount, tags, welcomeMessage, whitelistedWords |
| GET | `/api/chat/rooms/[roomId]/song-request` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/chat/rooms/[roomId]/song-request` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | dedication, duration, note, priority, requestId, requestType, title, videoId |
| POST | `/api/chat/rooms/[roomId]/song-request` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | dedication, duration, note, priority, requestId, requestType, title, videoId |
| DELETE | `/api/chat/rooms/[roomId]/speak-request` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | message |
| GET | `/api/chat/rooms/[roomId]/speak-request` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/speak-request` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | message |
| DELETE | `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | reason |
| POST | `/api/chat/rooms/[roomId]/speak-request/[userId]/block` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | reason |
| DELETE | `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | reason |
| POST | `/api/chat/rooms/[roomId]/speak-request/[userId]/reject` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | reason |
| GET | `/api/chat/rooms/[roomId]/speak-requests` | mobile-jwt/web-session | FLUTTER_READY |  |  | status | — |
| POST | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/approve` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| DELETE | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | public | DEPRECATED_ALIAS |  |  | — | reason |
| POST | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/block` | public | DEPRECATED_ALIAS |  |  | — | reason |
| DELETE | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | public | DEPRECATED_ALIAS |  |  | — | reason |
| POST | `/api/chat/rooms/[roomId]/speak-requests/[targetUserId]/reject` | public | DEPRECATED_ALIAS |  |  | — | reason |
| GET | `/api/chat/rooms/[roomId]/state` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/chat/rooms/[roomId]/stream` | mobile-jwt/web-session | FLUTTER_READY |  | ✔ | lastEventId | — |
| GET | `/api/chat/rooms/[roomId]/sync` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/transfer-ownership` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | newOwnerId |
| GET | `/api/chat/rooms/[roomId]/typing` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/typing` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | isTyping |
| GET | `/api/chat/rooms/[roomId]/voice` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/chat/rooms/[roomId]/voice` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | type |
| GET | `/api/chat/rooms/backgrounds` | public | PUBLIC |  |  | — | — |
| POST | `/api/chat/rooms/create` | mobile-jwt | FLUTTER_READY |  |  | — | description, icon, name, paymentType, roomType |
| GET | `/api/chat/rooms/pk-list` | public | PUBLIC |  |  | status | — |
| GET | `/api/chat/rooms/pk/candidates` | mobile-jwt/web-session | FLUTTER_READY |  |  | roomId | — |
| GET | `/api/chat/youtube-audio` | public | PUBLIC |  |  | start, url, v, videoId | — |
| POST | `/api/chat/youtube-audio` | public | PUBLIC |  |  | start, url, v, videoId | — |
| GET | `/api/chat/youtube-stream` | public | PUBLIC |  |  | start, v, videoId | — |

## /compatibility  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/compatibility` | public | PUBLIC |  |  | — | moonSign1, moonSign2, risingSign1, risingSign2, sign1, sign2 |

## /config  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/config` | public | PUBLIC |  |  | platform | — |

## /contact  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/contact` | public | PUBLIC |  |  | — | email, message, name |

## /credit-packages  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/credit-packages` | public | PUBLIC |  |  | — | — |

## /cron  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/cron/membership-expiry` | cron-secret | INTERNAL |  |  | limit | — |
| POST | `/api/cron/membership-expiry` | cron-secret | INTERNAL |  |  | limit | — |

## /currency-branding  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/currency-branding` | public | PUBLIC |  |  | — | — |

## /daily-login  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/daily-login` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/daily-login` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /daily-missions  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/daily-missions` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/daily-missions` | mobile-jwt | FLUTTER_READY |  |  | — | taskType |

## /deeplink  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/deeplink/resolve` | public | PUBLIC |  |  | type, url, value | — |

## /devices  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| DELETE | `/api/devices/fcm` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | appVersion, platform, token |
| POST | `/api/devices/fcm` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | appVersion, platform, token |

## /dream-contest  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/dream-contest` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/dream-contest/[contestId]/entries` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/dream-contest/[contestId]/entries` | mobile-jwt | FLUTTER_READY |  |  | — | interpretation |
| POST | `/api/dream-contest/[contestId]/vote` | mobile-jwt | FLUTTER_READY |  |  | — | entryId |

## /dream-diary  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| DELETE | `/api/dream-diary` | mobile-jwt | FLUTTER_READY |  |  | month, year | analyzeWithAI, content, dreamDate, id, lucidity, mood, symbols, title |
| GET | `/api/dream-diary` | mobile-jwt | FLUTTER_READY |  |  | month, year | — |
| POST | `/api/dream-diary` | mobile-jwt | FLUTTER_READY |  |  | month, year | analyzeWithAI, content, dreamDate, id, lucidity, mood, symbols, title |

## /dream-stats  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/dream-stats` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /dream-symbols  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/dream-symbols` | public | PUBLIC |  |  | letter, search | — |
| GET | `/api/dream-symbols/[slug]` | public | PUBLIC |  |  | — | — |

## /dreams  (14 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/dreams` | public | PUBLIC |  |  | category, limit, page, search, sort | — |
| GET | `/api/dreams/[slug]` | public | PUBLIC |  |  | — | — |
| DELETE | `/api/dreams/[slug]/comments` | mobile-jwt | ADMIN_ONLY | ✔ |  | page, type | commentId, content, didComeTrue, experienceType |
| GET | `/api/dreams/[slug]/comments` | mobile-jwt | ADMIN_ONLY | ✔ |  | page, type | — |
| POST | `/api/dreams/[slug]/comments` | mobile-jwt | ADMIN_ONLY | ✔ |  | page, type | commentId, content, didComeTrue, experienceType |
| GET | `/api/dreams/[slug]/favorite` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/dreams/[slug]/favorite` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/dreams/[slug]/view` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/dreams/favorites` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/dreams/generate` | public | PUBLIC |  |  | — | query |
| POST | `/api/dreams/interpret` | mobile-jwt | FLUTTER_READY |  |  | — | dreamText |
| POST | `/api/dreams/morning-reminder` | cron-secret | INTERNAL |  |  | — | — |
| GET | `/api/dreams/recommendations` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/dreams/trends` | public | PUBLIC |  |  | period | — |

## /effects  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/effects/resolve` | rbac | FLUTTER_READY |  |  | broadcasterId | — |

## /emoji-packs  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/emoji-packs` | public | PUBLIC |  |  | — | — |

## /entrance-effects  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/entrance-effects` | public | PUBLIC |  |  | — | — |

## /favorite-tellers  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/favorite-tellers` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/favorite-tellers` | mobile-jwt | FLUTTER_READY |  |  | — | tellerId |

## /football  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/football` | public | PUBLIC |  |  | action, competition, competitions, dateFrom, dateTo, matchday, status | — |

## /fortune-access  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/fortune-access/check` | mobile-jwt | FLUTTER_READY |  |  | — | adWatched, fortuneType |
| GET | `/api/fortune-access/ip-status` | public | PUBLIC |  |  | — | — |

## /fortune-request-types  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/fortune-request-types` | public | PUBLIC |  |  | — | — |

## /fortune-tellers  (18 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/fortune-tellers` | mobile-jwt | FLUTTER_READY |  |  | online, sort, specialty | — |
| POST | `/api/fortune-tellers` | mobile-jwt | FLUTTER_READY |  |  | online, sort, specialty | bio, displayName, pricePerSession, specialties |
| GET | `/api/fortune-tellers/[tellerId]` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/fortune-tellers/[tellerId]` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | avatar, bio, displayName, isActive, isOnline, isVerified, pricePerSession, specialties |
| GET | `/api/fortune-tellers/[tellerId]/reviews` | public | PUBLIC |  |  | — | — |
| GET | `/api/fortune-tellers/[tellerId]/session` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/fortune-tellers/[tellerId]/session` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | duration, fortuneType |
| POST | `/api/fortune-tellers/apply` | mobile-jwt | FLUTTER_READY |  |  | — | applicationNote, bio, displayName, specialties |
| GET | `/api/fortune-tellers/awards` | public | PUBLIC |  |  | tellerId | — |
| GET | `/api/fortune-tellers/gifts` | public | PUBLIC |  |  | tellerId | — |
| GET | `/api/fortune-tellers/my-profile` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/fortune-tellers/session` | mobile-jwt/web-session | FLUTTER_READY |  |  | sessionId | — |
| POST | `/api/fortune-tellers/session` | mobile-jwt/web-session | FLUTTER_READY |  |  | sessionId | duration, fortuneType, tellerId |
| GET | `/api/fortune-tellers/sessions` | mobile-jwt/web-session | FLUTTER_READY |  |  | status | — |
| PATCH | `/api/fortune-tellers/sessions/[sessionId]` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | action |
| GET | `/api/fortune-tellers/sessions/stream` | mobile-jwt/web-session | FLUTTER_READY |  | ✔ | — | — |
| GET | `/api/fortune-tellers/toggle-online` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/fortune-tellers/toggle-online` | mobile-jwt | FLUTTER_READY |  |  | — | isOnline |

## /fortunes  (15 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/fortunes/ask-uyumu` | mobile-jwt | FLUTTER_READY |  | ✔ | — | language, partnerName, partnerSign, yourName, yourSign |
| POST | `/api/fortunes/aura-analizi` | mobile-jwt | FLUTTER_READY |  | ✔ | — | birthDate, currentMood, language, name, recentExperiences |
| POST | `/api/fortunes/burc-yorumu` | mobile-jwt | FLUTTER_READY |  | ✔ | — | language, zodiacSign |
| POST | `/api/fortunes/dogum-haritasi` | mobile-jwt | FLUTTER_READY |  | ✔ | — | birthDate, birthPlace, birthTime, language |
| POST | `/api/fortunes/el-fali` | mobile-jwt | FLUTTER_READY |  | ✔ | — | hand, language, palmImagePath |
| POST | `/api/fortunes/evet-hayir` | mobile-jwt | FLUTTER_READY |  | ✔ | — | language, question |
| POST | `/api/fortunes/istihare` | mobile-jwt | FLUTTER_READY |  | ✔ | — | language, question, situation |
| POST | `/api/fortunes/kahve-fali` | mobile-jwt | FLUTTER_READY |  | ✔ | — | description, language |
| POST | `/api/fortunes/kahve-fali-image` | mobile-jwt | FLUTTER_READY |  | ✔ | — | cupImagePath, language, saucerImagePath |
| POST | `/api/fortunes/katina` | mobile-jwt | FLUTTER_READY |  | ✔ | — | language, question |
| POST | `/api/fortunes/kursundokme` | mobile-jwt | FLUTTER_READY |  | ✔ | — | — |
| POST | `/api/fortunes/melek-kartlari` | mobile-jwt | FLUTTER_READY |  | ✔ | — | cardCount, language, question |
| POST | `/api/fortunes/numeroloji` | mobile-jwt | FLUTTER_READY |  | ✔ | — | birthDate, language, name |
| POST | `/api/fortunes/ruya-yorumu` | mobile-jwt | FLUTTER_READY |  | ✔ | — | dreamDescription, language |
| POST | `/api/fortunes/tarot-fali` | mobile-jwt | FLUTTER_READY |  | ✔ | — | cardCount, language, question |

## /games  (40 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/games` | public | PUBLIC |  |  | — | — |
| POST | `/api/games/auto-match` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/games/daily-reward` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/games/daily-reward` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/games/daily-spin` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/games/grid-settings` | public | PUBLIC |  |  | — | — |
| GET | `/api/games/lamba-cini` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/games/lamba-cini` | mobile-jwt | FLUTTER_READY |  |  | — | chestIndex |
| GET | `/api/games/leaderboard` | mobile-jwt | FLUTTER_READY |  |  | gameType, period, search | — |
| GET | `/api/games/lobby` | mobile-jwt | FLUTTER_READY |  |  | gameType, section | — |
| POST | `/api/games/play` | mobile-jwt | FLUTTER_READY |  |  | — | gameSlug, result, score |
| GET | `/api/games/profile` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/games/quests` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/games/quests` | mobile-jwt | FLUTTER_READY |  |  | — | questType |
| GET | `/api/games/room` | mobile-jwt | FLUTTER_READY |  |  | gameType, type | — |
| POST | `/api/games/room` | mobile-jwt | FLUTTER_READY |  |  | gameType, type | betAmount, betCurrency, gameType, gridSize, isAI, turnTimer |
| DELETE | `/api/games/room/[roomId]` | mobile-jwt | FLUTTER_READY |  |  | — | action, currentTurn, fullState, player1Score, player2Score, state, status, winnerId |
| GET | `/api/games/room/[roomId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/games/room/[roomId]` | mobile-jwt | FLUTTER_READY |  |  | — | action, currentTurn, fullState, player1Score, player2Score, state, status, winnerId |
| POST | `/api/games/room/[roomId]` | mobile-jwt | FLUTTER_READY |  |  | — | action, currentTurn, fullState, player1Score, player2Score, state, status, winnerId |
| GET | `/api/games/room/[roomId]/chat` | mobile-jwt | FLUTTER_READY |  |  | after | — |
| PATCH | `/api/games/room/[roomId]/chat` | mobile-jwt | FLUTTER_READY |  |  | after | chatEnabled, message |
| POST | `/api/games/room/[roomId]/chat` | mobile-jwt | FLUTTER_READY |  |  | after | chatEnabled, message |
| POST | `/api/games/room/[roomId]/replace-ai` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| DELETE | `/api/games/room/[roomId]/viewers` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/games/room/[roomId]/viewers` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/games/room/[roomId]/viewers` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/games/rooms` | public | PUBLIC |  |  | gameType, limit, status | — |
| GET | `/api/games/sos` | mobile-jwt | FLUTTER_READY |  |  | type | — |
| POST | `/api/games/sos` | mobile-jwt | FLUTTER_READY |  |  | type | betAmount, betCurrency, gridSize, isAI, turnTimer |
| DELETE | `/api/games/sos/[gameId]` | mobile-jwt | FLUTTER_READY |  |  | — | action, aiMoves, col, letter, row |
| GET | `/api/games/sos/[gameId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/games/sos/[gameId]` | mobile-jwt | FLUTTER_READY |  |  | — | action, aiMoves, col, letter, row |
| POST | `/api/games/sos/[gameId]` | mobile-jwt | FLUTTER_READY |  |  | — | action, aiMoves, col, letter, row |
| GET | `/api/games/sos/[gameId]/chat` | mobile-jwt | FLUTTER_READY |  |  | after | — |
| PATCH | `/api/games/sos/[gameId]/chat` | mobile-jwt | FLUTTER_READY |  |  | after | chatEnabled, message |
| POST | `/api/games/sos/[gameId]/chat` | mobile-jwt | FLUTTER_READY |  |  | after | chatEnabled, message |
| DELETE | `/api/games/sos/[gameId]/viewers` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/games/sos/[gameId]/viewers` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/games/sos/[gameId]/viewers` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /gift-box  (5 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/gift-box` | mobile-jwt/web-session | FLUTTER_READY |  |  | roomId, streamId | — |
| POST | `/api/gift-box` | mobile-jwt/web-session | FLUTTER_READY |  |  | roomId, streamId | roomId, streamId, taskTargetUserId |
| GET | `/api/gift-box/[boxId]` | public | PUBLIC |  |  | — | — |
| POST | `/api/gift-box/[boxId]/join` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/gift-box/share` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |

## /gift-engine  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/gift-engine/finish` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/gift-engine/gifts` | public | PUBLIC |  |  | collectionId, context | — |
| GET | `/api/gift-engine/queue` | public | PUBLIC |  |  | contextId | — |

## /gifts  (27 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/gifts/battles` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/gifts/battles` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | participants |
| GET | `/api/gifts/battles/[battleId]` | public | PUBLIC |  |  | — | — |
| GET | `/api/gifts/catalog` | mobile-jwt/web-session | FLUTTER_READY |  |  | context, sinceVersion | — |
| POST | `/api/gifts/check-reciprocal` | mobile-jwt | FLUTTER_READY |  |  | — | recipientId |
| GET | `/api/gifts/goals` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/gifts/goals` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/gifts/insights/album/[userId]` | public | PUBLIC |  |  | — | — |
| GET | `/api/gifts/insights/badge/[userId]` | public | PUBLIC |  |  | — | — |
| GET | `/api/gifts/insights/collection/[userId]` | public | PUBLIC |  |  | — | — |
| GET | `/api/gifts/insights/feed` | public | PUBLIC |  |  | context, contextId, limit | — |
| GET | `/api/gifts/insights/first-gifter/[context]/[contextId]` | public | PUBLIC |  |  | — | — |
| GET | `/api/gifts/insights/leaderboard` | public | PUBLIC |  |  | context, limit, period, scope, type | — |
| GET | `/api/gifts/insights/map` | public | PUBLIC |  |  | context, period, scope | — |
| GET | `/api/gifts/insights/me/badge` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/gifts/insights/me/history` | mobile-jwt/web-session | FLUTTER_READY |  |  | direction, limit, page, status | — |
| GET | `/api/gifts/insights/me/recommendations` | mobile-jwt/web-session | FLUTTER_READY |  |  | context, limit | — |
| GET | `/api/gifts/lucky/config` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/gifts/lucky/history` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, scope | — |
| POST | `/api/gifts/lucky/send` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | context, contextId, giftTypeId, quantity |
| GET | `/api/gifts/missions` | public | PUBLIC |  |  | — | — |
| POST | `/api/gifts/missions/[missionId]/claim` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/gifts/missions/me` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/gifts/recent-big` | public | PUBLIC |  |  | — | — |
| POST | `/api/gifts/send` | mobile-jwt | FLUTTER_READY |  |  | — | giftTypeId, jetonAmount, recipientUsername, type |
| GET | `/api/gifts/types` | public | PUBLIC |  |  | — | — |
| GET | `/api/gifts/version` | public | PUBLIC |  |  | — | — |

## /hashtags  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/hashtags/[name]` | mobile-jwt | FLUTTER_READY |  |  | cursor, limit | — |
| GET | `/api/hashtags/search` | public | PUBLIC |  |  | limit, q | — |
| GET | `/api/hashtags/trending` | public | PUBLIC |  |  | limit | — |

## /health  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/health` | public | PUBLIC |  |  | — | — |

## /homepage-buttons  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/homepage-buttons` | public | PUBLIC |  |  | — | — |

## /homepage-fortune-cards  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/homepage-fortune-cards` | public | PUBLIC |  |  | — | — |

## /homepage-ticker  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/homepage-ticker` | public | PUBLIC |  |  | — | — |

## /horoscope  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/horoscope/daily` | mobile-jwt/web-session | FLUTTER_READY |  |  | lang | — |

## /jeton  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/jeton` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/jeton` | mobile-jwt | FLUTTER_READY |  |  | — | action |

## /leaderboards  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/leaderboards` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/leaderboards/top100` | mobile-jwt/web-session | FLUTTER_READY |  |  | key, limit, period, scope | — |

## /legal  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/legal/child-safety` | public | PUBLIC |  |  | — | — |

## /live  (19 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/live/create-room` | mobile-jwt | FLUTTER_READY |  |  | — | category, coverUrl, description, thumbnailUrl, title |
| GET | `/api/live/gift-types` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/live/gift/send` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | giftTypeId, quantity, recipientId, roomId, roomType |
| GET | `/api/live/guest` | mobile-jwt/web-session | FLUTTER_READY |  |  | roomId, streamId, view | — |
| POST | `/api/live/guest` | mobile-jwt/web-session | FLUTTER_READY |  |  | roomId, streamId, view | message, muted, videoOff |
| GET | `/api/live/guest/list` | public | PUBLIC |  |  | roomId, streamId | — |
| POST | `/api/live/heartbeat` | mobile-jwt | FLUTTER_READY |  |  | — | roomId, roomType |
| POST | `/api/live/join-room` | mobile-jwt | FLUTTER_READY |  |  | — | nickname, password, roomId, roomType |
| POST | `/api/live/leave-room` | mobile-jwt | FLUTTER_READY |  |  | — | roomId, roomType |
| GET | `/api/live/message` | mobile-jwt | FLUTTER_READY |  |  | after, limit, roomId, roomType | — |
| POST | `/api/live/message` | mobile-jwt | FLUTTER_READY |  |  | after, limit, roomId, roomType | content, roomId, roomType |
| GET | `/api/live/online-users` | mobile-jwt | FLUTTER_READY |  |  | limit, roomId, roomType | — |
| GET | `/api/live/pk` | mobile-jwt | FLUTTER_READY |  |  | roomId | — |
| POST | `/api/live/pk` | mobile-jwt | FLUTTER_READY |  |  | roomId | action, battleId, duration, roomId, targetRoomId |
| GET | `/api/live/pk/active` | public | PUBLIC |  |  | includePending, roomId, streamId | — |
| POST | `/api/live/pk/score` | admin-helper/mobile-jwt/rbac | ADMIN_ONLY | ✔ |  | — | amount, battleId, roomId, side |
| GET | `/api/live/rooms` | mobile-jwt | FLUTTER_READY |  |  | limit, page, search, type | — |
| GET | `/api/live/seats` | mobile-jwt | FLUTTER_READY |  |  | roomId | — |
| POST | `/api/live/seats` | mobile-jwt | FLUTTER_READY |  |  | roomId | action, roomId, seatIndex, targetUserId |

## /me  (15 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/me` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/me` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/me/admin-capabilities` | rbac | FLUTTER_READY |  |  | — | — |
| GET | `/api/me/membership` | rbac | FLUTTER_READY |  |  | — | — |
| GET | `/api/me/membership-events` | rbac | FLUTTER_READY |  |  | — | — |
| GET | `/api/me/membership-history` | rbac | FLUTTER_READY |  |  | — | — |
| PUT | `/api/me/membership-history` | rbac | FLUTTER_READY |  |  | — | auto_renew |
| GET | `/api/me/profile-visitors` | rbac | FLUTTER_READY |  |  | limit | — |
| POST | `/api/me/profile-visitors` | rbac | FLUTTER_READY |  |  | limit | profileId |
| GET | `/api/me/vip-identity` | rbac | FLUTTER_READY |  |  | — | — |
| PUT | `/api/me/vip-identity` | rbac | FLUTTER_READY |  |  | — | custom_user_id, title |
| GET | `/api/me/vip-preferences` | rbac | FLUTTER_READY |  |  | — | — |
| PUT | `/api/me/vip-preferences` | rbac | FLUTTER_READY |  |  | — | — |
| GET | `/api/me/vip-xp` | rbac | FLUTTER_READY |  |  | limit | — |
| POST | `/api/me/vip-xp` | rbac | FLUTTER_READY |  |  | limit | — |

## /membership-badges  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/membership-badges` | public | PUBLIC |  |  | — | — |

## /membership  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/membership/plans` | public | PUBLIC |  |  | — | — |
| POST | `/api/membership/purchase` | public | DEPRECATED_ALIAS |  |  | — | paymentMethod, planId |

## /memberships  (5 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/memberships` | public | PUBLIC |  |  | — | — |
| GET | `/api/memberships/comparison` | public | PUBLIC |  |  | — | — |
| POST | `/api/memberships/gift` | mobile-jwt | FLUTTER_READY |  |  | — | message, receiverEmail, receiverId |
| GET | `/api/memberships/packages` | public | PUBLIC |  |  | — | — |
| POST | `/api/memberships/purchase` | mobile-jwt | FLUTTER_READY |  |  | — | paymentMethod, planId |

## /messages  (5 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/messages` | mobile-jwt | FLUTTER_READY |  |  | unreadCount | — |
| GET | `/api/messages/[userId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/messages/[userId]` | mobile-jwt | FLUTTER_READY |  |  | — | content, imageUrl |
| PATCH | `/api/messages/request` | mobile-jwt | FLUTTER_READY |  |  | — | action, message, receiverId, requestId |
| POST | `/api/messages/request` | mobile-jwt | FLUTTER_READY |  |  | — | action, message, receiverId, requestId |

## /mic-frames  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/mic-frames` | public | PUBLIC |  |  | — | — |

## /mobile  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/mobile/config` | public | PUBLIC |  |  | platform, version | — |
| GET | `/api/mobile/fortune-menu` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/mobile/home` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/mobile/user-profile/[userId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /monitoring  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/monitoring` | web-session | WEB_ONLY |  |  | — | — |

## /music  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/music/history` | public | PUBLIC |  |  | limit, roomId | — |
| GET | `/api/music/search` | mobile-jwt | FLUTTER_READY |  |  | q, query | — |

## /name-effects  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/name-effects` | public | PUBLIC |  |  | — | — |

## /notifications  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| DELETE | `/api/notifications` | mobile-jwt | FLUTTER_READY |  |  | id, page, unreadOnly | markAll, notificationIds |
| GET | `/api/notifications` | mobile-jwt | FLUTTER_READY |  |  | id, page, unreadOnly | — |
| POST | `/api/notifications` | mobile-jwt | FLUTTER_READY |  |  | id, page, unreadOnly | markAll, notificationIds |
| GET | `/api/notifications/stream` | mobile-jwt | FLUTTER_READY |  | ✔ | — | — |

## /online-fal  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/online-fal` | public | PUBLIC |  |  | — | — |

## /payments  (9 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/payments/config` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/payments/methods` | public | PUBLIC |  |  | — | — |
| GET | `/api/payments/notifications/[notificationId]/dispute` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/payments/notifications/[notificationId]/dispute` | rbac | FLUTTER_READY |  |  | — | message |
| GET | `/api/payments/notify` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, page, status | — |
| POST | `/api/payments/notify` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, page, status | amount, notes, paymentMethod, productType, proofUrl, requestedAmount, requestedGoldDays, requestedGoldType, senderName, transactionId |
| GET | `/api/payments/requests` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/payments/requests` | mobile-jwt | FLUTTER_READY |  |  | — | amount, method, notes, senderInfo |
| GET | `/api/payments/settings` | public | PUBLIC |  |  | — | — |

## /pk  (5 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/pk/[matchId]` | public | PUBLIC |  |  | — | — |
| GET | `/api/pk/[matchId]/stream` | public | PUBLIC |  | ✔ | — | — |
| GET | `/api/pk/active` | public | PUBLIC |  |  | includePending | — |
| GET | `/api/pk/leaderboard` | public | PUBLIC |  |  | limit, metric, period | — |
| GET | `/api/pk/me/invites` | mobile-jwt/web-session | FLUTTER_READY |  |  | direction | — |

## /platform  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/platform/commission-rate` | public | PUBLIC |  |  | — | — |

## /popups  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/popups` | mobile-jwt/web-session | FLUTTER_READY |  |  | since | — |

## /presence  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/presence` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/presence` | mobile-jwt | FLUTTER_READY |  |  | — | isNewSession, path, visitorId |
| GET | `/api/presence/online-events` | public | PUBLIC |  |  | since | — |
| GET | `/api/presence/sections` | public | PUBLIC |  |  | — | — |

## /profile-frames  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/profile-frames` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/profile-frames` | mobile-jwt | FLUTTER_READY |  |  | — | frameId |

## /public-stats  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/public-stats` | public | PUBLIC |  |  | — | — |

## /public  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/public/announcement-settings` | public | PUBLIC |  |  | — | — |
| GET | `/api/public/jeton-price` | public | PUBLIC |  |  | — | — |

## /referral  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/referral` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/referral/validate` | public | PUBLIC |  |  | code | — |

## /refunds  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/refunds` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/refunds` | mobile-jwt | FLUTTER_READY |  |  | — | paymentId, storePurchaseId |

## /room-themes  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/room-themes` | public | PUBLIC |  |  | — | — |
| GET | `/api/room-themes/catalog` | mobile-jwt/web-session | FLUTTER_READY |  |  | category, sinceVersion, tier | — |

## /room  (12 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/room/[sessionId]` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/room/[sessionId]` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | action, minutes |
| GET | `/api/room/[sessionId]/messages` | mobile-jwt/web-session | FLUTTER_READY |  |  | after | — |
| POST | `/api/room/[sessionId]/messages` | mobile-jwt/web-session | FLUTTER_READY |  |  | after | message |
| GET | `/api/room/[sessionId]/review` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/room/[sessionId]/review` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | comment, rating |
| GET | `/api/room/[sessionId]/stream` | mobile-jwt/web-session | FLUTTER_READY |  | ✔ | — | — |
| GET | `/api/room/[sessionId]/summary` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/room/[sessionId]/tip` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | amount |
| DELETE | `/api/room/signal` | mobile-jwt/web-session | FLUTTER_READY |  |  | sessionId | receiverId, sessionId, signalData, signalType |
| GET | `/api/room/signal` | mobile-jwt/web-session | FLUTTER_READY |  |  | sessionId | — |
| POST | `/api/room/signal` | mobile-jwt/web-session | FLUTTER_READY |  |  | sessionId | receiverId, sessionId, signalData, signalType |

## /rtc  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/rtc/telemetry` | rbac | FLUTTER_READY |  |  | — | samples |

## /search  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/search` | public | PUBLIC |  |  | lang, q | — |
| GET | `/api/search/advanced` | mobile-jwt | FLUTTER_READY |  |  | minRating, onlineOnly, q, sortBy, specialty, type | — |

## /seo-settings  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/seo-settings` | public | PUBLIC |  |  | — | — |

## /settings  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/settings/ads` | public | PUBLIC |  |  | — | — |
| GET | `/api/settings/canlidark-hero` | public | PUBLIC |  |  | — | — |
| GET | `/api/settings/public` | public | PUBLIC |  |  | key, keys | — |
| GET | `/api/settings/themes` | public | PUBLIC |  |  | — | — |

## /share-card  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/share-card` | mobile-jwt | FLUTTER_READY |  |  | fortuneId, postId | — |

## /short-videos  (21 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/short-videos` | mobile-jwt | FLUTTER_READY |  |  | cursor, limit, tab | — |
| DELETE | `/api/short-videos/[id]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/short-videos/[id]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/short-videos/[id]/comments` | mobile-jwt | FLUTTER_READY |  |  | limit, parentId | — |
| POST | `/api/short-videos/[id]/comments` | mobile-jwt | FLUTTER_READY |  |  | limit, parentId | content, parentId |
| DELETE | `/api/short-videos/[id]/comments/[commentId]` | mobile-jwt | ADMIN_ONLY | ✔ |  | — | — |
| POST | `/api/short-videos/[id]/comments/[commentId]/like` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/[id]/comments/[commentId]/pin` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/short-videos/[id]/duets` | mobile-jwt | FLUTTER_READY |  |  | cursor, limit | — |
| POST | `/api/short-videos/[id]/like` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/[id]/save` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/[id]/share` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/[id]/view` | mobile-jwt | FLUTTER_READY |  |  | — | watchedSec |
| GET | `/api/short-videos/explore` | mobile-jwt | FLUTTER_READY |  |  | cursor, limit, q | — |
| GET | `/api/short-videos/mentions/search` | public | PUBLIC |  |  | limit, q | — |
| GET | `/api/short-videos/music` | public | PUBLIC |  |  | limit, q | — |
| GET | `/api/short-videos/profile/[userId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/register` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/upload` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/short-videos/upload-url` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/short-videos/user/[userId]` | mobile-jwt | FLUTTER_READY |  |  | cursor, limit, tab | — |

## /signup  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/signup` | public | PUBLIC |  |  | — | birthDate, birthTime, email, name, password, preferredLanguage, referralCode, username |

## /site-pages  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/site-pages/[slug]` | public | PUBLIC |  |  | — | — |

## /social  (13 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/social/actions` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/social/actions` | rbac | FLUTTER_READY |  |  | — | message, targetId, type |
| GET | `/api/social/discovery` | rbac | FLUTTER_READY |  |  | — | — |
| GET | `/api/social/posts` | mobile-jwt | FLUTTER_READY |  |  | limit, page, type | — |
| POST | `/api/social/posts` | mobile-jwt | FLUTTER_READY |  |  | limit, page, type | content, fortuneId, fortuneType, imageUrl, isPublic, postType, youtubeUrl |
| DELETE | `/api/social/posts/[postId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/social/posts/[postId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| DELETE | `/api/social/posts/[postId]/comments` | mobile-jwt | FLUTTER_READY |  |  | commentId | content |
| GET | `/api/social/posts/[postId]/comments` | mobile-jwt | FLUTTER_READY |  |  | commentId | — |
| POST | `/api/social/posts/[postId]/comments` | mobile-jwt | FLUTTER_READY |  |  | commentId | content |
| POST | `/api/social/posts/[postId]/likes` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/social/posts/[postId]/view` | public | PUBLIC |  |  | — | — |
| GET | `/api/social/profile` | rbac | FLUTTER_READY |  |  | userId | — |

## /stories  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| DELETE | `/api/stories` | mobile-jwt | FLUTTER_READY |  |  | id | caption, mediaType, mediaUrl |
| GET | `/api/stories` | mobile-jwt | FLUTTER_READY |  |  | id | — |
| POST | `/api/stories` | mobile-jwt | FLUTTER_READY |  |  | id | caption, mediaType, mediaUrl |

## /support  (5 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/support/tickets` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/support/tickets` | rbac | FLUTTER_READY |  |  | — | category, message, subject |
| GET | `/api/support/tickets/[ticketId]` | rbac | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/support/tickets/[ticketId]` | rbac | FLUTTER_READY |  |  | — | assignedTo, priority, status |
| POST | `/api/support/tickets/[ticketId]/messages` | rbac | FLUTTER_READY |  |  | — | body, isInternal, message |

## /supporter-levels  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/supporter-levels` | rbac | FLUTTER_READY |  |  | broadcasterId | — |

## /teams  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/teams` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/teams` | rbac | FLUTTER_READY |  |  | — | description, logoUrl, name |
| GET | `/api/teams/[teamId]` | rbac | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/teams/[teamId]` | rbac | FLUTTER_READY |  |  | — | action |

## /teller-chat  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/teller-chat` | mobile-jwt/web-session | FLUTTER_READY |  |  | role | — |
| GET | `/api/teller-chat/[sessionId]` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/teller-chat/[sessionId]` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | content, imageUrl, messageType |

## /teller  (4 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/teller/analytics` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/teller/level` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/teller/verification` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/teller/verification` | mobile-jwt | FLUTTER_READY |  |  | — | docUrl |

## /tencent  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/tencent/webhook` | public | PUBLIC |  |  | — | CallbackTs, EventGroupId, EventInfo, EventType |

## /tiktok-videos  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/tiktok-videos` | public | PUBLIC |  |  | categoryId, limit | — |
| GET | `/api/tiktok-videos/[id]` | public | PUBLIC |  |  | — | — |
| GET | `/api/tiktok-videos/oembed` | public | PUBLIC |  |  | url | — |

## /tmdb  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/tmdb` | public | PUBLIC |  |  | action, genre, id, page, query, sort, time, type | — |

## /tournaments  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/tournaments` | mobile-jwt/web-session | FLUTTER_READY |  |  | category, filter | — |

## /translations  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/translations` | public | PUBLIC |  |  | — | — |

## /trend-videos  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/trend-videos` | public | PUBLIC |  |  | category, limit, sort | — |
| POST | `/api/trend-videos` | public | PUBLIC |  |  | category, limit, sort | videoId |

## /trends  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/trends` | public | PUBLIC |  |  | category, limit, page | — |
| GET | `/api/trends/[slug]` | public | PUBLIC |  |  | — | — |
| POST | `/api/trends/[slug]/like` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /trtc  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| POST | `/api/trtc/token` | mobile-jwt | FLUTTER_READY |  |  | — | role, roomId |
| POST | `/api/trtc/usersig` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/trtc/webhook` | public | PUBLIC |  |  | — | — |

## /upload  (3 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/upload/get-url` | mobile-jwt | FLUTTER_READY |  |  | path | — |
| POST | `/api/upload/get-url` | mobile-jwt | FLUTTER_READY |  |  | path | cloud_storage_path, isPublic |
| POST | `/api/upload/presigned` | mobile-jwt | FLUTTER_READY |  |  | — | contentType, fileName, folder, isPublic |

## /user  (41 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/user/[userId]/achievements` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| DELETE | `/api/user/[userId]/follow` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/user/[userId]/follow` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/[userId]/follow-status` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| DELETE | `/api/user/account` | mobile-jwt | FLUTTER_READY |  |  | — | password, reason |
| POST | `/api/user/account` | mobile-jwt | FLUTTER_READY |  |  | — | password, reason |
| POST | `/api/user/account/delete` | public | DEPRECATED_ALIAS |  |  | — | password, reason |
| GET | `/api/user/achievements` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/active-sessions` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/activity` | mobile-jwt | FLUTTER_READY |  |  | limit, page, type, unread | — |
| PATCH | `/api/user/activity` | mobile-jwt | FLUTTER_READY |  |  | limit, page, type, unread | markAllRead, notificationIds |
| GET | `/api/user/block` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/user/block` | mobile-jwt | FLUTTER_READY |  |  | — | userId |
| DELETE | `/api/user/blocked` | mobile-jwt | FLUTTER_READY |  |  | — | id, type |
| GET | `/api/user/blocked` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/broadcast-history` | mobile-jwt | FLUTTER_READY |  |  | limit, page, status | — |
| GET | `/api/user/co-broadcast-invites` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/credits` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/followers` | mobile-jwt | FLUTTER_READY |  |  | userId | — |
| GET | `/api/user/following` | mobile-jwt | FLUTTER_READY |  |  | userId | — |
| GET | `/api/user/fortunes` | mobile-jwt | FLUTTER_READY |  |  | pinned, saved | — |
| PATCH | `/api/user/fortunes/[fortuneId]` | mobile-jwt | FLUTTER_READY |  |  | — | action |
| GET | `/api/user/likers` | mobile-jwt | FLUTTER_READY |  |  | userId | — |
| GET | `/api/user/location` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/user/location` | rbac | FLUTTER_READY |  |  | — | latitude, locationEnabled, longitude, showDistance |
| GET | `/api/user/profile` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/user/profile` | mobile-jwt | FLUTTER_READY |  |  | — | bio, birthDate, birthTime, email, favoriteTeam, hideProfileViews, image, messagePrivacy, name, phone, risingSign, username, zodiacSign |
| GET | `/api/user/received-gifts` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/referral-earnings` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, offset, type | — |
| POST | `/api/user/report` | mobile-jwt | FLUTTER_READY |  |  | — | details, reason, userId |
| GET | `/api/user/social-settings` | rbac | FLUTTER_READY |  |  | — | — |
| PUT | `/api/user/social-settings` | rbac | FLUTTER_READY |  |  | — | hobbies, showAge, showCity, showDistance, showLastActive, socialLinks, socialLinksPublic |
| GET | `/api/user/statistics` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/stats` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/user/stats` | mobile-jwt | FLUTTER_READY |  |  | — | minutesToAdd |
| GET | `/api/user/theme` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/user/theme` | mobile-jwt | FLUTTER_READY |  |  | — | theme |
| GET | `/api/user/wallet` | mobile-jwt/web-session | FLUTTER_READY |  |  | currency, limit, offset | — |
| GET | `/api/user/watch-ad` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/user/watch-ad` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/user/xp` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /users  (7 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/users/[userId]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/users/[userId]/follow` | mobile-jwt | FLUTTER_READY |  |  | type | — |
| POST | `/api/users/[userId]/follow` | mobile-jwt | FLUTTER_READY |  |  | type | — |
| GET | `/api/users/[userId]/posts` | mobile-jwt | FLUTTER_READY |  |  | limit, page, type | — |
| GET | `/api/users/lookup/[username]` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/users/online` | public | PUBLIC |  |  | — | — |
| GET | `/api/users/search` | mobile-jwt | FLUTTER_READY |  |  | q | — |

## /verification  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/verification` | rbac | FLUTTER_READY |  |  | — | — |
| POST | `/api/verification` | rbac | FLUTTER_READY |  |  | — | documentType, documentUrls, fullName, note, type |

## /video-streams  (55 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/video-streams` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, page | — |
| POST | `/api/video-streams` | mobile-jwt/web-session | FLUTTER_READY |  |  | limit, page | category, coverUrl, description, tags, thumbnailUrl, title |
| GET | `/api/video-streams/[streamId]` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | — |
| PATCH | `/api/video-streams/[streamId]` | mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | — | backgroundUrl, broadcastImage, description, isImageMode, status, title |
| GET | `/api/video-streams/[streamId]/auto-close` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/auto-close` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| DELETE | `/api/video-streams/[streamId]/ban` | mobile-jwt | FLUTTER_READY |  |  | userId | reason, userId |
| GET | `/api/video-streams/[streamId]/ban` | mobile-jwt | FLUTTER_READY |  |  | userId | — |
| POST | `/api/video-streams/[streamId]/ban` | mobile-jwt | FLUTTER_READY |  |  | userId | reason, userId |
| GET | `/api/video-streams/[streamId]/co-broadcast` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| PATCH | `/api/video-streams/[streamId]/co-broadcast` | mobile-jwt | FLUTTER_READY |  |  | — | action, userId |
| POST | `/api/video-streams/[streamId]/co-broadcast` | mobile-jwt | FLUTTER_READY |  |  | — | action, userId |
| POST | `/api/video-streams/[streamId]/co-broadcast/invite` | mobile-jwt | FLUTTER_READY |  |  | — | inviteeId |
| GET | `/api/video-streams/[streamId]/comments` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/comments` | mobile-jwt | FLUTTER_READY |  |  | — | content, isHidden, nickname |
| POST | `/api/video-streams/[streamId]/end` | mobile-jwt | ADMIN_ONLY | ✔ |  | — | — |
| DELETE | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | FLUTTER_READY |  |  | refundAll, userId | action, anonymous, displayName, fortuneTypeId, hidden, isHidden, message, nickName, nickname, question, requestId, requestTypeId, text, typeId, type_id |
| GET | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | FLUTTER_READY |  |  | refundAll, userId | — |
| PATCH | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | FLUTTER_READY |  |  | refundAll, userId | action, anonymous, displayName, fortuneTypeId, hidden, isHidden, message, nickName, nickname, question, requestId, requestTypeId, text, typeId, type_id |
| POST | `/api/video-streams/[streamId]/fortune-requests` | mobile-jwt | FLUTTER_READY |  |  | refundAll, userId | action, anonymous, displayName, fortuneTypeId, hidden, isHidden, message, nickName, nickname, question, requestId, requestTypeId, text, typeId, type_id |
| GET | `/api/video-streams/[streamId]/fortune-requests/my-status` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/video-streams/[streamId]/gifts` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/gifts` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | giftTypeId, quantity |
| DELETE | `/api/video-streams/[streamId]/join` | mobile-jwt | FLUTTER_READY |  |  | viewerId | — |
| POST | `/api/video-streams/[streamId]/join` | mobile-jwt | FLUTTER_READY |  |  | viewerId | — |
| POST | `/api/video-streams/[streamId]/leave` | mobile-jwt | FLUTTER_READY |  |  | viewerId | viewerId |
| GET | `/api/video-streams/[streamId]/like` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/like` | mobile-jwt | FLUTTER_READY |  |  | — | count |
| POST | `/api/video-streams/[streamId]/live-started` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/media-heartbeat` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/video-streams/[streamId]/messages` | mobile-jwt | FLUTTER_READY |  |  | limit, since | — |
| POST | `/api/video-streams/[streamId]/messages` | mobile-jwt | FLUTTER_READY |  |  | limit, since | — |
| DELETE | `/api/video-streams/[streamId]/moderators` | mobile-jwt | FLUTTER_READY |  |  | — | userId |
| GET | `/api/video-streams/[streamId]/moderators` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/moderators` | mobile-jwt | FLUTTER_READY |  |  | — | userId |
| DELETE | `/api/video-streams/[streamId]/mute` | mobile-jwt | FLUTTER_READY |  |  | — | expiresAt, reason, viewerId |
| GET | `/api/video-streams/[streamId]/mute` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/mute` | mobile-jwt | FLUTTER_READY |  |  | — | expiresAt, reason, viewerId |
| GET | `/api/video-streams/[streamId]/pk-battle` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/video-streams/[streamId]/pk-battle` | mobile-jwt | FLUTTER_READY |  |  | — | action, battleId, duration, targetStreamId |
| DELETE | `/api/video-streams/[streamId]/signal` | mobile-jwt | FLUTTER_READY |  |  | recipientId | data, receiverId, type |
| GET | `/api/video-streams/[streamId]/signal` | mobile-jwt | FLUTTER_READY |  |  | recipientId | — |
| POST | `/api/video-streams/[streamId]/signal` | mobile-jwt | FLUTTER_READY |  |  | recipientId | data, receiverId, type |
| GET | `/api/video-streams/[streamId]/stream` | mobile-jwt | FLUTTER_READY |  | ✔ | — | — |
| GET | `/api/video-streams/[streamId]/sync` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| GET | `/api/video-streams/[streamId]/viewers` | public | PUBLIC |  |  | — | — |
| GET | `/api/video-streams/gifts` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| GET | `/api/video-streams/pk` | admin-helper/mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | streamId | — |
| POST | `/api/video-streams/pk` | admin-helper/mobile-jwt/web-session | ADMIN_ONLY | ✔ |  | streamId | action, battleId, duration, opponentVoiceRoomId, streamId, targetStreamId |
| GET | `/api/video-streams/pk/candidates` | mobile-jwt/web-session | FLUTTER_READY |  |  | streamId | — |
| GET | `/api/video-streams/pk/list` | public | PUBLIC |  |  | — | — |
| POST | `/api/video-streams/pk/score` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | battleId, points, streamId |
| DELETE | `/api/video-streams/signal` | mobile-jwt | FLUTTER_READY |  |  | recipientId, streamId | data, receiverId, streamId, type |
| GET | `/api/video-streams/signal` | mobile-jwt | FLUTTER_READY |  |  | recipientId, streamId | — |
| POST | `/api/video-streams/signal` | mobile-jwt | FLUTTER_READY |  |  | recipientId, streamId | data, receiverId, streamId, type |

## /vip  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/vip/leaderboard` | rbac | FLUTTER_READY |  |  | limit | — |

## /wallet  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/wallet` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /warmup  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/warmup` | public | PUBLIC |  |  | — | — |

## /weekly-dream-report  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/weekly-dream-report` | mobile-jwt | FLUTTER_READY |  |  | — | — |
| POST | `/api/weekly-dream-report` | mobile-jwt | FLUTTER_READY |  |  | — | — |

## /withdrawals  (2 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/withdrawals` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | — |
| POST | `/api/withdrawals` | mobile-jwt/web-session | FLUTTER_READY |  |  | — | accountDetails, amount, currency, method |

## /youtube  (1 endpoint)

| Method | Path | Auth | Sınıf | Admin | SSE | Query | Body alanları |
|---|---|---|---|---|---|---|---|
| GET | `/api/youtube/search` | mobile-jwt | FLUTTER_READY |  |  | q | — |

---

## BÖLÜM 22 — Multi-Guest · PK/Battle · Hediye Kutusu

Bu uçların tam sözleşmesi ayrı dosyadadır: **BOLUM22_MULTIGUEST_PK_GIFTBOX.md**

- `POST /api/live/guest` · `GET /api/live/guest/list`
- `POST|GET /api/video-streams/pk` · `POST|GET /api/chat/rooms/{roomId}/pk` · `POST /api/live/pk/score` · `POST /api/chat/rooms/{roomId}/pk/score`
- `GET|POST /api/gift-box` · `GET /api/gift-box/{boxId}` · `POST /api/gift-box/{boxId}/join` · `POST /api/gift-box/share`
- `GET /api/video-streams/{streamId}/sync` · `GET /api/chat/rooms/{roomId}/sync`
