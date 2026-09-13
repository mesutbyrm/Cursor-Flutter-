# CanlıFal — Servis / Kütüphane Katmanı

Toplam modül: **118**

Bu katman API route'larının arkasındaki iş mantığıdır. Flutter istemcisi bunlara doğrudan erişmez; ancak dönen alan adları, hesaplama kuralları ve durum makineleri buradan gelir.

| Modül | Satır | Dışa açılan semboller |
|---|---:|---|
| `lib/activity-logger.ts` | 63 | `ActivityType`, `cleanOldActivities`, `logActivity` |
| `lib/ad-placements.ts` | 180 | `AD_ADMIN_ROLES`, `AD_FULL_ADMIN_ROLES`, `AD_PLATFORMS`, `AD_PLATFORM_LABELS`, `AD_POSITIONS`, `AD_POSITION_LABELS`, `AD_TYPES`, `AD_TYPE_LABELS`, `AdAdminAuth`, `AdPlatform`, `AdPosition`, `AdType`, `DEFAULT_AD_PLACEMENTS`, `ResolvedPlacement`, `coerceEnum`, `normalizePlacementKey`, `passesTargeting`, `requireAdAdmin`, `resolveAdPlacement` |
| `lib/admin-check.ts` | 30 | `getExcludedUserIds`, `isExcludedFromFinance` |
| `lib/admin-utils.ts` | 57 | `ADMIN_ROLES`, `FULL_ADMIN_ROLES`, `MEMBERSHIP_LABELS`, `MEMBERSHIP_ORDER`, `ROLE_LABELS`, `isAdminRole`, `isFullAdmin`, `isStaffSpender`, `isYonetici` |
| `lib/agency-commission.ts` | 94 | `processAgencyCommission` |
| `lib/agency-wallet.ts` | 432 | `AGENCY_COMMISSION_SOURCES`, `AGENCY_LEVELS`, `AGENCY_SETTING_KEYS`, `AGENCY_WALLET_USES`, `ResolvedRule`, `WalletMoveResult`, `adjustWallet`, `getAgencyJetonRate`, `getAllBonusRules`, `getAllowedWalletUses`, `getBonusRateForLevel`, `getCommissionRules`, `getOrCreateWallet`, `invalidateAgencySettingsCache`, `resolveCommissionRule`, `topUpWallet`, `transferToUser` |
| `lib/animation-admin.ts` | 144 | `ANIMATION_ADMIN_ROLES`, `ANIMATION_FULL_ADMIN_ROLES`, `AnimationAdminAuth`, `DURATION_PRESETS`, `DurationPreset`, `coerceAnimationPayload`, `requireAnimationAdmin`, `resolveEndDate`, `slugifyAnimation` |
| `lib/animation-constants.ts` | 128 | `ANIMATION_ANCHORS`, `ANIMATION_CATEGORIES`, `ANIMATION_CONTEXTS`, `ANIMATION_POSITIONS`, `ANIMATION_PRIORITY`, `ANIMATION_RARITIES`, `ANIMATION_SCALES`, `ANIMATION_STATUSES`, `ANIMATION_TYPES`, `ASSIGNMENT_PRIORITY`, `AnimationCategory`, `AnimationContext`, `LEGACY_TYPES`, `LEGACY_TYPE_TO_CATEGORY`, `LegacyType`, `MEMBERSHIP_TIERS`, `MembershipTier`, `isPrivilegedRole`, `membershipRank` |
| `lib/animation-resolver.ts` | 293 | `AnimationPayload`, `ResolveOptions`, `logAnimationPlayback`, `resolveUserAnimation`, `resolveUserAnimations` |
| `lib/api-response.ts` | 289 | `ErrorCode`, `ErrorCodes`, `apiError`, `apiForbidden`, `apiInternalError`, `apiNotFound`, `apiPaginated`, `apiRateLimited`, `apiSuccess`, `apiUnauthorized`, `apiValidation`, `getRequestId` |
| `lib/apple-billing.ts` | 106 | `AppleVerifyResult`, `getAppleSharedSecret`, `isAppleBillingConfigured`, `verifyAppleReceipt` |
| `lib/audit-log.ts` | 87 | `AuditParams`, `getAuditIp`, `getAuditLogs`, `recordAudit` |
| `lib/auth-options.ts` | 157 | `authOptions` |
| `lib/auto-linker.ts` | 136 | `KeywordLink`, `addInternalLinks` |
| `lib/aws-config.ts` | 13 | `createS3Client`, `getBucketConfig` |
| `lib/balance-guard.ts` | 89 | `BalanceField`, `atomicDebitCredits`, `atomicDebitJeton`, `atomicDebitOp`, `isInsufficientBalanceError` |
| `lib/bot-fortune-messages.ts` | 123 | `DREAM_COMMENTS`, `FORTUNE_POST_TEMPLATES`, `FORTUNE_TYPES`, `FORTUNE_TYPE_LABELS`, `FortuneType` |
| `lib/bot-messages.ts` | 210 | `CHAT_MESSAGES`, `FAREWELLS`, `FORTUNE_MESSAGES`, `GENERAL_MESSAGES`, `GREETINGS`, `Personality`, `REACTIONS`, `generateBotMessage`, `maybeAddTypo`, `pickRandom` |
| `lib/bot-social-messages.ts` | 82 | `POST_COMMENTS`, `STREAM_COMMENTS`, `STREAM_EMOJIS`, `pickRandom` |
| `lib/cache.ts` | 597 | `CACHE_TTL`, `getCacheStats`, `getCached`, `getCachedAchievements`, `getCachedAllPlatformSettings`, `getCachedChatRoom`, `getCachedCreditPackages`, `getCachedFortuneRequestTypes`, `getCachedGiftTypes`, `getCachedHomepageButtons`, `getCachedHomepageFortuneCards`, `getCachedPaymentMethods`, `getCachedPlatformSetting`, `invalidateCache`, `invalidateCachePrefix`, `redisCache` |
| `lib/chat-dj-events.ts` | 149 | `buildDjPayload`, `emitDjUpdate`, `getLatestDjEvent` |
| `lib/chat-events.ts` | 91 | `emitChatEvent`, `getChatEventsSince`, `getTypingUsers`, `nextEventId` |
| `lib/chat-permissions.ts` | 190 | `ChatRole`, `ROLE_HIERARCHY`, `ROLE_LABELS`, `ROLE_SYMBOLS`, `UserPermissions`, `canUserSpeak`, `getUserPermissions`, `getUserRole`, `isUserBanned` |
| `lib/check-feature.ts` | 96 | `getFeatureFlags`, `isFeatureEnabled`, `requireFeature` |
| `lib/cosmetics.ts` | 194 | `CosmeticAdminConfig`, `CosmeticPublicConfig`, `createCosmeticAdminHandlers`, `createCosmeticPublicHandlers` |
| `lib/credit-checker.ts` | 175 | `FORTUNE_COSTS`, `FortuneType`, `checkAndDeductCredits`, `getUserCredits`, `sendFortuneSummaryEmail` |
| `lib/critical-confirm.ts` | 174 | `CRITICAL_THRESHOLDS`, `CriticalCheck`, `checkCritical`, `requireConfirmation` |
| `lib/crypto-vault.ts` | 100 | `CipherBundle`, `SECRET_MASK`, `decryptSecret`, `encryptSecret`, `hmacCode`, `timingSafeEqualHex`, `vaultKeyStatus` |
| `lib/currency-branding.ts` | 238 | `BonusTier`, `CONVERTIBLE_CURRENCIES`, `CURRENCY_SETTING_DEFAULTS`, `CURRENCY_SETTING_KEYS`, `CURRENCY_SETTING_LABELS`, `CurrencyBrand`, `CurrencyBranding`, `DEFAULT_BONUS_TIERS`, `DEFAULT_CURRENCY_BRANDING`, `NON_CONVERTIBLE_CURRENCIES`, `REWARD_BALANCE_FIELD`, `REWARD_CURRENCY`, `applyTopupBonus`, `getCurrencyBranding`, `invalidateCurrencyBrandingCache`, `isConvertibleCurrency`, `resolveTopupBonus` |
| `lib/db.ts` | 73 | `prisma` |
| `lib/deeplink.ts` | 214 | `DEEPLINK_SCHEME`, `DeepLink`, `DeepLinkType`, `buildDeepLink`, `resolveDeepLink` |
| `lib/distance-bands.ts` | 55 | `DistanceBand`, `bandToText`, `computeDistanceBand`, `distanceToBand`, `haversineKm` |
| `lib/dream-categories.ts` | 27 | `DREAM_CATEGORIES`, `DreamCategory`, `getCategoryIcon`, `getCategoryLabel` |
| `lib/dream-utils.ts` | 16 | `slugifyTurkish` |
| `lib/effect-rules.ts` | 78 | `EffectContext`, `ResolvedEffect`, `resolveEffects` |
| `lib/email-service.ts` | 190 | `getContactFormEmailHtml`, `getFortuneReadingSummaryHtml`, `getLowCreditsEmailHtml`, `getNewUserSignupEmailHtml`, `getWelcomeEmailHtml`, `sendNotificationEmail` |
| `lib/event-announcement.ts` | 82 | `triggerEventAnnouncement` |
| `lib/fortune-access.ts` | 128 | `FortuneAccessResult`, `checkIpFortuneAccess`, `checkRegisteredFortuneAccess`, `getClientIp` |
| `lib/fortune-handler.ts` | 159 | `handleFortuneRequest` |
| `lib/game-logic.ts` | 2349 | `GameType`, `Meld`, `OkeyTile`, `amiralBattiAI`, `amiralBattiInit`, `amiralBattiMove`, `amiralBattiPlaceShips`, `connect4AI`, `connect4Init`, `connect4Move`, `damaAI`, `damaInit`, `damaMove`, `getInitialState`, `gomokuAI`, `gomokuInit`, `gomokuMove`, `kartEslestirmePvpAI`, `kartEslestirmePvpInit`, `kartEslestirmePvpMove`, `kelimeDuellosuAI`, `kelimeDuellosuInit`, `kelimeDuellosuMove`, `mangalaAI`, `mangalaInit` … |
| `lib/gift-battles.ts` | 273 | `BATTLE_ALLOWED_DURATIONS`, `BATTLE_DEFAULT_DURATION`, `SerializedBattle`, `SerializedGoal`, `SerializedParticipant`, `normaliseDuration`, `readContextPair`, `serializeBattle`, `serializeGoal` |
| `lib/gift-box.ts` | 386 | `BUILTIN_TASK_TYPES`, `GIFT_BOX_ERROR_MESSAGES`, `GiftBoxErrors`, `GiftBoxEventName`, `GiftBoxLimits`, `GiftBoxView`, `TASK_LABELS`, `TaskContext`, `broadcastGiftBox`, `checkGiftBoxEligibility`, `closeGiftBoxesFor`, `computeSplits`, `expireStaleBoxes`, `getGiftBoxLimits`, `isPresent`, `parseSplits`, `serializeGiftBox`, `settleGiftBox`, `verifyGiftBoxTask` |
| `lib/gift-engine.ts` | 507 | `ANIMATION_TYPES`, `DISPLAY_AREAS`, `GiftContext`, `PRIORITIES`, `SEAT_EFFECTS`, `buildGiftReceivedPayload`, `cleanupQueue`, `comboMilestone`, `computeCombo`, `emitGiftEngineEvent`, `enqueueGift`, `finishQueueEntry`, `getQueueSnapshot`, `processGiftSend`, `resolveAnimationType`, `resolveDisplayArea`, `resolveDurationMs`, `resolvePriority`, `resolveSeatEffect`, `resolveSoundEffect` |
| `lib/gift-insights.ts` | 364 | `GIFT_CONTEXTS`, `GIFT_SELECT`, `MissionDefinition`, `PERIODS`, `Period`, `PublicGift`, `PublicUser`, `SUPPORTER_TIERS`, `Scope`, `SupporterTier`, `USER_SELECT`, `activeMissions`, `buildSupporterBadge`, `clampLimit`, `dayStartUtc`, `displayAmount`, `displayNameOf`, `ledgerWhere`, `missionProgressForUser`, `normalizeContext`, `normalizePeriod`, `normalizeScope`, `periodStart`, `rewardOf`, `serializeGift` … |
| `lib/gift-media-probe.ts` | 72 | `generateVideoThumbnail` |
| `lib/gift-pk-score.ts` | 198 | `GiftPkScoreResult`, `applyGiftPkScore` |
| `lib/gift-render.ts` | 102 | `GiftRenderMeta`, `buildGiftRenderMeta` |
| `lib/idempotency.ts` | 173 | `IDEMPOTENCY_TTL_MS`, `IdempotencyOutcome`, `beginIdempotent`, `completeIdempotent`, `getIdempotencyKey`, `releaseIdempotent` |
| `lib/integration-secrets.ts` | 167 | `deleteProviderConfig`, `deleteSecret`, `getIntegrationSetting`, `getProviderConfig`, `getSecret`, `hasSecret`, `invalidateIntegrationCache`, `invalidateIntegrationSettings`, `secretSource`, `setIntegrationSetting`, `setProviderConfig`, `setSecret` |
| `lib/leaderboard-engine.ts` | 470 | `LeaderboardScope`, `PeriodType`, `RewardConfigEntry`, `ScoringRules`, `distributeRewards`, `ensureDefaultConfigs`, `finalizeExpiredPeriods`, `getActiveConfigs`, `getConfig`, `getOrCreateCurrentPeriod`, `getTop100`, `incrementLeaderboardScore` |
| `lib/ledger.ts` | 242 | `AccountType`, `Currency`, `LedgerCategory`, `LedgerLeg`, `LedgerParams`, `getAccountLedger`, `getTransaction`, `recordLedger`, `recordMultiLeg` |
| `lib/live-guest.ts` | 315 | `GUEST_ERROR_MESSAGES`, `GuestErrorCode`, `GuestErrors`, `GuestLimits`, `GuestView`, `MODERATOR_ROLES`, `broadcastGuests`, `checkGuestEligibility`, `closeGuestStateForStream`, `emitGuestRequestEvent`, `expireStalePending`, `getGuestLimits`, `gridSlotsFor`, `listGuests`, `nextFreeSlot`, `pendingRequestCount`, `resolveGuestAuthority` |
| `lib/llm.ts` | 66 | `callLLM` |
| `lib/log-redact.ts` | 78 | `REDACTED`, `maskPhone`, `redact`, `redactHeaders`, `redactString`, `safeError`, `safeLog` |
| `lib/media-url.ts` | 219 | `GiftMediaFields`, `computeGiftMediaFields`, `deriveAssetFormat`, `deriveMediaType`, `deriveMimeType`, `resolveMediaUrl`, `serializeGiftMedia` |
| `lib/membership-lifecycle.ts` | 172 | `ApplyMembershipInput`, `ApplyMembershipResult`, `applyMembership`, `membershipsExpiringWithin`, `sweepExpiredMemberships` |
| `lib/mobile-auth.ts` | 109 | `AuthenticatedUser`, `MobileTokenPayload`, `authenticateRequest`, `generateMobileTokens`, `verifyMobileToken` |
| `lib/mp4-duration.ts` | 95 | `getMp4DurationSec` |
| `lib/music-permissions.ts` | 43 | `canControlMusic` |
| `lib/notify.ts` | 268 | `DEFAULT_DEDUPE_WINDOW_SECONDS`, `buildNotificationDedupeKey`, `createBulkNotificationsWithPush`, `createNotificationWithPush`, `resolveNotificationDeepLink` |
| `lib/onesignal-admin.ts` | 214 | `OneSignalSendResult`, `SendNotificationParams`, `cancelNotification`, `getAppStats`, `getNotificationDetails`, `sendNotification` |
| `lib/onesignal.ts` | 265 | `getNotificationTitle`, `getNotificationUrl`, `sendOneSignalPush`, `sendOneSignalPushToMany`, `sendPushToMultipleUsers`, `sendPushToUser` |
| `lib/pagination.ts` | 124 | `CursorParams`, `buildCursorMeta`, `cursorQuery`, `fetchCursorPage`, `isCursorMode`, `parseCursorParams`, `parseOffsetParams` |
| `lib/payment-status.ts` | 117 | `DEFAULT_ADMIN_NOTES`, `PAYMENT_METHOD_LABELS`, `PAYMENT_STATUS_COLORS`, `PAYMENT_STATUS_LABELS`, `PRODUCT_TYPE_LABELS`, `PaymentStatus`, `decoratePaymentNotification` |
| `lib/perf.ts` | 257 | `GET`, `SLOW_THRESHOLD_MS`, `checkETag`, `clearAuthCacheForUser`, `getCachedAuth`, `getMonitoringSnapshot`, `invalidateCachedAuth`, `recordTiming`, `setCachedAuth`, `withPerfHeaders`, `withTiming` |
| `lib/permissions.ts` | 419 | `PERMISSIONS`, `PERMISSION_GROUPS`, `PermissionDef`, `SYSTEM_ROLES`, `getEffectivePermissions`, `getRolePermissions`, `hasPermission`, `listRoles`, `setRolePermissions`, `staffCan` |
| `lib/pk-expiry.ts` | 100 | `PK_TIMEOUT_MS`, `expireAllStalePKs`, `expirePendingPK` |
| `lib/pk-match.ts` | 141 | `PkMatch`, `loadPkUsers`, `mapPkStatus`, `serializePkMatch`, `serializePkMatches` |
| `lib/pk-state.ts` | 533 | `PK_LIVE_STATUSES`, `PK_PENDING_STATUSES`, `PK_RUNNING_STATUSES`, `PK_STATE_ALIASES`, `PK_TERMINAL_STATUSES`, `PkMode`, `PkScope`, `PkStatus`, `abortPendingPk`, `addPkParticipants`, `checkPkTransition`, `computePkOutcome`, `derivePkMode`, `emitPkToBothSides`, `endPksForSide`, `ensurePkSidesAlive`, `finalizeExpiredActivePKs`, `findBlockingPk`, `finishPkBattle`, `getPkLimits`, `listPkParticipants`, `pausePkBattle`, `resumePkBattle`, `startPkBattle` |
| `lib/presence-engine.ts` | 219 | `ONLINE_EVENT_COOLDOWN_MS`, `ONLINE_EVENT_FEED_WINDOW_MS`, `ONLINE_WINDOW_MS`, `PRESENCE_LABELS`, `PresenceStatus`, `cleanupOldOnlineEvents`, `computeTellerStatus`, `getRecentOnlineEvents`, `maybeEmitOnlineEntrance` |
| `lib/push-notifications.ts` | 157 | `getPermissionStatus`, `isPushSupported`, `playNotificationSound`, `registerServiceWorker`, `requestNotificationPermission`, `showBrowserNotification` |
| `lib/push.ts` | 60 | `PUSH_PROVIDER`, `UnifiedPushPayload`, `sendPush`, `sendPushBulk` |
| `lib/r2-storage.ts` | 180 | `PresignedUpload`, `UploadResult`, `buildPublicUrl`, `deleteFromR2`, `extractR2Key`, `getPresignedDownloadUrl`, `getPresignedUploadUrl`, `getPresignedUploadUrlForFile`, `isR2Key`, `uploadToR2` |
| `lib/rate-limit-guard.ts` | 149 | `DEFAULT_RATE_LIMITS`, `RateLimitOptions`, `getClientIp`, `guardRateLimit`, `resolveIdentity`, `resolveLimit` |
| `lib/rate-limiter.ts` | 75 | `apiLimiter`, `authLimiter`, `heavyLimiter`, `rateLimit` |
| `lib/rbac.ts` | 225 | `ResolvedUser`, `SUPER_ADMIN_ROLES`, `isSuperAdmin`, `requireAdmin`, `requireAnyPermission`, `requireAuth`, `requireFullAdmin`, `requireOwnerOrAdmin`, `requirePermission`, `requireRole`, `requireSuperAdmin`, `resolveUser` |
| `lib/referral-commission.ts` | 376 | `AGENCY_PAYOUT_BALANCE_FIELD`, `AGENCY_PAYOUT_CURRENCY`, `COMMISSION_PAYOUT_BALANCE_FIELD`, `COMMISSION_PAYOUT_CURRENCY`, `COMMISSION_SETTING_DEFAULTS`, `COMMISSION_SETTING_KEYS`, `COMMISSION_SETTING_LABELS`, `CommissionConfig`, `REFERRAL_PAYOUT_BALANCE_FIELD`, `REFERRAL_PAYOUT_CURRENCY`, `TopupCommissionInput`, `TopupCommissionResult`, `awardTopupCommissions`, `getCommissionConfig`, `getCommissionSummary`, `invalidateCommissionConfigCache`, `resolveAgencyPayout` |
| `lib/risk-score.ts` | 291 | `DEFAULT_RISK_RULES`, `RiskCategory`, `RiskInput`, `RiskLevel`, `RiskResult`, `RiskRules`, `RiskSignal`, `computeRiskScore`, `getRiskEvents`, `recordRiskEvent` |
| `lib/room-events.ts` | 105 | `clearRoomEvents`, `emitRoomEvent`, `emitTellerEvent`, `getRoomEventsSince`, `getTellerEventsSince` |
| `lib/rtc-telemetry.ts` | 418 | `DEFAULT_RTC_THRESHOLDS`, `RtcContext`, `RtcQualityLevel`, `RtcQualityResult`, `RtcTelemetryInput`, `RtcTelemetryQuery`, `RtcTelemetrySummary`, `RtcThresholds`, `computeRtcQuality`, `getRtcTelemetry`, `getRtcTelemetrySummary`, `recordRtcTelemetry` |
| `lib/s3.ts` | 105 | `deleteFile`, `generatePresignedUploadUrl`, `getFileUrl` |
| `lib/seo-config.ts` | 215 | `BLOG_POSTS`, `FORTUNE_SEO`, `SEO_PAGES`, `SITE_DESCRIPTION_EN`, `SITE_DESCRIPTION_TR`, `SITE_NAME`, `SITE_URL` |
| `lib/services/leaderboard-service.ts` | 76 | `CommunityLeaderboards`, `LeaderboardEntry`, `getCommunityLeaderboards` |
| `lib/short-videos.ts` | 277 | `AuthorDTO`, `CreateShortVideoInput`, `createShortVideoRecord`, `mapAuthor`, `mapVideo`, `normalizeCommentSetting`, `normalizeVisibility`, `parseHashtags`, `parseMentions`, `safeFloat`, `safeInt`, `syncVideoHashtags`, `syncVideoMentions` |
| `lib/sms.ts` | 42 | `getSmsProvider`, `isSmsConfigured`, `normalizePhone`, `sendSms` |
| `lib/sms/adapters.ts` | 562 | `DEFAULT_TIMEOUT_MS`, `SMS_ADAPTERS`, `SmsAdapter`, `SmsBalanceResult`, `SmsConfig`, `SmsConfigValidation`, `SmsHealthResult`, `SmsSendResult`, `getAdapter` |
| `lib/sms/catalog.ts` | 308 | `SMS_PROVIDERS`, `SmsFieldDef`, `SmsProviderMeta`, `getProviderMeta`, `listProviderKeys` |
| `lib/sms/service.ts` | 451 | `ProviderState`, `SMS_SETTING_KEYS`, `SelectionMode`, `SendOutcome`, `checkProviderBalance`, `getSelectionMode`, `isSmsConfiguredAsync`, `listProviderStates`, `loadProviderConfig`, `providerConfigStatus`, `resolveProviderChain`, `sendOtpSms`, `sendSmsMessage`, `testProviderConnection` |
| `lib/social-helper.ts` | 165 | `autoShareFortune` |
| `lib/sorbak/mock-data.ts` | 101 | `mockAnswers`, `mockCategories`, `mockQuestions`, `mockTags`, `mockUsers`, `topAnswerers`, `weeklyActiveUsers` |
| `lib/sorbak/types.ts` | 102 | `FeedTab`, `PLATFORM_NAME`, `PLATFORM_SLUG`, `SBAnswer`, `SBBadge`, `SBCategory`, `SBComment`, `SBPollOption`, `SBQuestion`, `SBTag`, `SBUser` |
| `lib/speak-requests.ts` | 89 | `SpeakRequestDto`, `canModerateSpeakRequests`, `getActiveSpeakBlock`, `loadRequestUser`, `serializeSpeakRequest` |
| `lib/sse-resume.ts` | 57 | `newestTimestamp`, `parseLastEventId`, `resumeCursor`, `sseIdLine` |
| `lib/store-billing.ts` | 169 | `PlayVerifyResult`, `acknowledgeGooglePlayPurchase`, `getPlayPackageName`, `getPlayServiceAccountJson`, `isPlayBillingConfigured`, `verifyGooglePlayPurchase` |
| `lib/store-grant.ts` | 110 | `grantMappedPurchase` |
| `lib/stream-auto-close.ts` | 99 | `closeStreamForMediaInactivity`, `getMediaInactivityTimeoutMs`, `sweepMediaInactiveStreams` |
| `lib/stream-events.ts` | 71 | `emitStreamEvent`, `getStreamEventsSince` |
| `lib/supporter-level.ts` | 66 | `SUPPORTER_TIERS`, `recordContribution`, `resolveTier` |
| `lib/team-points.ts` | 40 | `recordTeamPoints` |
| `lib/teller-levels.ts` | 75 | `LEVEL_LABELS_TR`, `LEVEL_ORDER`, `TELLER_LEVELS`, `TellerLevel`, `calculateLevelPoints`, `getLevelForPoints`, `getNextLevel`, `getProgressToNextLevel` |
| `lib/token-revocation.ts` | 145 | `getUserRevokedAt`, `hashToken`, `isTokenRevoked`, `isTokenStillValid`, `revokeAllUserTokens`, `revokeToken` |
| `lib/tournament-state.ts` | 182 | `TERMINAL_STATUSES`, `TOURNAMENT_STATUSES`, `TournamentStatus`, `checkTournamentTransition`, `finalizeExpiredTournaments`, `getLeaderboard`, `incrementScore`, `joinTournament`, `snapshotRanks`, `transitionTournament`, `validateTournamentData` |
| `lib/trtc-client.ts` | 249 | `TRTCCredentials`, `TRTCRole`, `createTRTCInstance`, `destroyTRTC`, `enableAudioVolumeEvaluation`, `enterRoom`, `exitRoom`, `fetchTRTCCredentials`, `getCameraList`, `getMicrophoneList`, `getTRTCEvent`, `isSupported`, `muteLocalAudio`, `muteRemoteAudio`, `startLocalAudio`, `startLocalVideo`, `startRemoteVideo`, `stopLocalAudio`, `stopLocalVideo`, `stopRemoteVideo`, `switchRole`, `updateLocalVideo` |
| `lib/trtc-room.ts` | 32 | `userIdToNumericUid`, `voiceTrtcRoomId` |
| `lib/types.ts` | 56 | `Fortune`, `FortuneType`, `Translation` |
| `lib/ua-parser.ts` | 86 | `UAInfo`, `deviceEmoji`, `parseUserAgent` |
| `lib/user-timeline.ts` | 49 | `TimelineEventInput`, `getUserTimeline`, `recordTimelineEvent`, `recordTimelineEventSafe` |
| `lib/utils.ts` | 28 | `cn`, `formatDuration`, `stripHtml` |
| `lib/vip-entitlements.ts` | 429 | `DiscoveryCandidate`, `FeatureGrant`, `FeatureInfo`, `MATRIX_CACHE_KEY`, `NEW_USER_GRACE_DAYS`, `TIER_CACHE_KEY`, `TierInfo`, `UserEntitlements`, `VipPreferences`, `applyDiscoveryWeighting`, `capabilityLimit`, `discoveryWeight`, `getMatrix`, `getTierInfo`, `getTiers`, `getUserEntitlements`, `hasCapability`, `invalidateUserEntitlements`, `invalidateVipCatalog`, `meetsMinTier`, `normalizeTierKey`, `resolveTierFeatures`, `userEntitlementCacheKey`, `userTierRank` |
| `lib/vip-features.ts` | 164 | `DEFAULT_TIERS`, `FEATURE_CATALOG`, `FEATURE_KEYS`, `FeatureSeed`, `FeatureValueType`, `TierSeed` |
| `lib/vip-guard.ts` | 71 | `VipGuardResult`, `requireCapability`, `requireMinTier`, `resolveUserId` |
| `lib/vip-xp.ts` | 258 | `AwardVipXpInput`, `AwardVipXpResult`, `VIP_LEVEL_THRESHOLDS`, `VIP_XP_SOURCES`, `VipLeaderboardRow`, `VipXpSource`, `VipXpSourceDef`, `awardVipXp`, `awardVipXpSafe`, `claimDailyLoginXp`, `getVipLeaderboard`, `getVipXpSummary`, `vipLevelFor` |
| `lib/voice-room-constants.ts` | 44 | `MAX_SEAT_INDEX`, `SEAT_COUNT`, `SEAT_STALE_MS`, `findFirstFreeSeat`, `seatStaleThreshold` |
| `lib/voice-room-events.ts` | 220 | `RoomEventKind`, `RoomEventPayload`, `SpeakRequestUser`, `emitHostChanged`, `emitMicChanged`, `emitOwnerChanged`, `emitPkInvite`, `emitRoomClosed`, `emitSeatChanged`, `emitUserJoined`, `emitUserLeft`, `emitVoiceRequest`, `emitVoiceRequestAccepted`, `emitVoiceRequestBlocked`, `emitVoiceRequestCancelled`, `emitVoiceRequestRejected`, `emitVoiceRequestUnblocked` |
| `lib/voice-room-gifts.ts` | 42 | `getReceivedJetonTotals` |
| `lib/voice-room-revenue.ts` | 168 | `ROOM_TYPES`, `RoomType`, `calculateGiftDistribution`, `calculateMusicDistribution`, `getMaxUsersForRoomType`, `logRoomRevenue`, `roomTypeSupports` |
| `lib/voice-room-seats.ts` | 279 | `DEFAULT_SEAT_COUNT`, `MAX_GUEST_SEATS`, `MAX_PRIVILEGED_SEATS`, `MAX_SEAT_COUNT`, `MIN_SEAT_COUNT`, `OWNER_SEAT_INDEX`, `PRIVILEGED_MIN_MEMBERSHIP`, `SEAT_SETTING_KEY`, `SeatComposition`, `SeatKind`, `SeatLayoutEntry`, `SeatState`, `SeatUserContext`, `buildSeatLayout`, `canSitOnSeat`, `canUsePrivilegedSeat`, `clampSeatCount`, `findFirstFreeSeatFor`, `getGlobalSeatCount`, `getSeatComposition`, `resolveRoomSeatCount`, `seatAuthorityWeight`, `seatKind` |
| `lib/webrtc-config.ts` | 679 | `AdaptiveBitrateManager`, `BITRATE_PRESETS`, `BitrateConfig`, `ICE_SERVERS`, `MAX_RECONNECT_ATTEMPTS`, `NetworkStats`, `RECONNECT_DELAY`, `SIMULCAST_ENCODINGS`, `TurnServerConfig`, `VideoQuality`, `addTrackWithSimulcast`, `applyInitialBitrate`, `getMediaConstraints`, `getNetworkStats`, `getRTCConfiguration`, `isMobileDevice`, `setAudioBitrate`, `setPreferredCodec`, `setVideoBitrate`, `setupConnectionRecovery` |
