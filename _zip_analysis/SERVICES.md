# CanlıFal — Servis / Kütüphane Katmanı

Toplam modül: **95**

Bu katman API route’larının arkasındaki iş mantığıdır. Flutter istemcisi bunlara doğrudan erişmez; ancak dönen alan adları, hesaplama kuralları ve durum makineleri buradan gelir.

| Modül | Satır | Dışa açılan semboller |
|---|---|---|
| `lib/activity-logger.ts` | 62 | `ActivityType`, `cleanOldActivities`, `logActivity` |
| `lib/ad-placements.ts` | 179 | `AD_ADMIN_ROLES`, `AD_FULL_ADMIN_ROLES`, `AD_PLATFORMS`, `AD_PLATFORM_LABELS`, `AD_POSITIONS`, `AD_POSITION_LABELS`, `AD_TYPES`, `AD_TYPE_LABELS`, `AdAdminAuth`, `AdPlatform`, `AdPosition`, `AdType`, `DEFAULT_AD_PLACEMENTS`, `ResolvedPlacement`, `coerceEnum`, `normalizePlacementKey`, `passesTargeting`, `requireAdAdmin`, `resolveAdPlacement` |
| `lib/admin-check.ts` | 29 | `getExcludedUserIds`, `isExcludedFromFinance` |
| `lib/admin-utils.ts` | 56 | `ADMIN_ROLES`, `FULL_ADMIN_ROLES`, `MEMBERSHIP_LABELS`, `MEMBERSHIP_ORDER`, `ROLE_LABELS`, `isAdminRole`, `isFullAdmin`, `isStaffSpender`, `isYonetici` |
| `lib/agency-commission.ts` | 85 | `processAgencyCommission` |
| `lib/animation-admin.ts` | 143 | `ANIMATION_ADMIN_ROLES`, `ANIMATION_FULL_ADMIN_ROLES`, `AnimationAdminAuth`, `DURATION_PRESETS`, `DurationPreset`, `coerceAnimationPayload`, `requireAnimationAdmin`, `resolveEndDate`, `slugifyAnimation` |
| `lib/animation-constants.ts` | 127 | `ANIMATION_ANCHORS`, `ANIMATION_CATEGORIES`, `ANIMATION_CONTEXTS`, `ANIMATION_POSITIONS`, `ANIMATION_PRIORITY`, `ANIMATION_RARITIES`, `ANIMATION_SCALES`, `ANIMATION_STATUSES`, `ANIMATION_TYPES`, `ASSIGNMENT_PRIORITY`, `AnimationCategory`, `AnimationContext`, `LEGACY_TYPES`, `LEGACY_TYPE_TO_CATEGORY`, `LegacyType`, `MEMBERSHIP_TIERS`, `MembershipTier`, `isPrivilegedRole`, `membershipRank` |
| `lib/animation-resolver.ts` | 292 | `AnimationPayload`, `ResolveOptions`, `logAnimationPlayback`, `resolveUserAnimation`, `resolveUserAnimations` |
| `lib/api-response.ts` | 288 | `ErrorCode`, `ErrorCodes`, `apiError`, `apiForbidden`, `apiInternalError`, `apiNotFound`, `apiPaginated`, `apiRateLimited`, `apiSuccess`, `apiUnauthorized`, `apiValidation`, `getRequestId` |
| `lib/audit-log.ts` | 86 | `AuditParams`, `getAuditIp`, `getAuditLogs`, `recordAudit` |
| `lib/auth-options.ts` | 156 | `authOptions` |
| `lib/auto-linker.ts` | 135 | `KeywordLink`, `addInternalLinks` |
| `lib/aws-config.ts` | 12 | `createS3Client`, `getBucketConfig` |
| `lib/bot-fortune-messages.ts` | 122 | `DREAM_COMMENTS`, `FORTUNE_POST_TEMPLATES`, `FORTUNE_TYPES`, `FORTUNE_TYPE_LABELS`, `FortuneType` |
| `lib/bot-messages.ts` | 209 | `CHAT_MESSAGES`, `FAREWELLS`, `FORTUNE_MESSAGES`, `GENERAL_MESSAGES`, `GREETINGS`, `Personality`, `REACTIONS`, `generateBotMessage`, `maybeAddTypo`, `pickRandom` |
| `lib/bot-social-messages.ts` | 81 | `POST_COMMENTS`, `STREAM_COMMENTS`, `STREAM_EMOJIS`, `pickRandom` |
| `lib/cache.ts` | 596 | `CACHE_TTL`, `getCacheStats`, `getCached`, `getCachedAchievements`, `getCachedAllPlatformSettings`, `getCachedChatRoom`, `getCachedCreditPackages`, `getCachedFortuneRequestTypes`, `getCachedGiftTypes`, `getCachedHomepageButtons`, `getCachedHomepageFortuneCards`, `getCachedPaymentMethods`, `getCachedPlatformSetting`, `invalidateCache`, `invalidateCachePrefix`, `redisCache` |
| `lib/chat-dj-events.ts` | 148 | `buildDjPayload`, `emitDjUpdate`, `getLatestDjEvent` |
| `lib/chat-events.ts` | 90 | `emitChatEvent`, `getChatEventsSince`, `getTypingUsers`, `nextEventId` |
| `lib/chat-permissions.ts` | 189 | `ChatRole`, `ROLE_HIERARCHY`, `ROLE_LABELS`, `ROLE_SYMBOLS`, `UserPermissions`, `canUserSpeak`, `getUserPermissions`, `getUserRole`, `isUserBanned` |
| `lib/check-feature.ts` | 95 | `getFeatureFlags`, `isFeatureEnabled`, `requireFeature` |
| `lib/cosmetics.ts` | 193 | `CosmeticAdminConfig`, `CosmeticPublicConfig`, `createCosmeticAdminHandlers`, `createCosmeticPublicHandlers` |
| `lib/credit-checker.ts` | 174 | `FORTUNE_COSTS`, `FortuneType`, `checkAndDeductCredits`, `getUserCredits`, `sendFortuneSummaryEmail` |
| `lib/critical-confirm.ts` | 151 | `CRITICAL_THRESHOLDS`, `CriticalCheck`, `checkCritical`, `requireConfirmation` |
| `lib/currency-branding-context.tsx` | 127 | `CurrencyBrand`, `CurrencyBrandingProvider`, `CurrencyBrandingValue`, `DEFAULT_BRANDING`, `useCurrencyBrand`, `useCurrencyBranding` |
| `lib/currency-branding.ts` | 237 | `BonusTier`, `CONVERTIBLE_CURRENCIES`, `CURRENCY_SETTING_DEFAULTS`, `CURRENCY_SETTING_KEYS`, `CURRENCY_SETTING_LABELS`, `CurrencyBrand`, `CurrencyBranding`, `DEFAULT_BONUS_TIERS`, `DEFAULT_CURRENCY_BRANDING`, `NON_CONVERTIBLE_CURRENCIES`, `REWARD_BALANCE_FIELD`, `REWARD_CURRENCY`, `applyTopupBonus`, `getCurrencyBranding`, `invalidateCurrencyBrandingCache`, `isConvertibleCurrency`, `resolveTopupBonus` |
| `lib/db.ts` | 72 | `prisma` |
| `lib/deeplink.ts` | 213 | `DEEPLINK_SCHEME`, `DeepLink`, `DeepLinkType`, `buildDeepLink`, `resolveDeepLink` |
| `lib/dream-categories.ts` | 26 | `DREAM_CATEGORIES`, `DreamCategory`, `getCategoryIcon`, `getCategoryLabel` |
| `lib/dream-utils.ts` | 15 | `slugifyTurkish` |
| `lib/effect-rules.ts` | 77 | `EffectContext`, `ResolvedEffect`, `resolveEffects` |
| `lib/email-service.ts` | 189 | `getContactFormEmailHtml`, `getFortuneReadingSummaryHtml`, `getLowCreditsEmailHtml`, `getNewUserSignupEmailHtml`, `getWelcomeEmailHtml`, `sendNotificationEmail` |
| `lib/event-announcement.ts` | 81 | `triggerEventAnnouncement` |
| `lib/fortune-access.ts` | 121 | `FortuneAccessResult`, `checkIpFortuneAccess`, `checkRegisteredFortuneAccess`, `getClientIp` |
| `lib/fortune-handler.ts` | 158 | `handleFortuneRequest` |
| `lib/game-logic.ts` | 2348 | `GameType`, `Meld`, `OkeyTile`, `amiralBattiAI`, `amiralBattiInit`, `amiralBattiMove`, `amiralBattiPlaceShips`, `connect4AI`, `connect4Init`, `connect4Move`, `damaAI`, `damaInit`, `damaMove`, `getInitialState`, `gomokuAI`, `gomokuInit`, `gomokuMove`, `kartEslestirmePvpAI`, `kartEslestirmePvpInit`, `kartEslestirmePvpMove`, `kelimeDuellosuAI`, `kelimeDuellosuInit`, `kelimeDuellosuMove`, `mangalaAI` … |
| `lib/gift-battles.ts` | 272 | `BATTLE_ALLOWED_DURATIONS`, `BATTLE_DEFAULT_DURATION`, `SerializedBattle`, `SerializedGoal`, `SerializedParticipant`, `normaliseDuration`, `readContextPair`, `serializeBattle`, `serializeGoal` |
| `lib/gift-engine.ts` | 506 | `ANIMATION_TYPES`, `DISPLAY_AREAS`, `GiftContext`, `PRIORITIES`, `SEAT_EFFECTS`, `buildGiftReceivedPayload`, `cleanupQueue`, `comboMilestone`, `computeCombo`, `emitGiftEngineEvent`, `enqueueGift`, `finishQueueEntry`, `getQueueSnapshot`, `processGiftSend`, `resolveAnimationType`, `resolveDisplayArea`, `resolveDurationMs`, `resolvePriority`, `resolveSeatEffect`, `resolveSoundEffect` |
| `lib/gift-insights.ts` | 363 | `GIFT_CONTEXTS`, `GIFT_SELECT`, `MissionDefinition`, `PERIODS`, `Period`, `PublicGift`, `PublicUser`, `SUPPORTER_TIERS`, `Scope`, `SupporterTier`, `USER_SELECT`, `activeMissions`, `buildSupporterBadge`, `clampLimit`, `dayStartUtc`, `displayAmount`, `displayNameOf`, `ledgerWhere`, `missionProgressForUser`, `normalizeContext`, `normalizePeriod`, `normalizeScope`, `periodStart`, `rewardOf` … |
| `lib/gift-media-probe.ts` | 71 | `generateVideoThumbnail` |
| `lib/gift-pk-score.ts` | 117 | `GiftPkScoreResult`, `applyGiftPkScore` |
| `lib/gift-render.ts` | 101 | `GiftRenderMeta`, `buildGiftRenderMeta` |
| `lib/idempotency.ts` | 172 | `IDEMPOTENCY_TTL_MS`, `IdempotencyOutcome`, `beginIdempotent`, `completeIdempotent`, `getIdempotencyKey`, `releaseIdempotent` |
| `lib/language-context.tsx` | 66 | `LanguageProvider`, `useLanguage` |
| `lib/leaderboard-engine.ts` | 469 | `LeaderboardScope`, `PeriodType`, `RewardConfigEntry`, `ScoringRules`, `distributeRewards`, `ensureDefaultConfigs`, `finalizeExpiredPeriods`, `getActiveConfigs`, `getConfig`, `getOrCreateCurrentPeriod`, `getTop100`, `incrementLeaderboardScore` |
| `lib/ledger.ts` | 238 | `AccountType`, `Currency`, `LedgerCategory`, `LedgerLeg`, `LedgerParams`, `getAccountLedger`, `getTransaction`, `recordLedger`, `recordMultiLeg` |
| `lib/llm.ts` | 65 | `callLLM` |
| `lib/media-url.ts` | 218 | `GiftMediaFields`, `computeGiftMediaFields`, `deriveAssetFormat`, `deriveMediaType`, `deriveMimeType`, `resolveMediaUrl`, `serializeGiftMedia` |
| `lib/mobile-auth.ts` | 101 | `AuthenticatedUser`, `MobileTokenPayload`, `authenticateRequest`, `generateMobileTokens`, `verifyMobileToken` |
| `lib/mp4-duration.ts` | 94 | `getMp4DurationSec` |
| `lib/music-permissions.ts` | 42 | `canControlMusic` |
| `lib/notify.ts` | 267 | `DEFAULT_DEDUPE_WINDOW_SECONDS`, `buildNotificationDedupeKey`, `createBulkNotificationsWithPush`, `createNotificationWithPush`, `resolveNotificationDeepLink` |
| `lib/onesignal-admin.ts` | 213 | `OneSignalSendResult`, `SendNotificationParams`, `cancelNotification`, `getAppStats`, `getNotificationDetails`, `sendNotification` |
| `lib/onesignal.ts` | 264 | `getNotificationTitle`, `getNotificationUrl`, `sendOneSignalPush`, `sendOneSignalPushToMany`, `sendPushToMultipleUsers`, `sendPushToUser` |
| `lib/pagination.ts` | 123 | `CursorParams`, `buildCursorMeta`, `cursorQuery`, `fetchCursorPage`, `isCursorMode`, `parseCursorParams`, `parseOffsetParams` |
| `lib/payment-status.ts` | 116 | `DEFAULT_ADMIN_NOTES`, `PAYMENT_METHOD_LABELS`, `PAYMENT_STATUS_COLORS`, `PAYMENT_STATUS_LABELS`, `PRODUCT_TYPE_LABELS`, `PaymentStatus`, `decoratePaymentNotification` |
| `lib/perf.ts` | 244 | `SLOW_THRESHOLD_MS`, `checkETag`, `getCachedAuth`, `getMonitoringSnapshot`, `recordTiming`, `setCachedAuth`, `withPerfHeaders`, `withTiming` |
| `lib/permissions.ts` | 254 | `PERMISSIONS`, `PERMISSION_GROUPS`, `PermissionDef`, `SYSTEM_ROLES`, `getRolePermissions`, `hasPermission`, `listRoles`, `setRolePermissions` |
| `lib/pk-expiry.ts` | 100 | `PK_TIMEOUT_MS`, `expireAllStalePKs`, `expirePendingPK` |
| `lib/pk-match.ts` | 126 | `PkMatch`, `loadPkUsers`, `mapPkStatus`, `serializePkMatch`, `serializePkMatches` |
| `lib/pk-state.ts` | 295 | `PK_STATE_ALIASES`, `PK_TERMINAL_STATUSES`, `PkStatus`, `abortPendingPk`, `checkPkTransition`, `computePkOutcome`, `emitPkToBothSides`, `endPksForSide`, `ensurePkSidesAlive`, `finalizeExpiredActivePKs`, `findBlockingPk`, `finishPkBattle` |
| `lib/presence-engine.ts` | 204 | `ONLINE_EVENT_COOLDOWN_MS`, `ONLINE_EVENT_FEED_WINDOW_MS`, `ONLINE_WINDOW_MS`, `PRESENCE_LABELS`, `PresenceStatus`, `cleanupOldOnlineEvents`, `computeTellerStatus`, `getRecentOnlineEvents`, `maybeEmitOnlineEntrance` |
| `lib/push-notifications.ts` | 156 | `getPermissionStatus`, `isPushSupported`, `playNotificationSound`, `registerServiceWorker`, `requestNotificationPermission`, `showBrowserNotification` |
| `lib/push.ts` | 59 | `PUSH_PROVIDER`, `UnifiedPushPayload`, `sendPush`, `sendPushBulk` |
| `lib/r2-storage.ts` | 179 | `PresignedUpload`, `UploadResult`, `buildPublicUrl`, `deleteFromR2`, `extractR2Key`, `getPresignedDownloadUrl`, `getPresignedUploadUrl`, `getPresignedUploadUrlForFile`, `isR2Key`, `uploadToR2` |
| `lib/rate-limit-guard.ts` | 144 | `DEFAULT_RATE_LIMITS`, `RateLimitOptions`, `getClientIp`, `guardRateLimit`, `resolveIdentity`, `resolveLimit` |
| `lib/rate-limiter.ts` | 74 | `apiLimiter`, `authLimiter`, `heavyLimiter`, `rateLimit` |
| `lib/rbac.ts` | 128 | `ResolvedUser`, `requireAdmin`, `requireAuth`, `requireFullAdmin`, `requireOwnerOrAdmin`, `requireRole`, `resolveUser` |
| `lib/referral-commission.ts` | 375 | `AGENCY_PAYOUT_BALANCE_FIELD`, `AGENCY_PAYOUT_CURRENCY`, `COMMISSION_PAYOUT_BALANCE_FIELD`, `COMMISSION_PAYOUT_CURRENCY`, `COMMISSION_SETTING_DEFAULTS`, `COMMISSION_SETTING_KEYS`, `COMMISSION_SETTING_LABELS`, `CommissionConfig`, `REFERRAL_PAYOUT_BALANCE_FIELD`, `REFERRAL_PAYOUT_CURRENCY`, `TopupCommissionInput`, `TopupCommissionResult`, `awardTopupCommissions`, `getCommissionConfig`, `getCommissionSummary`, `invalidateCommissionConfigCache`, `resolveAgencyPayout` |
| `lib/risk-score.ts` | 290 | `DEFAULT_RISK_RULES`, `RiskCategory`, `RiskInput`, `RiskLevel`, `RiskResult`, `RiskRules`, `RiskSignal`, `computeRiskScore`, `getRiskEvents`, `recordRiskEvent` |
| `lib/room-events.ts` | 104 | `clearRoomEvents`, `emitRoomEvent`, `emitTellerEvent`, `getRoomEventsSince`, `getTellerEventsSince` |
| `lib/rtc-telemetry.ts` | 417 | `DEFAULT_RTC_THRESHOLDS`, `RtcContext`, `RtcQualityLevel`, `RtcQualityResult`, `RtcTelemetryInput`, `RtcTelemetryQuery`, `RtcTelemetrySummary`, `RtcThresholds`, `computeRtcQuality`, `getRtcTelemetry`, `getRtcTelemetrySummary`, `recordRtcTelemetry` |
| `lib/s3.ts` | 104 | `deleteFile`, `generatePresignedUploadUrl`, `getFileUrl` |
| `lib/seo-config.ts` | 214 | `BLOG_POSTS`, `FORTUNE_SEO`, `SEO_PAGES`, `SITE_DESCRIPTION_EN`, `SITE_DESCRIPTION_TR`, `SITE_NAME`, `SITE_URL` |
| `lib/short-videos.ts` | 276 | `AuthorDTO`, `CreateShortVideoInput`, `createShortVideoRecord`, `mapAuthor`, `mapVideo`, `normalizeCommentSetting`, `normalizeVisibility`, `parseHashtags`, `parseMentions`, `safeFloat`, `safeInt`, `syncVideoHashtags`, `syncVideoMentions` |
| `lib/social-helper.ts` | 164 | `autoShareFortune` |
| `lib/speak-requests.ts` | 88 | `SpeakRequestDto`, `canModerateSpeakRequests`, `getActiveSpeakBlock`, `loadRequestUser`, `serializeSpeakRequest` |
| `lib/stream-auto-close.ts` | 98 | `closeStreamForMediaInactivity`, `getMediaInactivityTimeoutMs`, `sweepMediaInactiveStreams` |
| `lib/stream-events.ts` | 70 | `emitStreamEvent`, `getStreamEventsSince` |
| `lib/supporter-level.ts` | 65 | `SUPPORTER_TIERS`, `recordContribution`, `resolveTier` |
| `lib/team-points.ts` | 39 | `recordTeamPoints` |
| `lib/teller-levels.ts` | 74 | `LEVEL_LABELS_TR`, `LEVEL_ORDER`, `TELLER_LEVELS`, `TellerLevel`, `calculateLevelPoints`, `getLevelForPoints`, `getNextLevel`, `getProgressToNextLevel` |
| `lib/theme-context.tsx` | 82 | `ColorMode`, `SiteTheme`, `SiteThemeProvider`, `useSiteTheme` |
| `lib/tournament-state.ts` | 181 | `TERMINAL_STATUSES`, `TOURNAMENT_STATUSES`, `TournamentStatus`, `checkTournamentTransition`, `finalizeExpiredTournaments`, `getLeaderboard`, `incrementScore`, `joinTournament`, `snapshotRanks`, `transitionTournament`, `validateTournamentData` |
| `lib/trtc-client.ts` | 248 | `TRTCCredentials`, `TRTCRole`, `createTRTCInstance`, `destroyTRTC`, `enableAudioVolumeEvaluation`, `enterRoom`, `exitRoom`, `fetchTRTCCredentials`, `getCameraList`, `getMicrophoneList`, `getTRTCEvent`, `isSupported`, `muteLocalAudio`, `muteRemoteAudio`, `startLocalAudio`, `startLocalVideo`, `startRemoteVideo`, `stopLocalAudio`, `stopLocalVideo`, `stopRemoteVideo`, `switchRole`, `updateLocalVideo` |
| `lib/trtc-room.ts` | 31 | `userIdToNumericUid`, `voiceTrtcRoomId` |
| `lib/types.ts` | 55 | `Fortune`, `FortuneType`, `Translation` |
| `lib/ua-parser.ts` | 85 | `UAInfo`, `deviceEmoji`, `parseUserAgent` |
| `lib/utils.ts` | 28 | `cn`, `formatDuration`, `stripHtml` |
| `lib/voice-room-constants.ts` | 43 | `MAX_SEAT_INDEX`, `SEAT_COUNT`, `SEAT_STALE_MS`, `findFirstFreeSeat`, `seatStaleThreshold` |
| `lib/voice-room-events.ts` | 219 | `RoomEventKind`, `RoomEventPayload`, `SpeakRequestUser`, `emitHostChanged`, `emitMicChanged`, `emitOwnerChanged`, `emitPkInvite`, `emitRoomClosed`, `emitSeatChanged`, `emitUserJoined`, `emitUserLeft`, `emitVoiceRequest`, `emitVoiceRequestAccepted`, `emitVoiceRequestBlocked`, `emitVoiceRequestCancelled`, `emitVoiceRequestRejected`, `emitVoiceRequestUnblocked` |
| `lib/voice-room-gifts.ts` | 41 | `getReceivedJetonTotals` |
| `lib/voice-room-revenue.ts` | 167 | `ROOM_TYPES`, `RoomType`, `calculateGiftDistribution`, `calculateMusicDistribution`, `getMaxUsersForRoomType`, `logRoomRevenue`, `roomTypeSupports` |
| `lib/voice-room-seats.ts` | 278 | `DEFAULT_SEAT_COUNT`, `MAX_GUEST_SEATS`, `MAX_PRIVILEGED_SEATS`, `MAX_SEAT_COUNT`, `MIN_SEAT_COUNT`, `OWNER_SEAT_INDEX`, `PRIVILEGED_MIN_MEMBERSHIP`, `SEAT_SETTING_KEY`, `SeatComposition`, `SeatKind`, `SeatLayoutEntry`, `SeatState`, `SeatUserContext`, `buildSeatLayout`, `canSitOnSeat`, `canUsePrivilegedSeat`, `clampSeatCount`, `findFirstFreeSeatFor`, `getGlobalSeatCount`, `getSeatComposition`, `resolveRoomSeatCount`, `seatAuthorityWeight`, `seatKind` |
| `lib/webrtc-config.ts` | 678 | `AdaptiveBitrateManager`, `BITRATE_PRESETS`, `BitrateConfig`, `ICE_SERVERS`, `MAX_RECONNECT_ATTEMPTS`, `NetworkStats`, `RECONNECT_DELAY`, `SIMULCAST_ENCODINGS`, `TurnServerConfig`, `VideoQuality`, `addTrackWithSimulcast`, `applyInitialBitrate`, `getMediaConstraints`, `getNetworkStats`, `getRTCConfiguration`, `isMobileDevice`, `setAudioBitrate`, `setPreferredCodec`, `setVideoBitrate`, `setupConnectionRecovery` |