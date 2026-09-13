# CanlıFal — Veri Modelleri (Flutter için)

Toplam model: **268**

Skaler alanlar JSON olarak döner. `DateTime` alanlar ISO-8601 string olarak serileşir — Flutter'da `DateTime.parse()` kullanın. `Json` alanlar `dynamic`'tir.

## Account

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `type` | String | String | evet |  |
| `provider` | String | String | evet |  |
| `providerAccountId` | String | String | evet |  |
| `refresh_token` | String? | String? | hayır |  |
| `access_token` | String? | String? | hayır |  |
| `expires_at` | Int? | int? | hayır |  |
| `token_type` | String? | String? | hayır |  |
| `scope` | String? | String? | hayır |  |
| `id_token` | String? | String? | hayır |  |
| `session_state` | String? | String? | hayır |  |
| `user` | User | — | evet | ilişki |

## AccountDeletion

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet | unique |
| `originalEmail` | String? | String? | hayır |  |
| `originalUsername` | String? | String? | hayır |  |
| `reason` | String? | String? | hayır |  |
| `source` | String | String | hayır | default="mobile" |
| `status` | String | String | hayır | default="completed" |
| `requestedAt` | DateTime | DateTime | hayır | default=now( |
| `completedAt` | DateTime? | DateTime? | hayır |  |

## Achievement

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `code` | String | String | evet | unique |
| `nameTr` | String | String | evet |  |
| `nameEn` | String | String | evet |  |
| `descriptionTr` | String | String | evet |  |
| `descriptionEn` | String | String | evet |  |
| `icon` | String | String | evet |  |
| `category` | String | String | evet |  |
| `targetValue` | Int | int | evet |  |
| `rewardCredits` | Int | int | hayır | default=0 |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ActivityFeedConfig

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `isEnabled` | Boolean | bool | hayır | default=true |
| `maxItems` | Int | int | hayır | default=20 |
| `visibleToGuests` | Boolean | bool | hayır | default=true |
| `visibleToBasic` | Boolean | bool | hayır | default=true |
| `visibleToPremium` | Boolean | bool | hayır | default=true |
| `visibleToGold` | Boolean | bool | hayır | default=true |
| `visibleToDiamond` | Boolean | bool | hayır | default=true |
| `visibleToModerator` | Boolean | bool | hayır | default=true |
| `visibleToAdmin` | Boolean | bool | hayır | default=true |
| `specificUserIds` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## AdNetwork

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `provider` | String | String | evet | unique |
| `adCode` | String? | String? | hayır |  |
| `adUnitId` | String? | String? | hayır |  |
| `appId` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=false |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `placements` | AdPlacement[] | — | evet | ilişki |

## AdPlacement

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `placementKey` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `adNetworkId` | String? | String? | hayır |  |
| `adType` | String | String | hayır | default="banner" |
| `position` | String? | String? | hayır |  |
| `platform` | String | String | hayır | default="all" |
| `isActive` | Boolean | bool | hayır | default=false |
| `sortOrder` | Int | int | hayır | default=0 |
| `customCode` | String? | String? | hayır |  |
| `targeting` | Json? | dynamic? | hayır |  |
| `frequencyCap` | Int | int | hayır | default=0 |
| `impressions` | Int | int | hayır | default=0 |
| `clicks` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `adNetwork` | AdNetwork? | — | hayır | ilişki |

## AdminPopup

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `message` | String | String | evet |  |
| `buttons` | String | String | hayır | default="[]" |
| `isActive` | Boolean | bool | hayır | default=true |
| `showTo` | String | String | hayır | default="all" |
| `popupType` | String | String | hayır | default="custom" |
| `priority` | Int | int | hayır | default=0 |
| `maxShowCount` | Int | int | hayır | default=1 |
| `showOnRefresh` | Boolean | bool | hayır | default=false |
| `showDelaySeconds` | Int | int | hayır | default=1 |
| `lastSentAt` | DateTime | DateTime | hayır | default=now( |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## AdminUserAction

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `targetUserId` | String | String | evet |  |
| `targetUser` | User | — | evet | ilişki |
| `adminId` | String | String | evet |  |
| `adminName` | String? | String? | hayır |  |
| `action` | String | String | evet |  |
| `oldValue` | String? | String? | hayır |  |
| `newValue` | String? | String? | hayır |  |
| `reason` | String? | String? | hayır |  |
| `metadata` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## Agency

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet | unique |
| `description` | String? | String? | hayır |  |
| `ownerId` | String | String | evet |  |
| `ownerName` | String | String | evet |  |
| `status` | String | String | hayır | default="pending" |
| `commissionRate` | Float | double | hayır | default=5.0 |
| `contactEmail` | String? | String? | hayır |  |
| `contactPhone` | String? | String? | hayır |  |
| `logoUrl` | String? | String? | hayır |  |
| `totalEarnings` | Float | double | hayır | default=0 |
| `totalMembers` | Int | int | hayır | default=0 |
| `activeMembers` | Int | int | hayır | default=0 |
| `performanceScore` | Float | double | hayır | default=0 |
| `penaltyLevel` | Int | int | hayır | default=0 |
| `penaltyNote` | String? | String? | hayır |  |
| `invitesDisabled` | Boolean | bool | hayır | default=false |
| `level` | String | String | hayır | default="bronze" |
| `approvedAt` | DateTime? | DateTime? | hayır |  |
| `rejectedAt` | DateTime? | DateTime? | hayır |  |
| `rejectedReason` | String? | String? | hayır |  |
| `suspendedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `members` | AgencyUser[] | — | evet | ilişki |
| `earnings` | AgencyEarning[] | — | evet | ilişki |
| `inviteCodes` | InviteCode[] | — | evet | ilişki |
| `tasks` | AgencyTask[] | — | evet | ilişki |
| `penalties` | AgencyPenalty[] | — | evet | ilişki |
| `leaveRequests` | AgencyLeaveRequest[] | — | evet | ilişki |
| `wallet` | AgencyWallet? | — | hayır | ilişki |
| `walletTxns` | AgencyWalletTransaction[] | — | evet | ilişki |
| `commissionRules` | AgencyCommissionRule[] | — | evet | ilişki |

## AgencyBonusRule

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `level` | String | String | evet | unique |
| `label` | String | String | evet |  |
| `bonusRate` | Float | double | hayır | default=0 |
| `minMonthlyEarning` | Float | double | hayır | default=0 |
| `minActiveBroadcasters` | Int | int | hayır | default=0 |
| `minStreamMinutes` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## AgencyCommissionRule

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String? | String? | hayır |  |
| `sourceType` | String | String | evet |  |
| `enabled` | Boolean | bool | hayır | default=true |
| `rate` | Float? | double? | hayır |  |
| `note` | String? | String? | hayır |  |
| `updatedById` | String? | String? | hayır |  |
| `updatedByName` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `agency` | Agency? | — | hayır | ilişki |

## AgencyEarning

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `amount` | Float | double | evet |  |
| `sourceType` | String | String | evet |  |
| `sourceId` | String? | String? | hayır |  |
| `originalAmount` | Float | double | evet |  |
| `commissionRate` | Float | double | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `agency` | Agency | — | evet | ilişki |

## AgencyLeaveRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `reviewedBy` | String? | String? | hayır |  |
| `reviewNote` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `reviewedAt` | DateTime? | DateTime? | hayır |  |
| `agency` | Agency | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## AgencyPenalty

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `level` | Int | int | evet |  |
| `reason` | String | String | evet |  |
| `appliedBy` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `resolvedAt` | DateTime? | DateTime? | hayır |  |
| `resolvedBy` | String? | String? | hayır |  |
| `resolvedNote` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `agency` | Agency | — | evet | ilişki |

## AgencyTask

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `weekStart` | DateTime | DateTime | evet |  |
| `weekEnd` | DateTime | DateTime | evet |  |
| `earningsTarget` | Float | double | hayır | default=0 |
| `newUsersTarget` | Int | int | hayır | default=0 |
| `activeUsersTarget` | Int | int | hayır | default=0 |
| `earningsActual` | Float | double | hayır | default=0 |
| `newUsersActual` | Int | int | hayır | default=0 |
| `activeUsersActual` | Int | int | hayır | default=0 |
| `completionPercent` | Float | double | hayır | default=0 |
| `bonusAwarded` | Float | double | hayır | default=0 |
| `status` | String | String | hayır | default="active" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `agency` | Agency | — | evet | ilişki |

## AgencyUser

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `userId` | String | String | evet | unique |
| `role` | String | String | hayır | default="member" |
| `joinedVia` | String? | String? | hayır |  |
| `inviteCodeId` | String? | String? | hayır |  |
| `totalEarnings` | Float | double | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `leftAt` | DateTime? | DateTime? | hayır |  |
| `joinIp` | String? | String? | hayır |  |
| `joinDeviceId` | String? | String? | hayır |  |
| `agency` | Agency | — | evet | ilişki |
| `user` | User | — | evet | ilişki |
| `inviteCode` | InviteCode? | — | hayır | ilişki |

## AgencyWallet

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet | unique |
| `jetonBalance` | Float | double | hayır | default=0 |
| `totalTopUp` | Float | double | hayır | default=0 |
| `totalBonus` | Float | double | hayır | default=0 |
| `totalTransferred` | Float | double | hayır | default=0 |
| `totalAdjusted` | Float | double | hayır | default=0 |
| `isLocked` | Boolean | bool | hayır | default=false |
| `lockReason` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `agency` | Agency | — | evet | ilişki |

## AgencyWalletTransaction

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `type` | String | String | evet |  |
| `direction` | String | String | evet |  |
| `amount` | Float | double | evet |  |
| `balanceBefore` | Float | double | evet |  |
| `balanceAfter` | Float | double | evet |  |
| `tlAmount` | Float? | double? | hayır |  |
| `rateUsed` | Float? | double? | hayır |  |
| `bonusRate` | Float? | double? | hayır |  |
| `targetUserId` | String? | String? | hayır |  |
| `targetUserName` | String? | String? | hayır |  |
| `actorId` | String? | String? | hayır |  |
| `actorName` | String? | String? | hayır |  |
| `actorRole` | String? | String? | hayır |  |
| `reason` | String? | String? | hayır |  |
| `referenceType` | String? | String? | hayır |  |
| `referenceId` | String? | String? | hayır |  |
| `idempotencyKey` | String? | String? | hayır |  |
| `metadata` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `agency` | Agency | — | evet | ilişki |

## Animation

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `category` | String | String | evet |  |
| `type` | String | String | evet |  |
| `assetUrl` | String | String | evet |  |
| `thumbnailUrl` | String? | String? | hayır |  |
| `previewUrl` | String? | String? | hayır |  |
| `soundUrl` | String? | String? | hayır |  |
| `durationMs` | Int | int | hayır | default=3000 |
| `priority` | Int | int | hayır | default=10 |
| `status` | String | String | hayır | default="active" |
| `rarity` | String | String | hayır | default="normal" |
| `membershipLevel` | String? | String? | hayır |  |
| `contexts` | Json? | dynamic? | hayır |  |
| `position` | String | String | hayır | default="center" |
| `scale` | String | String | hayır | default="medium" |
| `anchor` | String | String | hayır | default="room" |
| `cooldownMs` | Int | int | hayır | default=0 |
| `canSkip` | Boolean | bool | hayır | default=true |
| `activeFrom` | DateTime? | DateTime? | hayır |  |
| `activeTo` | DateTime? | DateTime? | hayır |  |
| `legacyType` | String? | String? | hayır |  |
| `legacyRefId` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `assignments` | AnimationAssignment[] | — | evet | ilişki |
| `membershipDefaults` | AnimationMembershipDefault[] | — | evet | ilişki |
| `playbackLogs` | AnimationPlaybackLog[] | — | evet | ilişki |

## AnimationAssignment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `animationId` | String | String | evet |  |
| `assignmentType` | String | String | hayır | default="user_custom" |
| `context` | String? | String? | hayır |  |
| `category` | String? | String? | hayır |  |
| `startDate` | DateTime? | DateTime? | hayır |  |
| `endDate` | DateTime? | DateTime? | hayır |  |
| `priority` | Int | int | hayır | default=50 |
| `isActive` | Boolean | bool | hayır | default=true |
| `assignedBy` | String? | String? | hayır |  |
| `note` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `user` | User | — | evet | ilişki |
| `assigner` | User? | — | hayır | ilişki |
| `animation` | Animation | — | evet | ilişki |

## AnimationMembershipDefault

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `membershipTier` | String | String | evet |  |
| `category` | String | String | evet |  |
| `animationId` | String | String | evet |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `animation` | Animation | — | evet | ilişki |

## AnimationPlaybackLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String? | String? | hayır |  |
| `animationId` | String | String | evet |  |
| `roomId` | String? | String? | hayır |  |
| `context` | String? | String? | hayır |  |
| `playedAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User? | — | hayır | ilişki |
| `animation` | Animation | — | evet | ilişki |

## AnonymousFortune

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `anonymousUserId` | String | String | evet |  |
| `fortuneType` | String | String | evet |  |
| `inputData` | String | String | evet |  |
| `aiResponse` | String | String | evet |  |
| `language` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `anonymousUser` | AnonymousUser | — | evet | ilişki |

## AnonymousUser

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `username` | String | String | evet | unique |
| `deviceId` | String | String | evet | unique |
| `credits` | Int | int | hayır | default=0 |
| `adsWatched` | Int | int | hayır | default=0 |
| `adsWatchedToday` | Int | int | hayır | default=0 |
| `lastAdDate` | DateTime? | DateTime? | hayır |  |
| `fortunesUsed` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `anonymousFortunes` | AnonymousFortune[] | — | evet | ilişki |

## AuditLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `actorId` | String | String | evet |  |
| `actorRole` | String? | String? | hayır |  |
| `actorIp` | String? | String? | hayır |  |
| `action` | String | String | evet |  |
| `targetType` | String? | String? | hayır |  |
| `targetId` | String? | String? | hayır |  |
| `before` | Json? | dynamic? | hayır |  |
| `after` | Json? | dynamic? | hayır |  |
| `description` | String? | String? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## AvatarAccessory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `slot` | String | String | hayır | default="hat" |
| `assetUrl` | String | String | evet |  |
| `tier` | String | String | hayır | default="gold" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## BanaOzelHistory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `itemSlug` | String | String | evet |  |
| `content` | String | String | evet |  |
| `jetonSpent` | Int | int | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## BanaOzelItem

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `slug` | String | String | evet | unique |
| `nameTr` | String | String | evet |  |
| `nameEn` | String | String | evet |  |
| `descTr` | String? | String? | hayır |  |
| `descEn` | String? | String? | hayır |  |
| `icon` | String | String | evet |  |
| `jetonCost` | Int | int | hayır | default=5 |
| `category` | String | String | hayır | default="fortune" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `contentPool` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## BlogCategory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `slug` | String | String | evet | unique |
| `nameTr` | String | String | evet |  |
| `nameEn` | String | String | hayır | default="" |
| `descTr` | String | String | hayır | default="" |
| `descEn` | String | String | hayır | default="" |
| `icon` | String | String | hayır | default="BookOpen" |
| `color` | String | String | hayır | default="#8B5CF6" |
| `coverImage` | String | String | hayır | default="" |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `postCount` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## BlogComment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | hayır | default="Anonim" |
| `userAvatar` | String | String | hayır | default="" |
| `content` | String | String | evet |  |
| `isApproved` | Boolean | bool | hayır | default=true |
| `likes` | Int | int | hayır | default=0 |
| `parentId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## BlogFavorite

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## BlogLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## BlogPost

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `slug` | String | String | evet | unique |
| `titleTr` | String | String | evet |  |
| `titleEn` | String | String | hayır | default="" |
| `descTr` | String | String | evet |  |
| `descEn` | String | String | hayır | default="" |
| `contentTr` | String | String | evet |  |
| `contentEn` | String | String | hayır | default="" |
| `category` | String | String | hayır | default="genel" |
| `keywords` | String[] | List<String> | hayır | default=[] |
| `metaDescription` | String | String | hayır | default="" |
| `coverImage` | String | String | hayır | default="" |
| `readTime` | Int | int | hayır | default=5 |
| `views` | Int | int | hayır | default=0 |
| `likes` | Int | int | hayır | default=0 |
| `isPublished` | Boolean | bool | hayır | default=false |
| `isFeatured` | Boolean | bool | hayır | default=false |
| `isTrending` | Boolean | bool | hayır | default=false |
| `isEditorPick` | Boolean | bool | hayır | default=false |
| `isAiGenerated` | Boolean | bool | hayır | default=false |
| `isPremium` | Boolean | bool | hayır | default=false |
| `zodiacSign` | String | String | hayır | default="" |
| `authorId` | String? | String? | hayır |  |
| `authorName` | String | String | hayır | default="Canlifal Editör" |
| `publishedAt` | DateTime? | DateTime? | hayır |  |
| `scheduledAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## BotProfile

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet | unique |
| `user` | User | — | evet | ilişki |
| `personality` | String | String | evet |  |
| `age` | Int | int | evet |  |
| `city` | String | String | evet |  |
| `interests` | String? | String? | hayır |  |
| `activityLevel` | String | String | hayır | default="medium" |
| `activeHoursStart` | Int | int | hayır | default=9 |
| `activeHoursEnd` | Int | int | hayır | default=23 |
| `isActive` | Boolean | bool | hayır | default=true |
| `lastActionAt` | DateTime? | DateTime? | hayır |  |
| `totalActions` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## BroadcastImage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `imageUrl` | String | String | evet |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## Celebrity

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `category` | String | String | evet |  |
| `bio` | String? | String? | hayır |  |
| `profileImage` | String? | String? | hayır |  |
| `coverImage` | String? | String? | hayır |  |
| `isVerified` | Boolean | bool | hayır | default=true |
| `isActive` | Boolean | bool | hayır | default=true |
| `followerCount` | Int | int | hayır | default=0 |
| `birthDate` | DateTime? | DateTime? | hayır |  |
| `birthPlace` | String? | String? | hayır |  |
| `zodiacSign` | String? | String? | hayır |  |
| `socialLinks` | String? | String? | hayır |  |
| `achievements` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `followers` | CelebrityFollow[] | — | evet | ilişki |
| `fanClub` | FanClub? | — | hayır | ilişki |
| `posts` | CelebrityPost[] | — | evet | ilişki |

## CelebrityFollow

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `celebrityId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |
| `celebrity` | Celebrity | — | evet | ilişki |

## CelebrityPost

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `celebrityId` | String | String | evet |  |
| `celebrity` | Celebrity | — | evet | ilişki |
| `platform` | String | String | evet |  |
| `postType` | String | String | hayır | default="photo" |
| `content` | String? | String? | hayır |  |
| `mediaUrl` | String? | String? | hayır |  |
| `externalUrl` | String? | String? | hayır |  |
| `likeCount` | Int | int | hayır | default=0 |
| `commentCount` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `isPinned` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `likes` | CelebrityPostLike[] | — | evet | ilişki |
| `comments` | CelebrityPostComment[] | — | evet | ilişki |

## CelebrityPostComment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `content` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `post` | CelebrityPost | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## CelebrityPostLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `post` | CelebrityPost | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## CfcContest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `description` | String? | String? | hayır |  |
| `type` | String | String | evet |  |
| `scope` | String | String | hayır | default="general" |
| `status` | String | String | hayır | default="draft" |
| `seasonId` | String? | String? | hayır |  |
| `season` | CfcSeason? | — | hayır | ilişki |
| `scoringMetrics` | String | String | evet |  |
| `commissionRate` | Float? | double? | hayır |  |
| `rules` | String? | String? | hayır |  |
| `minParticipants` | Int | int | hayır | default=2 |
| `maxParticipants` | Int? | int? | hayır |  |
| `entryRequirements` | String? | String? | hayır |  |
| `startsAt` | DateTime? | DateTime? | hayır |  |
| `endsAt` | DateTime? | DateTime? | hayır |  |
| `registrationEndsAt` | DateTime? | DateTime? | hayır |  |
| `rewards` | String? | String? | hayır |  |
| `createdBy` | String? | String? | hayır |  |
| `isPublic` | Boolean | bool | hayır | default=true |
| `isFeatured` | Boolean | bool | hayır | default=false |
| `bannerImage` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `participants` | CfcParticipant[] | — | evet | ilişki |
| `teams` | CfcTeam[] | — | evet | ilişki |
| `scoreLogs` | CfcScoreLog[] | — | evet | ilişki |

## CfcParticipant

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `contestId` | String | String | evet |  |
| `contest` | CfcContest | — | evet | ilişki |
| `userId` | String? | String? | hayır |  |
| `agencyId` | String? | String? | hayır |  |
| `roomId` | String? | String? | hayır |  |
| `teamId` | String? | String? | hayır |  |
| `team` | CfcTeam? | — | hayır | ilişki |
| `displayName` | String? | String? | hayır |  |
| `score` | Float | double | hayır | default=0 |
| `rank` | Int? | int? | hayır |  |
| `status` | String | String | hayır | default="active" |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## CfcPaymentRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `amount` | Int | int | evet |  |
| `method` | String | String | evet |  |
| `senderInfo` | String? | String? | hayır |  |
| `notes` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `reviewedBy` | String? | String? | hayır |  |
| `reviewNote` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## CfcScoreLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `contestId` | String | String | evet |  |
| `contest` | CfcContest | — | evet | ilişki |
| `userId` | String? | String? | hayır |  |
| `agencyId` | String? | String? | hayır |  |
| `roomId` | String? | String? | hayır |  |
| `metric` | String | String | evet |  |
| `delta` | Float | double | evet |  |
| `reason` | String? | String? | hayır |  |
| `calculatedAt` | DateTime | DateTime | hayır | default=now( |

## CfcSeason

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `description` | String? | String? | hayır |  |
| `startsAt` | DateTime? | DateTime? | hayır |  |
| `endsAt` | DateTime? | DateTime? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `contests` | CfcContest[] | — | evet | ilişki |

## CfcTeam

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `contestId` | String | String | evet |  |
| `contest` | CfcContest | — | evet | ilişki |
| `name` | String | String | evet |  |
| `color` | String? | String? | hayır |  |
| `badgeEmoji` | String? | String? | hayır |  |
| `captainId` | String? | String? | hayır |  |
| `totalScore` | Float | double | hayır | default=0 |
| `rank` | Int? | int? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `members` | CfcParticipant[] | — | evet | ilişki |

## ChatBan

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `bannedBy` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `banner` | User | — | evet | ilişki |
| `room` | ChatRoom | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## ChatBubbleSkin

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `assetUrl` | String | String | evet |  |
| `tier` | String | String | hayır | default="gold" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## ChatMessage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `content` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `room` | ChatRoom | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## ChatMute

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `mutedBy` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `muter` | User | — | evet | ilişki |
| `room` | ChatRoom | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## ChatPresence

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `nickname` | String? | String? | hayır |  |
| `isTyping` | Boolean | bool | hayır | default=false |
| `lastTyping` | DateTime? | DateTime? | hayır |  |
| `lastSeen` | DateTime | DateTime | hayır | default=now( |
| `seatIndex` | Int | int | hayır | default=-1 |
| `room` | ChatRoom | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## ChatRoom

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `slug` | String | String | evet | unique |
| `nameEn` | String | String | evet |  |
| `nameTr` | String | String | evet |  |
| `descEn` | String | String | evet |  |
| `descTr` | String | String | evet |  |
| `icon` | String | String | evet |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `isMuted` | Boolean | bool | hayır | default=false |
| `ownerId` | String? | String? | hayır |  |
| `owner` | User? | — | hayır | ilişki |
| `giftCommissionPercent` | Int | int | hayır | default=0 |
| `giftBeneficiaryId` | String? | String? | hayır |  |
| `giftBeneficiary` | User? | — | hayır | ilişki |
| `backgroundImage` | String? | String? | hayır |  |
| `bannedWords` | String? | String? | hayır |  |
| `currentMusicVideoId` | String? | String? | hayır |  |
| `currentMusicTitle` | String? | String? | hayır |  |
| `currentMusicStartedAt` | DateTime? | DateTime? | hayır |  |
| `currentMusicDuration` | String? | String? | hayır |  |
| `djUserIds` | String? | String? | hayır |  |
| `activeDjId` | String? | String? | hayır |  |
| `whitelistedWords` | String? | String? | hayır |  |
| `roomType` | String | String | hayır | default="FREE" |
| `password` | String? | String? | hayır |  |
| `welcomeMessage` | String? | String? | hayır |  |
| `pinnedAnnouncement` | String? | String? | hayır |  |
| `tags` | String? | String? | hayır |  |
| `bannerImage` | String? | String? | hayır |  |
| `seatCount` | Int? | int? | hayır |  |
| `minMembershipTier` | String? | String? | hayır |  |
| `showVipEntranceFx` | Boolean | bool | hayır | default=true |
| `isVipLounge` | Boolean | bool | hayır | default=false |
| `vipThemeId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `bans` | ChatBan[] | — | evet | ilişki |
| `messages` | ChatMessage[] | — | evet | ilişki |
| `mutes` | ChatMute[] | — | evet | ilişki |
| `presences` | ChatPresence[] | — | evet | ilişki |
| `userRoles` | ChatUserRole[] | — | evet | ilişki |
| `chatGifts` | ChatRoomGift[] | — | evet | ilişki |
| `revenueLogs` | RoomRevenueLog[] | — | evet | ilişki |

## ChatRoomGift

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `recipientId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `totalPrice` | Int | int | evet |  |
| `currencyType` | String | String | hayır | default="jeton" |
| `commissionAmount` | Int | int | hayır | default=0 |
| `beneficiaryId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `room` | ChatRoom | — | evet | ilişki |
| `sender` | User | — | evet | ilişki |
| `recipient` | User | — | evet | ilişki |
| `giftType` | GiftType | — | evet | ilişki |

## ChatSpeakBlock

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `blockedBy` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ChatSpeakRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `status` | String | String | hayır | default="pending" |
| `message` | String? | String? | hayır |  |
| `reason` | String? | String? | hayır |  |
| `handledBy` | String? | String? | hayır |  |
| `handledAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## ChatUserRole

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `role` | String | String | evet |  |
| `grantedBy` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `room` | ChatRoom | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## Conversation

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `user1Id` | String | String | evet |  |
| `user2Id` | String | String | evet |  |
| `lastMessageAt` | DateTime | DateTime | hayır | default=now( |
| `lastMessageText` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user1` | User | — | evet | ilişki |
| `user2` | User | — | evet | ilişki |

## CreditPackage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String? | String? | hayır |  |
| `credits` | Int | int | evet |  |
| `price` | Float | double | evet |  |
| `currency` | String | String | hayır | default="TRY" |
| `stripePriceId` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `isFeatured` | Boolean | bool | hayır | default=false |
| `bonusCredits` | Int | int | hayır | default=0 |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `payments` | Payment[] | — | evet | ilişki |

## CreditTransaction

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `amount` | Int | int | evet |  |
| `type` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `relatedId` | String? | String? | hayır |  |
| `balance` | Int | int | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## CurrencyConfig

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `area` | String | String | evet | unique |
| `areaName` | String | String | evet |  |
| `currencyType` | String | String | hayır | default="cfc" |
| `cost` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## CustomBadge

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `icon` | String | String | evet |  |
| `color` | String | String | hayır | default="#fbbf24" |
| `bgColor` | String | String | hayır | default="#78350f" |
| `description` | String? | String? | hayır |  |
| `tier` | String? | String? | hayır |  |
| `userId` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## DailyLoginReward

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `rewardDate` | DateTime | DateTime | evet |  |
| `streak` | Int | int | hayır | default=1 |
| `xpEarned` | Int | int | hayır | default=10 |
| `jetonEarned` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## DailyQuest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `questDate` | DateTime | DateTime | evet |  |
| `questType` | String | String | evet |  |
| `progress` | Int | int | hayır | default=0 |
| `target` | Int | int | hayır | default=1 |
| `reward` | Int | int | hayır | default=10 |
| `claimed` | Boolean | bool | hayır | default=false |
| `claimedAt` | DateTime? | DateTime? | hayır |  |

## DailyReward

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `rewardDate` | DateTime | DateTime | evet |  |
| `streak` | Int | int | hayır | default=1 |
| `jetonReward` | Int | int | hayır | default=5 |
| `claimedAt` | DateTime | DateTime | hayır | default=now( |

## DailyTask

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `taskType` | String | String | evet |  |
| `completedAt` | DateTime | DateTime | hayır | default=now( |
| `jetonEarned` | Int | int | hayır | default=0 |
| `date` | DateTime | DateTime | evet |  |

## DirectMessage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `content` | String | String | evet |  |
| `imageUrl` | String? | String? | hayır |  |
| `isRead` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `sender` | User | — | evet | ilişki |
| `receiver` | User | — | evet | ilişki |

## DreamComment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `content` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `dreamId` | String | String | evet |  |
| `experienceType` | String | String | hayır | default="yorum" |
| `didComeTrue` | Boolean? | bool? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `user` | User | — | evet | ilişki |
| `dream` | DreamInterpretation | — | evet | ilişki |

## DreamContest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `description` | String | String | evet |  |
| `dreamPrompt` | String | String | evet |  |
| `startDate` | DateTime | DateTime | evet |  |
| `endDate` | DateTime | DateTime | evet |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `entries` | DreamContestEntry[] | — | evet | ilişki |

## DreamContestEntry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `contestId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `interpretation` | String | String | evet |  |
| `voteCount` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `contest` | DreamContest | — | evet | ilişki |
| `user` | User | — | evet | ilişki |
| `votes` | DreamContestVote[] | — | evet | ilişki |

## DreamContestVote

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `entryId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `entry` | DreamContestEntry | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## DreamDiaryEntry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `dreamDate` | DateTime | DateTime | evet |  |
| `title` | String | String | evet |  |
| `content` | String | String | evet |  |
| `symbols` | String[] | List<String> | hayır | default=[] |
| `mood` | String? | String? | hayır |  |
| `lucidity` | Int? | int? | hayır |  |
| `aiAnalysis` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `user` | User | — | evet | ilişki |

## DreamFavorite

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `dreamId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |
| `dream` | DreamInterpretation | — | evet | ilişki |

## DreamInterpretation

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `content` | String | String | evet |  |
| `summary` | String? | String? | hayır |  |
| `keywords` | String[] | List<String> | hayır | default=[] |
| `metaDescription` | String? | String? | hayır |  |
| `category` | String | String | hayır | default="genel" |
| `views` | Int | int | hayır | default=0 |
| `isPublished` | Boolean | bool | hayır | default=true |
| `isAiGenerated` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `comments` | DreamComment[] | — | evet | ilişki |
| `favorites` | DreamFavorite[] | — | evet | ilişki |
| `dreamViews` | DreamView[] | — | evet | ilişki |

## DreamSymbol

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet | unique |
| `slug` | String | String | evet | unique |
| `letter` | String | String | evet |  |
| `meaning` | String | String | evet |  |
| `detailedMeaning` | String? | String? | hayır |  |
| `relatedSymbols` | String[] | List<String> | hayır | default=[] |
| `isPublished` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## DreamView

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `dreamId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |
| `dream` | DreamInterpretation | — | evet | ilişki |

## EffectRule

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `effectType` | String | String | evet |  |
| `effectRefId` | String? | String? | hayır |  |
| `conditionType` | String | String | evet |  |
| `threshold` | Int | int | hayır | default=0 |
| `conditionValue` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `priority` | Int | int | hayır | default=0 |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## EmailVerificationToken

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `email` | String | String | evet |  |
| `token` | String | String | evet | unique |
| `expiresAt` | DateTime | DateTime | evet |  |
| `used` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## EmojiPack

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `coverUrl` | String | String | evet |  |
| `emojis` | String | String | evet |  |
| `tier` | String | String | hayır | default="gold" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## EntranceEffect

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `assetUrl` | String | String | evet |  |
| `assetType` | String | String | hayır | default="lottie" |
| `tier` | String | String | hayır | default="gold" |
| `durationMs` | Int | int | hayır | default=3000 |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `activeFrom` | DateTime? | DateTime? | hayır |  |
| `activeTo` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## FanClub

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `celebrityId` | String | String | evet | unique |
| `celebrity` | Celebrity | — | evet | ilişki |
| `description` | String? | String? | hayır |  |
| `rules` | String? | String? | hayır |  |
| `coverImage` | String? | String? | hayır |  |
| `memberCount` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `members` | FanClubMember[] | — | evet | ilişki |
| `posts` | FanClubPost[] | — | evet | ilişki |
| `polls` | FanClubPoll[] | — | evet | ilişki |

## FanClubMember

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `fanClubId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `role` | String | String | hayır | default="member" |
| `xp` | Int | int | hayır | default=0 |
| `level` | String | String | hayır | default="yeni_fan" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `fanClub` | FanClub | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## FanClubPoll

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `fanClubId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `question` | String | String | evet |  |
| `options` | Json | dynamic | evet |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `endsAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `fanClub` | FanClub | — | evet | ilişki |
| `user` | User | — | evet | ilişki |
| `votes` | FanClubPollVote[] | — | evet | ilişki |

## FanClubPollVote

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `pollId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `optionIndex` | Int | int | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `poll` | FanClubPoll | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## FanClubPost

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `fanClubId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `content` | String | String | evet |  |
| `image` | String? | String? | hayır |  |
| `likeCount` | Int | int | hayır | default=0 |
| `isPinned` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `fanClub` | FanClub | — | evet | ilişki |
| `user` | User | — | evet | ilişki |
| `likes` | FanClubPostLike[] | — | evet | ilişki |

## FanClubPostLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `post` | FanClubPost | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## FavoriteTeller

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `tellerId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## FeatureFlag

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `enabled` | Boolean | bool | hayır | default=false |
| `description` | String? | String? | hayır |  |
| `platform` | String | String | hayır | default="all" |
| `percentage` | Int | int | hayır | default=100 |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## Follow

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `followerId` | String | String | evet |  |
| `followingId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `follower` | User | — | evet | ilişki |
| `following` | User | — | evet | ilişki |

## Fortune

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `fortuneType` | String | String | evet |  |
| `inputData` | String | String | evet |  |
| `aiResponse` | String | String | evet |  |
| `language` | String | String | evet |  |
| `viewCount` | Int | int | hayır | default=0 |
| `isSaved` | Boolean | bool | hayır | default=false |
| `isPinned` | Boolean | bool | hayır | default=false |
| `pinnedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |
| `socialPosts` | SocialPost[] | — | evet | ilişki |

## FortuneRating

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `fortuneId` | String | String | evet | unique |
| `userId` | String | String | evet |  |
| `satisfaction` | Int? | int? | hayır |  |
| `accuracy` | Int? | int? | hayır |  |
| `feedback` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## FortuneRequestType

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String | String | evet |  |
| `icon` | String | String | hayır | default="☕" |
| `jetonCost` | Int | int | evet |  |
| `description` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `fortuneRequests` | StreamFortuneRequest[] | — | evet | ilişki |

## GamePlay

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `gameId` | String | String | evet |  |
| `reward` | Int | int | hayır | default=0 |
| `score` | Int? | int? | hayır |  |
| `result` | String? | String? | hayır |  |
| `playedAt` | DateTime | DateTime | hayır | default=now( |
| `game` | MiniGame | — | evet | ilişki |

## GameRoom

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `gameType` | String | String | evet |  |
| `player1Id` | String | String | evet |  |
| `player2Id` | String? | String? | hayır |  |
| `isAI` | Boolean | bool | hayır | default=false |
| `betAmount` | Int | int | hayır | default=0 |
| `betCurrency` | String | String | hayır | default="FREE" |
| `state` | String | String | hayır | default="{}" |
| `currentTurn` | Int | int | hayır | default=1 |
| `player1Score` | Int | int | hayır | default=0 |
| `player2Score` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="waiting" |
| `winnerId` | String? | String? | hayır |  |
| `player1Name` | String | String | hayır | default="Oyuncu 1" |
| `player2Name` | String | String | hayır | default="Oyuncu 2" |
| `turnTimer` | Int | int | hayır | default=0 |
| `chatEnabled` | Boolean | bool | hayır | default=true |
| `lastMoveAt` | DateTime? | DateTime? | hayır |  |
| `disconnectedPlayerId` | String? | String? | hayır |  |
| `player1LastSeen` | DateTime? | DateTime? | hayır |  |
| `player2LastSeen` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `chatMessages` | GameRoomChat[] | — | evet | ilişki |
| `viewers` | GameRoomViewer[] | — | evet | ilişki |

## GameRoomChat

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | evet |  |
| `message` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `room` | GameRoom | — | evet | ilişki |

## GameRoomViewer

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | evet |  |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `room` | GameRoom | — | evet | ilişki |

## GiftBattle

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `context` | String | String | evet |  |
| `contextId` | String | String | evet |  |
| `createdById` | String | String | evet |  |
| `status` | String | String | hayır | default="active" |
| `durationSec` | Int | int | hayır | default=180 |
| `startedAt` | DateTime | DateTime | hayır | default=now( |
| `endsAt` | DateTime | DateTime | evet |  |
| `winnerId` | String? | String? | hayır |  |
| `totalScore` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `participants` | GiftBattleParticipant[] | — | evet | ilişki |

## GiftBattleParticipant

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `battleId` | String | String | evet |  |
| `battle` | GiftBattle | — | evet | ilişki |
| `participantId` | String | String | evet |  |
| `displayName` | String? | String? | hayır |  |
| `score` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## GiftBox

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `scope` | String | String | hayır | default="stream" |
| `streamId` | String? | String? | hayır |  |
| `roomId` | String? | String? | hayır |  |
| `creatorId` | String | String | evet |  |
| `totalAmount` | Int | int | evet |  |
| `winnerCount` | Int | int | evet |  |
| `durationSec` | Int | int | evet |  |
| `splits` | String | String | evet |  |
| `taskType` | String | String | hayır | default="none" |
| `taskTargetUserId` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="active" |
| `startsAt` | DateTime | DateTime | hayır | default=now( |
| `endsAt` | DateTime | DateTime | evet |  |
| `finishedAt` | DateTime? | DateTime? | hayır |  |
| `settledAt` | DateTime? | DateTime? | hayır |  |
| `refundedAmount` | Int | int | hayır | default=0 |
| `paidCount` | Int | int | hayır | default=0 |
| `paidAmount` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `entries` | GiftBoxEntry[] | — | evet | ilişki |

## GiftBoxEntry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `boxId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `taskVerified` | Boolean | bool | hayır | default=false |
| `isWinner` | Boolean | bool | hayır | default=false |
| `rewardAmount` | Int | int | hayır | default=0 |
| `rank` | Int? | int? | hayır |  |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `box` | GiftBox | — | evet | ilişki |

## GiftCollection

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String | String | hayır | default="" |
| `slug` | String | String | evet | unique |
| `description` | String? | String? | hayır |  |
| `iconEmoji` | String? | String? | hayır |  |
| `iconUrl` | String? | String? | hayır |  |
| `iconCloudPath` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | hayır | default=now( |
| `gifts` | GiftType[] | — | evet | ilişki |

## GiftCombo

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `context` | String | String | evet |  |
| `contextId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `receiverId` | String? | String? | hayır |  |
| `comboCount` | Int | int | hayır | default=1 |
| `lastSentAt` | DateTime | DateTime | hayır | default=now( |
| `expiresAt` | DateTime | DateTime | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## GiftEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `idempotencyKey` | String? | String? | hayır | unique |
| `giftTypeId` | String | String | evet |  |
| `giftType` | GiftType | — | evet | ilişki |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `context` | String | String | evet |  |
| `contextId` | String? | String? | hayır |  |
| `quantity` | Int | int | hayır | default=1 |
| `grossAmount` | Int | int | evet |  |
| `siteAmount` | Int | int | hayır | default=0 |
| `receiverAmount` | Int | int | hayır | default=0 |
| `ownerAmount` | Int | int | hayır | default=0 |
| `ownerId` | String? | String? | hayır |  |
| `recipientIsOwner` | Boolean | bool | hayır | default=false |
| `senderCity` | String? | String? | hayır |  |
| `senderCountry` | String? | String? | hayır |  |
| `battleId` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="completed" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## GiftGoal

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `context` | String | String | evet |  |
| `contextId` | String | String | evet |  |
| `ownerId` | String | String | evet |  |
| `title` | String? | String? | hayır |  |
| `targetAmount` | Int | int | evet |  |
| `currentAmount` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="active" |
| `startedAt` | DateTime | DateTime | hayır | default=now( |
| `completedAt` | DateTime? | DateTime? | hayır |  |

## GiftHistory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `context` | String | String | evet |  |
| `contextId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `combo` | Int | int | hayır | default=1 |
| `priority` | String | String | hayır | default="MEDIUM" |
| `coinAmount` | Int | int | hayır | default=0 |
| `animationType` | String? | String? | hayır |  |
| `displayArea` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## GiftMission

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `code` | String | String | evet | unique |
| `title` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `type` | String | String | evet |  |
| `target` | Int | int | hayır | default=1 |
| `context` | String? | String? | hayır |  |
| `rewardJetons` | Int | int | hayır | default=0 |
| `rewardCredits` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## GiftQueue

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `context` | String | String | evet |  |
| `contextId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `combo` | Int | int | hayır | default=1 |
| `priority` | String | String | hayır | default="MEDIUM" |
| `durationMs` | Int | int | hayır | default=3000 |
| `displayArea` | String | String | hayır | default="CENTER" |
| `status` | String | String | hayır | default="pending" |
| `queueIndex` | Int | int | hayır | default=0 |
| `payload` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `playedAt` | DateTime? | DateTime? | hayır |  |
| `finishedAt` | DateTime? | DateTime? | hayır |  |

## GiftType

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String | String | evet |  |
| `icon` | String | String | evet |  |
| `animation` | String? | String? | hayır |  |
| `price` | Int | int | evet |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `thumbnailUrl` | String? | String? | hayır |  |
| `assetUrl` | String? | String? | hayır |  |
| `assetType` | String? | String? | hayır | default="image" |
| `cloudStoragePath` | String? | String? | hayır |  |
| `thumbnailCloudPath` | String? | String? | hayır |  |
| `assetWidth` | Int? | int? | hayır |  |
| `assetHeight` | Int? | int? | hayır |  |
| `assetDurationMs` | Int? | int? | hayır |  |
| `assetMimeType` | String? | String? | hayır |  |
| `category` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `updatedAt` | DateTime | DateTime | hayır | default=now( |
| `soundUrl` | String? | String? | hayır |  |
| `soundCloudPath` | String? | String? | hayır |  |
| `animationDurationMs` | Int? | int? | hayır |  |
| `isFullscreen` | Boolean | bool | hayır | default=false |
| `tier` | String | String | hayır | default="small" |
| `isPopular` | Boolean | bool | hayır | default=false |
| `isNew` | Boolean | bool | hayır | default=false |
| `isSpecialEvent` | Boolean | bool | hayır | default=false |
| `isHidden` | Boolean | bool | hayır | default=false |
| `seasonStart` | DateTime? | DateTime? | hayır |  |
| `seasonEnd` | DateTime? | DateTime? | hayır |  |
| `isFeatured` | Boolean | bool | hayır | default=false |
| `firstReleasedAt` | DateTime? | DateTime? | hayır |  |
| `iconImageUrl` | String? | String? | hayır |  |
| `iconImageCloudPath` | String? | String? | hayır |  |
| `effectColor` | String? | String? | hayır |  |
| `comboEnabled` | Boolean | bool | hayır | default=false |
| `isPremium` | Boolean | bool | hayır | default=false |
| `visibleInVoiceRoom` | Boolean | bool | hayır | default=true |
| `visibleInLiveStream` | Boolean | bool | hayır | default=true |
| `visibleInPK` | Boolean | bool | hayır | default=true |
| `visibleInProfile` | Boolean | bool | hayır | default=false |
| `visibleInMessaging` | Boolean | bool | hayır | default=false |
| `visibleInTrend` | Boolean | bool | hayır | default=false |
| `visibleInStories` | Boolean | bool | hayır | default=false |
| `visibleInFortune` | Boolean | bool | hayır | default=false |
| `visibleInNotification` | Boolean | bool | hayır | default=false |
| `visibleAsMini` | Boolean | bool | hayır | default=false |
| `visibleAsFullscreen` | Boolean | bool | hayır | default=false |
| `displayType` | String | String | hayır | default="static" |
| `requiresVip` | Boolean | bool | hayır | default=false |
| `eventOnly` | Boolean | bool | hayır | default=false |
| `pkOnly` | Boolean | bool | hayır | default=false |
| `liveOnly` | Boolean | bool | hayır | default=false |
| `voiceOnly` | Boolean | bool | hayır | default=false |
| `newUserOnly` | Boolean | bool | hayır | default=false |
| `timedCampaign` | Boolean | bool | hayır | default=false |
| `campaignStart` | DateTime? | DateTime? | hayır |  |
| `campaignEnd` | DateTime? | DateTime? | hayır |  |
| `isSeasonal` | Boolean | bool | hayır | default=false |
| `isReusable` | Boolean | bool | hayır | default=true |
| `dailySendLimit` | Int? | int? | hayır |  |
| `startDelayMs` | Int? | int? | hayır |  |
| `displayDurationMs` | Int? | int? | hayır |  |
| `repeatCount` | Int | int | hayır | default=1 |
| `volume` | Int | int | hayır | default=100 |
| `particleEffect` | String? | String? | hayır |  |
| `hasVibration` | Boolean | bool | hayır | default=false |
| `hasColorChange` | Boolean | bool | hayır | default=false |
| `screenPosition` | String | String | hayır | default="center" |
| `animStartPoint` | String? | String? | hayır |  |
| `animEndPoint` | String? | String? | hayır |  |
| `collectionId` | String? | String? | hayır |  |
| `collection` | GiftCollection? | — | hayır | ilişki |
| `musicUrl` | String? | String? | hayır |  |
| `musicCloudPath` | String? | String? | hayır |  |
| `isLucky` | Boolean | bool | hayır | default=false |
| `priority` | String | String | hayır | default="MEDIUM" |
| `animationType` | String? | String? | hayır |  |
| `displayArea` | String? | String? | hayır |  |
| `seatEffect` | String? | String? | hayır |  |
| `seatEffectEnabled` | Boolean | bool | hayır | default=true |
| `soundEffectEnabled` | Boolean | bool | hayır | default=true |
| `comboWindowMs` | Int | int | hayır | default=4000 |
| `contentVersion` | Int | int | hayır | default=1 |
| `gifts` | StreamGift[] | — | evet | ilişki |
| `chatRoomGifts` | ChatRoomGift[] | — | evet | ilişki |
| `giftEvents` | GiftEvent[] | — | evet | ilişki |

## Hashtag

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet | unique |
| `videosCount` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `videos` | ShortVideoHashtag[] | — | evet | ilişki |

## HomepageButton

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `label` | String | String | evet |  |
| `icon` | String | String | hayır | default="🔗" |
| `href` | String | String | evet |  |
| `isVisible` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `specialBehavior` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## HomepageFortuneCard

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `icon` | String | String | hayır | default="🔮" |
| `image` | String | String | hayır | default="" |
| `href` | String | String | hayır | default="/fallar" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## IdempotencyRecord

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `scope` | String | String | evet |  |
| `userId` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="in_flight" |
| `responseStatus` | Int? | int? | hayır |  |
| `responseBody` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `expiresAt` | DateTime | DateTime | evet |  |

## IntegrationSecret

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `scope` | String | String | evet |  |
| `providerKey` | String | String | evet |  |
| `fieldKey` | String | String | evet |  |
| `ciphertext` | String | String | evet |  |
| `iv` | String | String | evet |  |
| `authTag` | String | String | evet |  |
| `keyVersion` | Int | int | hayır | default=1 |
| `updatedBy` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## IntegrationSetting

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `value` | String | String | evet |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## InviteCode

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `agencyId` | String | String | evet |  |
| `code` | String | String | evet | unique |
| `createdById` | String | String | evet |  |
| `maxUses` | Int | int | hayır | default=0 |
| `usedCount` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `agency` | Agency | — | evet | ilişki |
| `usedBy` | AgencyUser[] | — | evet | ilişki |

## IpFortuneUsage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `ipAddress` | String | String | evet |  |
| `date` | DateTime | DateTime | evet |  |
| `count` | Int | int | hayır | default=1 |
| `adWatched` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## JetonTransaction

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `amount` | Int | int | evet |  |
| `type` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `itemSlug` | String? | String? | hayır |  |
| `balanceBefore` | Int | int | evet |  |
| `balanceAfter` | Int | int | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## LeaderboardConfig

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `scope` | String | String | evet |  |
| `periodType` | String | String | evet |  |
| `isEnabled` | Boolean | bool | hayır | default=true |
| `topN` | Int | int | hayır | default=100 |
| `rewardConfig` | Json? | dynamic? | hayır |  |
| `scoringRules` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `periods` | LeaderboardPeriod[] | — | evet | ilişki |

## LeaderboardEntry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `periodId` | String | String | evet |  |
| `period` | LeaderboardPeriod | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `contextId` | String? | String? | hayır |  |
| `score` | Int | int | hayır | default=0 |
| `rank` | Int? | int? | hayır |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## LeaderboardPeriod

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `configId` | String | String | evet |  |
| `config` | LeaderboardConfig | — | evet | ilişki |
| `scope` | String | String | evet |  |
| `periodType` | String | String | evet |  |
| `periodKey` | String | String | evet |  |
| `startTime` | DateTime | DateTime | evet |  |
| `endTime` | DateTime | DateTime | evet |  |
| `status` | String | String | hayır | default="active" |
| `finalizedAt` | DateTime? | DateTime? | hayır |  |
| `rewardedAt` | DateTime? | DateTime? | hayır |  |
| `entries` | LeaderboardEntry[] | — | evet | ilişki |
| `rewards` | LeaderboardReward[] | — | evet | ilişki |

## LeaderboardReward

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `periodId` | String | String | evet |  |
| `period` | LeaderboardPeriod | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `rank` | Int | int | evet |  |
| `rewardType` | String | String | evet |  |
| `rewardValue` | String | String | evet |  |
| `rewardLabel` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `distributedAt` | DateTime? | DateTime? | hayır |  |
| `transactionId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## LedgerEntry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `transactionId` | String | String | evet |  |
| `accountType` | String | String | evet |  |
| `accountId` | String | String | evet |  |
| `direction` | String | String | evet |  |
| `amount` | Int | int | evet |  |
| `currency` | String | String | hayır | default="jeton" |
| `balanceBefore` | Int | int | hayır | default=0 |
| `balanceAfter` | Int | int | hayır | default=0 |
| `category` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `referenceType` | String? | String? | hayır |  |
| `referenceId` | String? | String? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `actorId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## LiveActivity

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String? | String? | hayır |  |
| `userName` | String | String | evet |  |
| `userAvatar` | String? | String? | hayır |  |
| `activityType` | String | String | evet |  |
| `detail` | String? | String? | hayır |  |
| `targetUrl` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User? | — | hayır | ilişki |

## LiveFortuneTeller

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet | unique |
| `displayName` | String | String | evet |  |
| `bio` | String? | String? | hayır |  |
| `specialties` | String[] | List<String> | evet |  |
| `pricePerSession` | Int | int | hayır | default=100 |
| `rating` | Float | double | hayır | default=5.0 |
| `totalSessions` | Int | int | hayır | default=0 |
| `totalReviews` | Int | int | hayır | default=0 |
| `isOnline` | Boolean | bool | hayır | default=false |
| `isVerified` | Boolean | bool | hayır | default=false |
| `isActive` | Boolean | bool | hayır | default=true |
| `avatar` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `applicationNote` | String? | String? | hayır |  |
| `applicationStatus` | String | String | hayır | default="pending" |
| `approvedAt` | DateTime? | DateTime? | hayır |  |
| `banReason` | String? | String? | hayır |  |
| `bannedAt` | DateTime? | DateTime? | hayır |  |
| `bonusCredits` | Int | int | hayır | default=0 |
| `freezeReason` | String? | String? | hayır |  |
| `frozenAt` | DateTime? | DateTime? | hayır |  |
| `isBanned` | Boolean | bool | hayır | default=false |
| `isFrozen` | Boolean | bool | hayır | default=false |
| `rejectedAt` | DateTime? | DateTime? | hayır |  |
| `totalEarnings` | Int | int | hayır | default=0 |
| `tellerLevel` | String | String | hayır | default="bronze" |
| `levelPoints` | Int | int | hayır | default=0 |
| `levelUpdatedAt` | DateTime? | DateTime? | hayır |  |
| `canGoOnline` | Boolean | bool | hayır | default=true |
| `canChat` | Boolean | bool | hayır | default=true |
| `canStartSession` | Boolean | bool | hayır | default=true |
| `canSetPrice` | Boolean | bool | hayır | default=false |
| `canEditProfile` | Boolean | bool | hayır | default=true |
| `canViewEarnings` | Boolean | bool | hayır | default=true |
| `canWithdraw` | Boolean | bool | hayır | default=false |
| `verificationDocUrl` | String? | String? | hayır |  |
| `verificationStatus` | String | String | hayır | default="none" |
| `verificationNote` | String? | String? | hayır |  |
| `maxSessionsPerDay` | Int | int | hayır | default=10 |
| `commissionRate` | Int | int | hayır | default=20 |
| `adminNotes` | String? | String? | hayır |  |
| `user` | User | — | evet | ilişki |
| `sessions` | LiveSession[] | — | evet | ilişki |
| `reviews` | LiveTellerReview[] | — | evet | ilişki |
| `warnings` | TellerWarning[] | — | evet | ilişki |

## LiveGuestInvite

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `hostId` | String | String | evet |  |
| `guestId` | String | String | evet |  |
| `status` | String | String | hayır | default="pending" |
| `kind` | String | String | hayır | default="invite" |
| `message` | String? | String? | hayır |  |
| `respondedBy` | String? | String? | hayır |  |
| `cancelledAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `respondedAt` | DateTime? | DateTime? | hayır |  |
| `expiresAt` | DateTime | DateTime | evet |  |

## LiveGuestSession

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `status` | String | String | hayır | default="active" |
| `slot` | Int | int | evet |  |
| `source` | String | String | hayır | default="invite" |
| `approvedBy` | String? | String? | hayır |  |
| `isMuted` | Boolean | bool | hayır | default=false |
| `isVideoOff` | Boolean | bool | hayır | default=false |
| `mutedByHost` | Boolean | bool | hayır | default=false |
| `videoOffByHost` | Boolean | bool | hayır | default=false |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `lastSeenAt` | DateTime | DateTime | hayır | default=now( |
| `leftAt` | DateTime? | DateTime? | hayır |  |

## LiveSession

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tellerId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `fortuneType` | String | String | evet |  |
| `status` | String | String | hayır | default="pending" |
| `creditsCharged` | Int | int | evet |  |
| `startedAt` | DateTime? | DateTime? | hayır |  |
| `endedAt` | DateTime? | DateTime? | hayır |  |
| `notes` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `roomId` | String? | String? | hayır | unique |
| `maxMinutes` | Int | int | hayır | default=5 |
| `minutesUsed` | Int | int | hayır | default=0 |
| `creditsPerMinute` | Int | int | hayır | default=0 |
| `lastPingAt` | DateTime? | DateTime? | hayır |  |
| `timerStarted` | Boolean | bool | hayır | default=false |
| `timerStartedAt` | DateTime? | DateTime? | hayır |  |
| `messages` | LiveSessionMessage[] | — | evet | ilişki |
| `teller` | LiveFortuneTeller | — | evet | ilişki |
| `user` | User | — | evet | ilişki |
| `review` | LiveTellerReview? | — | hayır | ilişki |
| `chatSession` | TellerChatSession? | — | hayır | ilişki |
| `roomSignals` | RoomSignal[] | — | evet | ilişki |

## LiveSessionMessage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `sessionId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `message` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `session` | LiveSession | — | evet | ilişki |

## LiveTellerReview

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tellerId` | String | String | evet |  |
| `sessionId` | String | String | evet | unique |
| `rating` | Int | int | evet |  |
| `comment` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `session` | LiveSession | — | evet | ilişki |
| `teller` | LiveFortuneTeller | — | evet | ilişki |

## LuckyGiftReward

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `context` | String? | String? | hayır |  |
| `contextId` | String? | String? | hayır |  |
| `betJetons` | Int | int | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `multiplier` | Int | int | evet |  |
| `wonJetons` | Int | int | evet |  |
| `netJetons` | Int | int | evet |  |
| `isJackpot` | Boolean | bool | hayır | default=false |
| `tierId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## LuckyGiftTier

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String | String | hayır | default="" |
| `multiplier` | Int | int | evet |  |
| `weight` | Int | int | hayır | default=1 |
| `isJackpot` | Boolean | bool | hayır | default=false |
| `color` | String? | String? | hayır |  |
| `icon` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `contentVersion` | Int | int | hayır | default=1 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | hayır | default=now( |

## MembershipBadge

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `tier` | String | String | evet |  |
| `imageUrl` | String | String | evet |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## MembershipEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `bannerUrl` | String? | String? | hayır |  |
| `ctaUrl` | String? | String? | hayır |  |
| `startsAt` | DateTime | DateTime | evet |  |
| `endsAt` | DateTime | DateTime | evet |  |
| `minTierKey` | String? | String? | hayır |  |
| `allowedTiers` | String[] | List<String> | hayır | default=[] |
| `isActive` | Boolean | bool | hayır | default=true |
| `priority` | Int | int | hayır | default=0 |
| `createdBy` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## MembershipFeature

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `nameEn` | String | String | hayır | default="" |
| `category` | String | String | hayır | default="general" |
| `description` | String? | String? | hayır |  |
| `valueType` | String | String | hayır | default="boolean" |
| `unit` | String? | String? | hayır |  |
| `options` | Json? | dynamic? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `tierFeatures` | MembershipTierFeature[] | — | evet | ilişki |

## MembershipGrant

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `receiverId` | String | String | evet |  |
| `giverId` | String? | String? | hayır |  |
| `tierKey` | String | String | evet |  |
| `previousTier` | String? | String? | hayır |  |
| `source` | String | String | hayır | default="purchase" |
| `startsAt` | DateTime | DateTime | hayır | default=now( |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `transactionId` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="active" |
| `autoRenew` | Boolean | bool | hayır | default=false |
| `note` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `receiver` | User | — | evet | ilişki |
| `giver` | User? | — | hayır | ilişki |

## MembershipPlan

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `descriptionEn` | String? | String? | hayır |  |
| `tier` | String | String | evet |  |
| `durationDays` | Int | int | evet |  |
| `priceType` | String | String | evet |  |
| `price` | Int | int | evet |  |
| `currency` | String | String | hayır | default="TRY" |
| `features` | String? | String? | hayır |  |
| `bonusJetons` | Int | int | hayır | default=0 |
| `discountPercent` | Int | int | hayır | default=0 |
| `prioritySupport` | Boolean | bool | hayır | default=false |
| `exclusiveBadge` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `isFeatured` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `purchases` | MembershipPurchase[] | — | evet | ilişki |

## MembershipPurchase

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `planId` | String? | String? | hayır |  |
| `plan` | MembershipPlan? | — | hayır | ilişki |
| `priceType` | String | String | evet |  |
| `pricePaid` | Int | int | evet |  |
| `currency` | String | String | hayır | default="TRY" |
| `startsAt` | DateTime | DateTime | hayır | default=now( |
| `expiresAt` | DateTime | DateTime | evet |  |
| `status` | String | String | hayır | default="active" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `grantedBy` | String? | String? | hayır |  |

## MembershipTierDef

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `nameEn` | String | String | hayır | default="" |
| `rank` | Int | int | hayır | default=0 |
| `color` | String | String | hayır | default="#9ca3af" |
| `gradient` | String? | String? | hayır |  |
| `icon` | String | String | hayır | default="⭐" |
| `badgeUrl` | String? | String? | hayır |  |
| `frameUrl` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `discoveryWeight` | Float | double | hayır | default=1.0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `tierFeatures` | MembershipTierFeature[] | — | evet | ilişki |

## MembershipTierFeature

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tierKey` | String | String | evet |  |
| `featureKey` | String | String | evet |  |
| `enabled` | Boolean | bool | hayır | default=false |
| `limitValue` | Int? | int? | hayır |  |
| `dailyLimit` | Int? | int? | hayır |  |
| `monthlyLimit` | Int? | int? | hayır |  |
| `durationDays` | Int? | int? | hayır |  |
| `priority` | Int | int | hayır | default=0 |
| `assetRef` | String? | String? | hayır |  |
| `defaultValue` | Json? | dynamic? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `updatedBy` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `tier` | MembershipTierDef | — | evet | ilişki |
| `feature` | MembershipFeature | — | evet | ilişki |

## MessageRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `status` | String | String | hayır | default="pending" |
| `message` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `sender` | User | — | evet | ilişki |
| `receiver` | User | — | evet | ilişki |

## MicFrame

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `assetUrl` | String | String | evet |  |
| `tier` | String | String | hayır | default="gold" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## MiniGame

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `slug` | String | String | evet | unique |
| `title` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `icon` | String | String | hayır | default="🎮" |
| `isActive` | Boolean | bool | hayır | default=true |
| `entryFee` | Int | int | hayır | default=0 |
| `minReward` | Int | int | hayır | default=5 |
| `maxReward` | Int | int | hayır | default=50 |
| `sortOrder` | Int | int | hayır | default=0 |
| `config` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `plays` | GamePlay[] | — | evet | ilişki |

## NameEffect

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `tier` | String | String | hayır | default="gold" |
| `cssPreset` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## Notification

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `type` | String | String | evet |  |
| `title` | String? | String? | hayır |  |
| `message` | String | String | evet |  |
| `data` | String? | String? | hayır |  |
| `postId` | String? | String? | hayır |  |
| `fromUserId` | String? | String? | hayır |  |
| `fromUserName` | String? | String? | hayır |  |
| `isRead` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `dedupeKey` | String? | String? | hayır |  |
| `deepLink` | String? | String? | hayır |  |
| `user` | User | — | evet | ilişki |

## OkeyMatch

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `mode` | String | String | evet |  |
| `tableName` | String? | String? | hayır |  |
| `isPrivate` | Boolean | bool | hayır | default=false |
| `hasPassword` | Boolean | bool | hayır | default=false |
| `betAmount` | Int | int | hayır | default=0 |
| `betCurrency` | String | String | hayır | default="FREE" |
| `commissionPct` | Int | int | hayır | default=0 |
| `potAmount` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="finished" |
| `winnerId` | String? | String? | hayır |  |
| `winnerName` | String? | String? | hayır |  |
| `reason` | String? | String? | hayır |  |
| `durationSec` | Int | int | hayır | default=0 |
| `roundCount` | Int | int | hayır | default=1 |
| `indicatorTile` | String? | String? | hayır |  |
| `okeyTile` | String? | String? | hayır |  |
| `startedAt` | DateTime | DateTime | hayır | default=now( |
| `finishedAt` | DateTime | DateTime | hayır | default=now( |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `players` | OkeyMatchPlayer[] | — | evet | ilişki |

## OkeyMatchPlayer

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `matchId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | evet |  |
| `seat` | Int | int | evet |  |
| `isWinner` | Boolean | bool | hayır | default=false |
| `score` | Int | int | hayır | default=0 |
| `penaltyScore` | Int | int | hayır | default=0 |
| `betPaid` | Int | int | hayır | default=0 |
| `rewardWon` | Int | int | hayır | default=0 |
| `leftEarly` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `match` | OkeyMatch | — | evet | ilişki |

## OnlineFalButton

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `label` | String | String | evet |  |
| `icon` | String | String | hayır | default="🔗" |
| `href` | String | String | evet |  |
| `isVisible` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `bgColor` | String | String | hayır | default="from-purple-600/30 to-fuchsia-600/30" |
| `borderColor` | String | String | hayır | default="border-purple-400/50" |
| `textColor` | String | String | hayır | default="text-purple-200" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## OnlineFalSection

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `title` | String | String | evet |  |
| `icon` | String | String | hayır | default="✨" |
| `isVisible` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## PKBattle

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `stream1Id` | String | String | evet |  |
| `stream2Id` | String | String | evet |  |
| `user1Id` | String | String | evet |  |
| `user2Id` | String | String | evet |  |
| `score1` | Int | int | hayır | default=0 |
| `score2` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="pending" |
| `duration` | Int | int | hayır | default=300 |
| `startedAt` | DateTime? | DateTime? | hayır |  |
| `endedAt` | DateTime? | DateTime? | hayır |  |
| `winnerId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `acceptedAt` | DateTime? | DateTime? | hayır |  |
| `endsAt` | DateTime? | DateTime? | hayır |  |
| `isDraw` | Boolean | bool | hayır | default=false |
| `winnerSide` | Int? | int? | hayır |  |
| `scoreLogs` | PkScore[] | — | evet | ilişki |
| `pkGifts` | PkGift[] | — | evet | ilişki |
| `mode` | String | String | hayır | default="1v1" |
| `scope` | String | String | hayır | default="stream" |
| `scopeRoomId` | String? | String? | hayır |  |
| `pausedAt` | DateTime? | DateTime? | hayır |  |
| `pausedMs` | Int | int | hayır | default=0 |
| `participants` | PkBattleParticipant[] | — | evet | ilişki |

## PasswordResetToken

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `token` | String | String | evet | unique |
| `expiresAt` | DateTime | DateTime | evet |  |
| `used` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## Payment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `packageId` | String? | String? | hayır |  |
| `stripeSessionId` | String? | String? | hayır | unique |
| `stripePaymentIntentId` | String? | String? | hayır | unique |
| `amount` | Float | double | evet |  |
| `currency` | String | String | hayır | default="TRY" |
| `creditsAwarded` | Int | int | evet |  |
| `status` | String | String | hayır | default="pending" |
| `paymentMethod` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `completedAt` | DateTime? | DateTime? | hayır |  |
| `user` | User | — | evet | ilişki |
| `package` | CreditPackage? | — | hayır | ilişki |

## PaymentMethod

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `type` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `nameEn` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `descriptionEn` | String? | String? | hayır |  |
| `isActive` | Boolean | bool | hayır | default=true |
| `config` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## PaymentNotification

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `username` | String | String | evet |  |
| `paymentMethod` | String | String | evet |  |
| `amount` | Float | double | evet |  |
| `transactionId` | String? | String? | hayır |  |
| `senderName` | String? | String? | hayır |  |
| `notes` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `productType` | String | String | hayır | default="jeton" |
| `requestedAmount` | Int? | int? | hayır |  |
| `requestedGoldDays` | Int? | int? | hayır |  |
| `requestedGoldType` | String? | String? | hayır |  |
| `jetonLoaded` | Int? | int? | hayır |  |
| `cfcLoaded` | Int? | int? | hayır |  |
| `goldDaysLoaded` | Int? | int? | hayır |  |
| `goldTypeLoaded` | String? | String? | hayır |  |
| `processedBy` | String? | String? | hayır |  |
| `processedByName` | String? | String? | hayır |  |
| `processedAt` | DateTime? | DateTime? | hayır |  |
| `adminNote` | String? | String? | hayır |  |
| `originalRequestedAmount` | Int? | int? | hayır |  |
| `correctedAmount` | Int? | int? | hayır |  |
| `correctedBy` | String? | String? | hayır |  |
| `correctedAt` | DateTime? | DateTime? | hayır |  |
| `correctionReason` | String? | String? | hayır |  |
| `creditApplied` | Boolean | bool | hayır | default=false |
| `creditAppliedAt` | DateTime? | DateTime? | hayır |  |
| `proofUrl` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## Permission

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `group` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `roles` | RolePermission[] | — | evet | ilişki |

## PhoneOtp

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `phone` | String | String | evet |  |
| `code` | String? | String? | hayır |  |
| `codeHash` | String? | String? | hayır |  |
| `expiresAt` | DateTime | DateTime | evet |  |
| `used` | Boolean | bool | hayır | default=false |
| `attempts` | Int | int | hayır | default=0 |
| `ip` | String? | String? | hayır |  |
| `deviceId` | String? | String? | hayır |  |
| `providerKey` | String? | String? | hayır |  |
| `idempotencyKey` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## PkBan

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `bannedBy` | String | String | evet |  |
| `active` | Boolean | bool | hayır | default=true |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## PkBattleParticipant

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `battleId` | String | String | evet |  |
| `side` | Int | int | evet |  |
| `userId` | String | String | evet |  |
| `seatNumber` | Int? | int? | hayır |  |
| `points` | Int | int | hayır | default=0 |
| `isCaptain` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `battle` | PKBattle | — | evet | ilişki |

## PkEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `matchId` | String | String | evet |  |
| `type` | String | String | evet |  |
| `multiplier` | Float | double | hayır | default=2.0 |
| `startsAt` | DateTime | DateTime | hayır | default=now( |
| `endsAt` | DateTime | DateTime | evet |  |
| `createdBy` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## PkGift

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `battleId` | String | String | evet |  |
| `side` | Int | int | evet |  |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `points` | Int | int | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `battle` | PKBattle | — | evet | ilişki |

## PkMatch

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `hostUserId` | String | String | evet |  |
| `hostStreamId` | String | String | evet |  |
| `hostName` | String? | String? | hayır |  |
| `hostImage` | String? | String? | hayır |  |
| `guestUserId` | String | String | evet |  |
| `guestStreamId` | String? | String? | hayır |  |
| `guestName` | String? | String? | hayır |  |
| `guestImage` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `durationSec` | Int | int | hayır | default=180 |
| `hostScore` | Int | int | hayır | default=0 |
| `guestScore` | Int | int | hayır | default=0 |
| `result` | String? | String? | hayır |  |
| `winnerUserId` | String? | String? | hayır |  |
| `finalSprint` | Boolean | bool | hayır | default=false |
| `mode` | String | String | hayır | default="1v1" |
| `seatCount` | Int | int | hayır | default=2 |
| `leftScore` | Int | int | hayır | default=0 |
| `rightScore` | Int | int | hayır | default=0 |
| `leftName` | String? | String? | hayır |  |
| `rightName` | String? | String? | hayır |  |
| `seats` | PkSeat[] | — | evet | ilişki |
| `requestedAt` | DateTime | DateTime | hayır | default=now( |
| `respondedAt` | DateTime? | DateTime? | hayır |  |
| `startedAt` | DateTime? | DateTime? | hayır |  |
| `endsAt` | DateTime? | DateTime? | hayır |  |
| `finishedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## PkParticipant

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `matchId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `mode` | String | String | evet |  |
| `side` | String | String | evet |  |
| `score` | Int | int | hayır | default=0 |
| `outcome` | String | String | evet |  |
| `finishedAt` | DateTime | DateTime | hayır | default=now( |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## PkScore

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `battleId` | String | String | evet |  |
| `side` | Int | int | evet |  |
| `contributorId` | String | String | evet |  |
| `points` | Int | int | evet |  |
| `source` | String | String | hayır | default="gift" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `battle` | PKBattle | — | evet | ilişki |

## PkSeat

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `matchId` | String | String | evet |  |
| `match` | PkMatch | — | evet | ilişki |
| `seatIndex` | Int | int | evet |  |
| `team` | String | String | hayır | default="none" |
| `userId` | String | String | evet |  |
| `userName` | String? | String? | hayır |  |
| `userImage` | String? | String? | hayır |  |
| `streamId` | String? | String? | hayır |  |
| `score` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="active" |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `leftAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## PkStat

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `userId` | String | String | hayır | PK |
| `matches` | Int | int | hayır | default=0 |
| `wins` | Int | int | hayır | default=0 |
| `losses` | Int | int | hayır | default=0 |
| `draws` | Int | int | hayır | default=0 |
| `totalScore` | Int | int | hayır | default=0 |
| `bestScore` | Int | int | hayır | default=0 |
| `currentStreak` | Int | int | hayır | default=0 |
| `bestStreak` | Int | int | hayır | default=0 |
| `lastPlayedAt` | DateTime? | DateTime? | hayır |  |
| `updatedAt` | DateTime | DateTime | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## PlatformSettings

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `value` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## ProfileFrame

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `imageUrl` | String | String | evet |  |
| `tier` | String | String | hayır | default="gold" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `usersSelected` | User[] | — | evet | ilişki |
| `usersAssigned` | User[] | — | evet | ilişki |

## ProfileView

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `viewedUserId` | String | String | evet |  |
| `viewerId` | String? | String? | hayır |  |
| `viewedAt` | DateTime | DateTime | hayır | default=now( |

## ProfileVisit

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `visitorId` | String | String | evet |  |
| `profileId` | String | String | evet |  |
| `isHidden` | Boolean | bool | hayır | default=false |
| `visitedAt` | DateTime | DateTime | hayır | default=now( |
| `visitor` | User | — | evet | ilişki |
| `profile` | User | — | evet | ilişki |

## PushNotificationLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `onesignalId` | String? | String? | hayır |  |
| `title` | String | String | evet |  |
| `message` | String | String | evet |  |
| `url` | String? | String? | hayır |  |
| `imageUrl` | String? | String? | hayır |  |
| `targetType` | String | String | evet |  |
| `targetValue` | String? | String? | hayır |  |
| `scheduledAt` | DateTime? | DateTime? | hayır |  |
| `status` | String | String | hayır | default="sent" |
| `recipientCount` | Int | int | hayır | default=0 |
| `deliveredCount` | Int | int | hayır | default=0 |
| `clickedCount` | Int | int | hayır | default=0 |
| `errorMessage` | String? | String? | hayır |  |
| `createdBy` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## Referral

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `referrerId` | String | String | evet |  |
| `referredId` | String | String | evet |  |
| `creditsAwarded` | Int | int | hayır | default=50 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `referred` | User | — | evet | ilişki |
| `referrer` | User | — | evet | ilişki |

## ReferralCommission

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `earnerId` | String | String | evet |  |
| `sourceUserId` | String | String | evet |  |
| `agencyId` | String? | String? | hayır |  |
| `commissionType` | String | String | hayır | default="referral" |
| `topupAmount` | Int | int | evet |  |
| `topupCurrency` | String | String | hayır | default="credits" |
| `rate` | Float | double | evet |  |
| `amount` | Int | int | evet |  |
| `currency` | String | String | hayır | default="credits" |
| `sourceType` | String | String | hayır | default="admin_credit" |
| `sourceId` | String? | String? | hayır |  |
| `note` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `earner` | User | — | evet | ilişki |
| `sourceUser` | User | — | evet | ilişki |

## RefundRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `paymentId` | String? | String? | hayır |  |
| `storePurchaseId` | String? | String? | hayır |  |
| `amount` | Float | double | evet |  |
| `currency` | String | String | hayır | default="TRY" |
| `reason` | String | String | evet |  |
| `status` | String | String | hayır | default="pending" |
| `adminNote` | String? | String? | hayır |  |
| `resolvedBy` | String? | String? | hayır |  |
| `resolvedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `user` | User | — | evet | ilişki |

## RemoteConfig

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `value` | Json | dynamic | evet |  |
| `valueType` | String | String | hayır | default="json" |
| `group` | String | String | hayır | default="general" |
| `description` | String? | String? | hayır |  |
| `platform` | String | String | hayır | default="all" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## RevenueRule

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `context` | String | String | evet | unique |
| `label` | String | String | evet |  |
| `sitePercent` | Int | int | hayır | default=50 |
| `receiverPercent` | Int | int | hayır | default=50 |
| `ownerCutOfRemainderPercent` | Int | int | hayır | default=30 |
| `isActive` | Boolean | bool | hayır | default=true |
| `updatedAt` | DateTime | DateTime | hayır | default=now( |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## RevokedToken

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tokenHash` | String | String | evet | unique |
| `userId` | String | String | evet |  |
| `tokenType` | String | String | hayır | default="access" |
| `reason` | String? | String? | hayır |  |
| `expiresAt` | DateTime | DateTime | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## RiskEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `category` | String | String | evet |  |
| `score` | Int | int | hayır | default=0 |
| `level` | String | String | evet |  |
| `signals` | Json? | dynamic? | hayır |  |
| `amount` | Float? | double? | hayır |  |
| `currency` | String? | String? | hayır |  |
| `referenceType` | String? | String? | hayır |  |
| `referenceId` | String? | String? | hayır |  |
| `ip` | String? | String? | hayır |  |
| `reviewed` | Boolean | bool | hayır | default=false |
| `reviewedBy` | String? | String? | hayır |  |
| `reviewedAt` | DateTime? | DateTime? | hayır |  |
| `reviewNote` | String? | String? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## Role

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `name` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `level` | Int | int | hayır | default=0 |
| `isSystem` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `permissions` | RolePermission[] | — | evet | ilişki |

## RolePermission

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roleId` | String | String | evet |  |
| `permissionId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `role` | Role | — | evet | ilişki |
| `permission` | Permission | — | evet | ilişki |

## RoomRevenueLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `room` | ChatRoom | — | evet | ilişki |
| `eventType` | String | String | evet |  |
| `totalAmount` | Int | int | evet |  |
| `receiverAmount` | Int | int | hayır | default=0 |
| `ownerAmount` | Int | int | hayır | default=0 |
| `siteAmount` | Int | int | hayır | default=0 |
| `senderId` | String? | String? | hayır |  |
| `receiverId` | String? | String? | hayır |  |
| `ownerId` | String? | String? | hayır |  |
| `metadata` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## RoomSignal

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `sessionId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `receiverId` | String | String | evet |  |
| `signalType` | String | String | evet |  |
| `signalData` | String | String | evet |  |
| `processed` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `session` | LiveSession | — | evet | ilişki |

## RoomTheme

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `nameEn` | String | String | hayır | default="" |
| `backgroundUrl` | String | String | evet |  |
| `cloudStoragePath` | String? | String? | hayır |  |
| `thumbnailUrl` | String? | String? | hayır |  |
| `thumbnailCloudPath` | String? | String? | hayır |  |
| `assetType` | String | String | hayır | default="image" |
| `tier` | String | String | hayır | default="free" |
| `isActive` | Boolean | bool | hayır | default=true |
| `activeFrom` | DateTime? | DateTime? | hayır |  |
| `activeTo` | DateTime? | DateTime? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `category` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `animationSpeed` | Float? | double? | hayır | default=1.0 |
| `blurAmount` | Int? | int? | hayır | default=0 |
| `opacity` | Float? | double? | hayır | default=1.0 |
| `hasParallax` | Boolean | bool | hayır | default=false |
| `hasZoom` | Boolean | bool | hayır | default=false |
| `videoLoop` | Boolean | bool | hayır | default=true |
| `soundUrl` | String? | String? | hayır |  |
| `soundCloudPath` | String? | String? | hayır |  |
| `soundVolume` | Int? | int? | hayır | default=50 |
| `isPremium` | Boolean | bool | hayır | default=false |
| `isVipOnly` | Boolean | bool | hayır | default=false |
| `isEventOnly` | Boolean | bool | hayır | default=false |
| `contentVersion` | Int | int | hayır | default=1 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## RtcTelemetry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `context` | String | String | evet |  |
| `contextId` | String? | String? | hayır |  |
| `peerId` | String? | String? | hayır |  |
| `connectionState` | String? | String? | hayır |  |
| `iceState` | String? | String? | hayır |  |
| `reconnectCount` | Int | int | hayır | default=0 |
| `rttMs` | Float? | double? | hayır |  |
| `packetLossPercent` | Float? | double? | hayır |  |
| `jitterMs` | Float? | double? | hayır |  |
| `bitrateKbps` | Float? | double? | hayır |  |
| `freezeCount` | Int | int | hayır | default=0 |
| `freezeDurationMs` | Int | int | hayır | default=0 |
| `durationSeconds` | Int | int | hayır | default=0 |
| `qualityScore` | Int? | int? | hayır |  |
| `qualityLevel` | String? | String? | hayır |  |
| `platform` | String? | String? | hayır |  |
| `networkType` | String? | String? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## Session

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `sessionToken` | String | String | evet | unique |
| `userId` | String | String | evet |  |
| `expires` | DateTime | DateTime | evet |  |
| `user` | User | — | evet | ilişki |

## ShareEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `scope` | String | String | evet |  |
| `targetId` | String | String | evet |  |
| `channel` | String | String | hayır | default="link" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideo

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `videoUrl` | String | String | evet |  |
| `thumbnailUrl` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `durationSec` | Float? | double? | hayır |  |
| `viewsCount` | Int | int | hayır | default=0 |
| `likesCount` | Int | int | hayır | default=0 |
| `commentsCount` | Int | int | hayır | default=0 |
| `sharesCount` | Int | int | hayır | default=0 |
| `savesCount` | Int | int | hayır | default=0 |
| `visibility` | String | String | hayır | default="everyone" |
| `commentSetting` | String | String | hayır | default="everyone" |
| `allowDuet` | Boolean | bool | hayır | default=true |
| `locationName` | String? | String? | hayır |  |
| `locationLat` | Float? | double? | hayır |  |
| `locationLng` | Float? | double? | hayır |  |
| `musicId` | String? | String? | hayır |  |
| `music` | ShortVideoMusic? | — | hayır | ilişki |
| `duetOfId` | String? | String? | hayır |  |
| `duetOf` | ShortVideo? | — | hayır | ilişki |
| `duets` | ShortVideo[] | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `likes` | ShortVideoLike[] | — | evet | ilişki |
| `comments` | ShortVideoComment[] | — | evet | ilişki |
| `views` | ShortVideoView[] | — | evet | ilişki |
| `saves` | ShortVideoSave[] | — | evet | ilişki |
| `mentions` | ShortVideoMention[] | — | evet | ilişki |
| `hashtags` | ShortVideoHashtag[] | — | evet | ilişki |

## ShortVideoComment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `videoId` | String | String | evet |  |
| `video` | ShortVideo | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `content` | String | String | evet |  |
| `likesCount` | Int | int | hayır | default=0 |
| `isPinned` | Boolean | bool | hayır | default=false |
| `parentId` | String? | String? | hayır |  |
| `parent` | ShortVideoComment? | — | hayır | ilişki |
| `replies` | ShortVideoComment[] | — | evet | ilişki |
| `likes` | ShortVideoCommentLike[] | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideoCommentLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `commentId` | String | String | evet |  |
| `comment` | ShortVideoComment | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideoHashtag

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `videoId` | String | String | evet |  |
| `video` | ShortVideo | — | evet | ilişki |
| `hashtagId` | String | String | evet |  |
| `hashtag` | Hashtag | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideoLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `videoId` | String | String | evet |  |
| `video` | ShortVideo | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideoMention

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `videoId` | String | String | evet |  |
| `video` | ShortVideo | — | evet | ilişki |
| `mentionedUserId` | String | String | evet |  |
| `mentionedUser` | User | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideoMusic

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `artist` | String? | String? | hayır |  |
| `audioUrl` | String | String | evet |  |
| `coverUrl` | String? | String? | hayır |  |
| `durationSec` | Float? | double? | hayır |  |
| `usesCount` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `videos` | ShortVideo[] | — | evet | ilişki |

## ShortVideoSave

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `videoId` | String | String | evet |  |
| `video` | ShortVideo | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## ShortVideoView

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `videoId` | String | String | evet |  |
| `video` | ShortVideo | — | evet | ilişki |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `watchedSec` | Float? | double? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## SiteAnnouncement

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `type` | String | String | evet |  |
| `message` | String | String | evet |  |
| `color` | String | String | hayır | default="red" |
| `userId` | String? | String? | hayır |  |
| `userName` | String? | String? | hayır |  |
| `maxPasses` | Int | int | hayır | default=1 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `expiresAt` | DateTime | DateTime | evet |  |

## SitePage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `titleEn` | String? | String? | hayır |  |
| `slug` | String | String | evet | unique |
| `content` | String | String | evet |  |
| `contentEn` | String? | String? | hayır |  |
| `isPublished` | Boolean | bool | hayır | default=true |
| `showInFooter` | Boolean | bool | hayır | default=true |
| `showInHeader` | Boolean | bool | hayır | default=false |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## SitePresence

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `visitorId` | String | String | evet | unique |
| `userId` | String? | String? | hayır |  |
| `lastSeen` | DateTime | DateTime | hayır | default=now( |
| `userAgent` | String? | String? | hayır |  |
| `path` | String? | String? | hayır |  |
| `deviceType` | String? | String? | hayır |  |
| `isBot` | Boolean | bool | hayır | default=false |
| `botName` | String? | String? | hayır |  |

## SiteSetting

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `key` | String | String | evet | unique |
| `value` | String | String | evet |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## SiteVisit

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `visitorId` | String | String | evet |  |
| `userId` | String? | String? | hayır |  |
| `visitedAt` | DateTime | DateTime | hayır | default=now( |
| `path` | String? | String? | hayır |  |
| `userAgent` | String? | String? | hayır |  |
| `country` | String? | String? | hayır |  |
| `city` | String? | String? | hayır |  |
| `ipHash` | String? | String? | hayır |  |
| `deviceType` | String? | String? | hayır |  |
| `isBot` | Boolean | bool | hayır | default=false |
| `botName` | String? | String? | hayır |  |

## SmsDeliveryLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `providerKey` | String | String | evet |  |
| `phoneMasked` | String | String | evet |  |
| `purpose` | String | String | hayır | default="otp" |
| `success` | Boolean | bool | evet |  |
| `errorCode` | String? | String? | hayır |  |
| `latencyMs` | Int? | int? | hayır |  |
| `isFallback` | Boolean | bool | hayır | default=false |
| `isTest` | Boolean | bool | hayır | default=false |
| `idempotencyKey` | String? | String? | hayır |  |
| `providerMessageId` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## SmsProvider

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `providerKey` | String | String | evet | unique |
| `displayName` | String | String | evet |  |
| `enabled` | Boolean | bool | hayır | default=false |
| `priority` | Int | int | hayır | default=100 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## SmsProviderConfig

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `providerKey` | String | String | evet |  |
| `fieldKey` | String | String | evet |  |
| `value` | String | String | evet |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## SmsProviderHealth

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `providerKey` | String | String | evet | unique |
| `status` | String | String | hayır | default="unknown" |
| `lastSuccessAt` | DateTime? | DateTime? | hayır |  |
| `lastFailureAt` | DateTime? | DateTime? | hayır |  |
| `lastTestedAt` | DateTime? | DateTime? | hayır |  |
| `lastUsedAt` | DateTime? | DateTime? | hayır |  |
| `lastError` | String? | String? | hayır |  |
| `successCount` | Int | int | hayır | default=0 |
| `failureCount` | Int | int | hayır | default=0 |
| `fallbackUseCount` | Int | int | hayır | default=0 |
| `avgLatencyMs` | Int | int | hayır | default=0 |
| `cooldownUntil` | DateTime? | DateTime? | hayır |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## SocialAction

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `actorId` | String | String | evet |  |
| `actor` | User | — | evet | ilişki |
| `targetId` | String | String | evet |  |
| `target` | User | — | evet | ilişki |
| `type` | String | String | evet |  |
| `status` | String | String | hayır | default="active" |
| `message` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## SocialComment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `content` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `post` | SocialPost | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## SocialLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `postId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `post` | SocialPost | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## SocialPost

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `fortuneId` | String? | String? | hayır |  |
| `content` | String | String | evet |  |
| `postType` | String | String | evet |  |
| `fortuneType` | String? | String? | hayır |  |
| `isPublic` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `imageUrl` | String? | String? | hayır |  |
| `isAuto` | Boolean | bool | hayır | default=false |
| `audioUrl` | String? | String? | hayır |  |
| `youtubeUrl` | String? | String? | hayır |  |
| `comments` | SocialComment[] | — | evet | ilişki |
| `likes` | SocialLike[] | — | evet | ilişki |
| `fortune` | Fortune? | — | hayır | ilişki |
| `user` | User | — | evet | ilişki |

## SosGame

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `gridSize` | Int | int | hayır | default=6 |
| `player1Id` | String | String | evet |  |
| `player2Id` | String? | String? | hayır |  |
| `isAI` | Boolean | bool | hayır | default=false |
| `betAmount` | Int | int | hayır | default=0 |
| `betCurrency` | String | String | hayır | default="FREE" |
| `board` | String | String | hayır | default="[]" |
| `lines` | String | String | hayır | default="[]" |
| `currentTurn` | Int | int | hayır | default=1 |
| `player1Score` | Int | int | hayır | default=0 |
| `player2Score` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="waiting" |
| `winnerId` | String? | String? | hayır |  |
| `player1Name` | String | String | hayır | default="Oyuncu 1" |
| `player2Name` | String | String | hayır | default="Oyuncu 2" |
| `turnTimer` | Int | int | hayır | default=0 |
| `chatEnabled` | Boolean | bool | hayır | default=true |
| `lastMoveAt` | DateTime? | DateTime? | hayır |  |
| `disconnectedPlayerId` | String? | String? | hayır |  |
| `player1LastSeen` | DateTime? | DateTime? | hayır |  |
| `player2LastSeen` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `chatMessages` | SosGameChat[] | — | evet | ilişki |
| `viewers` | SosGameViewer[] | — | evet | ilişki |

## SosGameChat

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `gameId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | evet |  |
| `message` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `game` | SosGame | — | evet | ilişki |

## SosGameViewer

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `gameId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | evet |  |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `game` | SosGame | — | evet | ilişki |

## StorePurchase

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `provider` | String | String | hayır | default="google_play" |
| `productId` | String | String | evet |  |
| `purchaseToken` | String | String | evet |  |
| `orderId` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `failureReason` | String? | String? | hayır |  |
| `rawResponse` | Json? | dynamic? | hayır |  |
| `grantedType` | String? | String? | hayır |  |
| `grantedAmount` | Int | int | hayır | default=0 |
| `ledgerTxId` | String? | String? | hayır |  |
| `verifiedAt` | DateTime? | DateTime? | hayır |  |
| `grantedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## StreamBan

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `bannedUserId` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `bannedAt` | DateTime | DateTime | hayır | default=now( |

## StreamCoBroadcaster

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `status` | String | String | hayır | default="invited" |
| `isMuted` | Boolean | bool | hayır | default=false |
| `isVideoOff` | Boolean | bool | hayır | default=false |
| `invitedAt` | DateTime | DateTime | hayır | default=now( |
| `joinedAt` | DateTime? | DateTime? | hayır |  |
| `leftAt` | DateTime? | DateTime? | hayır |  |

## StreamFortuneRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `typeId` | String? | String? | hayır |  |
| `nickname` | String? | String? | hayır |  |
| `isHidden` | Boolean | bool | hayır | default=false |
| `question` | String? | String? | hayır |  |
| `jetonAmount` | Int | int | hayır | default=0 |
| `status` | String | String | hayır | default="pending" |
| `refundedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `selectedAt` | DateTime? | DateTime? | hayır |  |
| `completedAt` | DateTime? | DateTime? | hayır |  |
| `type` | FortuneRequestType? | — | hayır | ilişki |

## StreamGift

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `totalPrice` | Int | int | evet |  |
| `receiverAmount` | Int | int | hayır | default=0 |
| `siteAmount` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `stream` | VideoStream | — | evet | ilişki |
| `sender` | User | — | evet | ilişki |
| `giftType` | GiftType | — | evet | ilişki |

## StreamModerator

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `addedAt` | DateTime | DateTime | hayır | default=now( |

## StreamMutedViewer

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `viewerId` | String | String | evet |  |
| `mutedBy` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `mutedAt` | DateTime | DateTime | hayır | default=now( |
| `expiresAt` | DateTime? | DateTime? | hayır |  |

## SupportMessage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `ticketId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `senderRole` | String | String | hayır | default="user" |
| `body` | String | String | evet |  |
| `isInternal` | Boolean | bool | hayır | default=false |
| `attachments` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `ticket` | SupportTicket | — | evet | ilişki |

## SupportTicket

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `subject` | String | String | evet |  |
| `category` | String | String | hayır | default="general" |
| `status` | String | String | hayır | default="open" |
| `priority` | String | String | hayır | default="normal" |
| `assignedTo` | String? | String? | hayır |  |
| `lastMessageAt` | DateTime | DateTime | hayır | default=now( |
| `relatedType` | String? | String? | hayır |  |
| `relatedId` | String? | String? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `messages` | SupportMessage[] | — | evet | ilişki |

## SupporterLevel

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `broadcasterId` | String | String | evet |  |
| `totalContributed` | Int | int | hayır | default=0 |
| `level` | Int | int | hayır | default=0 |
| `levelName` | String? | String? | hayır |  |
| `lastContributedAt` | DateTime? | DateTime? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## Team

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `name` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `ownerId` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `logoUrl` | String? | String? | hayır |  |
| `memberCount` | Int | int | hayır | default=1 |
| `totalPoints` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `members` | TeamMember[] | — | evet | ilişki |

## TeamMember

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `teamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `role` | String | String | hayır | default="member" |
| `points` | Int | int | hayır | default=0 |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `team` | Team | — | evet | ilişki |

## TellerAward

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tellerId` | String | String | evet |  |
| `awardType` | String | String | evet |  |
| `title` | String? | String? | hayır |  |
| `awardedBy` | String? | String? | hayır |  |
| `startDate` | DateTime | DateTime | hayır | default=now( |
| `endDate` | DateTime | DateTime | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## TellerChatMessage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `chatSessionId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `senderType` | String | String | evet |  |
| `content` | String | String | evet |  |
| `messageType` | String | String | hayır | default="text" |
| `imageUrl` | String? | String? | hayır |  |
| `isRead` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `chatSession` | TellerChatSession | — | evet | ilişki |

## TellerChatSession

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `liveSessionId` | String | String | evet | unique |
| `userId` | String | String | evet |  |
| `tellerId` | String | String | evet |  |
| `status` | String | String | hayır | default="active" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `closedAt` | DateTime? | DateTime? | hayır |  |
| `liveSession` | LiveSession | — | evet | ilişki |
| `messages` | TellerChatMessage[] | — | evet | ilişki |

## TellerGift

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tellerId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `giftTypeId` | String | String | evet |  |
| `quantity` | Int | int | hayır | default=1 |
| `totalPrice` | Int | int | evet |  |
| `message` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## TellerWarning

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tellerId` | String | String | evet |  |
| `reason` | String | String | evet |  |
| `issuedBy` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `teller` | LiveFortuneTeller | — | evet | ilişki |

## TickerMessage

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `text` | String | String | evet |  |
| `icon` | String | String | hayır | default="✨" |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## TikTokCategory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `description` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `videos` | TikTokVideo[] | — | evet | ilişki |

## TikTokVideo

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tiktokUrl` | String | String | evet |  |
| `tiktokId` | String? | String? | hayır |  |
| `title` | String? | String? | hayır |  |
| `authorName` | String? | String? | hayır |  |
| `authorAvatar` | String? | String? | hayır |  |
| `thumbnailUrl` | String? | String? | hayır |  |
| `embedHtml` | String? | String? | hayır |  |
| `categoryId` | String? | String? | hayır |  |
| `category` | TikTokCategory? | — | hayır | ilişki |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## TopupBonusTier

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `label` | String? | String? | hayır |  |
| `minAmount` | Int | int | evet |  |
| `bonusPercent` | Float | double | hayır | default=0 |
| `currency` | String | String | hayır | default="all" |
| `sourceType` | String | String | hayır | default="all" |
| `maxBonus` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `sortOrder` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## TournamentMatch

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roundId` | String | String | evet |  |
| `matchOrder` | Int | int | hayır | default=1 |
| `status` | String | String | hayır | default="pending" |
| `side1Id` | String? | String? | hayır |  |
| `side1Name` | String? | String? | hayır |  |
| `side1Score` | Int | int | hayır | default=0 |
| `side2Id` | String? | String? | hayır |  |
| `side2Name` | String? | String? | hayır |  |
| `side2Score` | Int | int | hayır | default=0 |
| `winnerId` | String? | String? | hayır |  |
| `startedAt` | DateTime? | DateTime? | hayır |  |
| `endedAt` | DateTime? | DateTime? | hayır |  |
| `pkBattleId` | String? | String? | hayır |  |
| `notes` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime? | DateTime? | hayır |  |
| `round` | TournamentRound | — | evet | ilişki |

## TournamentRound

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tournamentId` | String | String | evet |  |
| `roundNumber` | Int | int | hayır | default=1 |
| `name` | String? | String? | hayır |  |
| `stage` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `startDate` | DateTime? | DateTime? | hayır |  |
| `endDate` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `tournament` | WeeklyTournament | — | evet | ilişki |
| `matches` | TournamentMatch[] | — | evet | ilişki |

## Translation

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `languageCode` | String | String | evet |  |
| `translationKey` | String | String | evet |  |
| `translationValue` | String | String | evet |  |

## TrendVideo

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `categoryId` | String | String | evet |  |
| `category` | TrendVideoCategory | — | evet | ilişki |
| `title` | String | String | evet |  |
| `youtubeId` | String | String | evet |  |
| `thumbnailUrl` | String? | String? | hayır |  |
| `channelName` | String? | String? | hayır |  |
| `duration` | String? | String? | hayır |  |
| `viewCount` | Int | int | hayır | default=0 |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## TrendVideoCategory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `description` | String? | String? | hayır |  |
| `sortOrder` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `videos` | TrendVideo[] | — | evet | ilişki |

## TrendingTopic

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `title` | String | String | evet |  |
| `slug` | String | String | evet | unique |
| `category` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `image` | String? | String? | hayır |  |
| `icon` | String? | String? | hayır |  |
| `trendScore` | Int | int | hayır | default=0 |
| `viewCount` | Int | int | hayır | default=0 |
| `likeCount` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `isPinned` | Boolean | bool | hayır | default=false |
| `relatedUrl` | String? | String? | hayır |  |
| `tags` | String? | String? | hayır |  |
| `startDate` | DateTime | DateTime | hayır | default=now( |
| `endDate` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## TrtcWebhookLog

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `eventGroupId` | Int | int | evet |  |
| `eventType` | Int | int | evet |  |
| `sdkAppId` | Int | int | evet |  |
| `roomId` | String? | String? | hayır |  |
| `userId` | String? | String? | hayır |  |
| `payload` | String | String | evet |  |
| `processedOk` | Boolean | bool | hayır | default=true |
| `errorMessage` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## User

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `email` | String | String | evet | unique |
| `emailVerified` | DateTime? | DateTime? | hayır |  |
| `password` | String? | String? | hayır |  |
| `name` | String | String | evet |  |
| `username` | String? | String? | hayır | unique |
| `phone` | String? | String? | hayır |  |
| `image` | String? | String? | hayır |  |
| `preferredLanguage` | String | String | hayır | default="tr" |
| `credits` | Int | int | hayır | default=50 |
| `role` | String | String | hayır | default="user" |
| `membership` | String | String | hayır | default="basic" |
| `membershipExpiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `referralCode` | String? | String? | hayır | unique |
| `referralCreditsEarned` | Int | int | hayır | default=0 |
| `referredById` | String? | String? | hayır |  |
| `bio` | String? | String? | hayır |  |
| `birthDate` | DateTime? | DateTime? | hayır |  |
| `birthTime` | String? | String? | hayır |  |
| `zodiacSign` | String? | String? | hayır |  |
| `risingSign` | String? | String? | hayır |  |
| `favoriteTeam` | String? | String? | hayır |  |
| `lastHoroscopeDate` | DateTime? | DateTime? | hayır |  |
| `messagePrivacy` | String | String | hayır | default="everyone" |
| `hideProfileViews` | Boolean | bool | hayır | default=false |
| `theme` | String | String | hayır | default="mystical" |
| `jetonBalance` | Int | int | hayır | default=0 |
| `city` | String? | String? | hayır |  |
| `country` | String? | String? | hayır | default="TR" |
| `specialBadges` | String? | String? | hayır |  |
| `profileEffect` | String? | String? | hayır |  |
| `profileFrameId` | String? | String? | hayır |  |
| `profileFrame` | ProfileFrame? | — | hayır | ilişki |
| `adminAssignedFrameId` | String? | String? | hayır |  |
| `adminAssignedFrame` | ProfileFrame? | — | hayır | ilişki |
| `nameEffect` | String? | String? | hayır |  |
| `entranceEffectId` | String? | String? | hayır |  |
| `premiumEntranceEnabled` | Boolean | bool | hayır | default=false |
| `premiumEntranceRequireGold` | Boolean | bool | hayır | default=true |
| `premiumEntranceEffectId` | String? | String? | hayır |  |
| `premiumEntranceDurationMs` | Int? | int? | hayır |  |
| `premiumEntranceAnimationType` | String? | String? | hayır |  |
| `lastOnlineEventAt` | DateTime? | DateTime? | hayır |  |
| `chatBubbleId` | String? | String? | hayır |  |
| `micFrameId` | String? | String? | hayır |  |
| `avatarAccessoryIds` | String? | String? | hayır |  |
| `withdrawalLimit` | Int | int | hayır | default=0 |
| `totalTimeSpentMinutes` | Int | int | hayır | default=0 |
| `lastActiveAt` | DateTime? | DateTime? | hayır |  |
| `activeDeviceToken` | String? | String? | hayır |  |
| `accounts` | Account[] | — | evet | ilişki |
| `bannedOthers` | ChatBan[] | — | evet | ilişki |
| `bannedIn` | ChatBan[] | — | evet | ilişki |
| `chatMessages` | ChatMessage[] | — | evet | ilişki |
| `mutedOthers` | ChatMute[] | — | evet | ilişki |
| `mutedIn` | ChatMute[] | — | evet | ilişki |
| `chatPresences` | ChatPresence[] | — | evet | ilişki |
| `chatRoles` | ChatUserRole[] | — | evet | ilişki |
| `ownedChatRooms` | ChatRoom[] | — | evet | ilişki |
| `beneficiaryRooms` | ChatRoom[] | — | evet | ilişki |
| `fortunes` | Fortune[] | — | evet | ilişki |
| `fortuneTellerProfile` | LiveFortuneTeller? | — | hayır | ilişki |
| `liveSessions` | LiveSession[] | — | evet | ilişki |
| `notifications` | Notification[] | — | evet | ilişki |
| `passwordResets` | PasswordResetToken[] | — | evet | ilişki |
| `emailVerifications` | EmailVerificationToken[] | — | evet | ilişki |
| `phoneOtps` | PhoneOtp[] | — | evet | ilişki |
| `refundRequests` | RefundRequest[] | — | evet | ilişki |
| `referredHistory` | Referral[] | — | evet | ilişki |
| `referralHistory` | Referral[] | — | evet | ilişki |
| `sessions` | Session[] | — | evet | ilişki |
| `socialComments` | SocialComment[] | — | evet | ilişki |
| `socialLikes` | SocialLike[] | — | evet | ilişki |
| `socialPosts` | SocialPost[] | — | evet | ilişki |
| `payments` | Payment[] | — | evet | ilişki |
| `referredBy` | User? | — | hayır | ilişki |
| `referrals` | User[] | — | evet | ilişki |
| `videoStreams` | VideoStream[] | — | evet | ilişki |
| `videoStreamComments` | VideoStreamComment[] | — | evet | ilişki |
| `videoStreamLikes` | VideoStreamLike[] | — | evet | ilişki |
| `streamGifts` | StreamGift[] | — | evet | ilişki |
| `sentChatRoomGifts` | ChatRoomGift[] | — | evet | ilişki |
| `receivedChatRoomGifts` | ChatRoomGift[] | — | evet | ilişki |
| `followers` | Follow[] | — | evet | ilişki |
| `following` | Follow[] | — | evet | ilişki |
| `sentMessages` | DirectMessage[] | — | evet | ilişki |
| `receivedMessages` | DirectMessage[] | — | evet | ilişki |
| `conversationsAsUser1` | Conversation[] | — | evet | ilişki |
| `conversationsAsUser2` | Conversation[] | — | evet | ilişki |
| `sentRequests` | MessageRequest[] | — | evet | ilişki |
| `receivedRequests` | MessageRequest[] | — | evet | ilişki |
| `dreamComments` | DreamComment[] | — | evet | ilişki |
| `dreamFavorites` | DreamFavorite[] | — | evet | ilişki |
| `dreamViews` | DreamView[] | — | evet | ilişki |
| `dreamDiaryEntries` | DreamDiaryEntry[] | — | evet | ilişki |
| `dailyLoginRewards` | DailyLoginReward[] | — | evet | ilişki |
| `dreamContestEntries` | DreamContestEntry[] | — | evet | ilişki |
| `dreamContestVotes` | DreamContestVote[] | — | evet | ilişki |
| `weeklyDreamReports` | WeeklyDreamReport[] | — | evet | ilişki |
| `liveActivities` | LiveActivity[] | — | evet | ilişki |
| `xp` | Int | int | hayır | default=0 |
| `level` | Int | int | hayır | default=1 |
| `loginStreak` | Int | int | hayır | default=0 |
| `lastLoginRewardDate` | DateTime? | DateTime? | hayır |  |
| `agencyMembership` | AgencyUser? | — | hayır | ilişki |
| `agencyLeaveRequests` | AgencyLeaveRequest[] | — | evet | ilişki |
| `celebrityFollows` | CelebrityFollow[] | — | evet | ilişki |
| `fanClubMemberships` | FanClubMember[] | — | evet | ilişki |
| `fanClubPosts` | FanClubPost[] | — | evet | ilişki |
| `fanClubPostLikes` | FanClubPostLike[] | — | evet | ilişki |
| `fanClubPolls` | FanClubPoll[] | — | evet | ilişki |
| `fanClubPollVotes` | FanClubPollVote[] | — | evet | ilişki |
| `celebrityPostLikes` | CelebrityPostLike[] | — | evet | ilişki |
| `celebrityPostComments` | CelebrityPostComment[] | — | evet | ilişki |
| `stories` | UserStory[] | — | evet | ilişki |
| `isBot` | Boolean | bool | hayır | default=false |
| `botProfile` | BotProfile? | — | hayır | ilişki |
| `cfcBalance` | Int | int | hayır | default=0 |
| `cfcPaymentRequests` | CfcPaymentRequest[] | — | evet | ilişki |
| `devices` | UserDevice[] | — | evet | ilişki |
| `shortVideos` | ShortVideo[] | — | evet | ilişki |
| `shortVideoLikes` | ShortVideoLike[] | — | evet | ilişki |
| `shortVideoComments` | ShortVideoComment[] | — | evet | ilişki |
| `shortVideoViews` | ShortVideoView[] | — | evet | ilişki |
| `shortVideoSaves` | ShortVideoSave[] | — | evet | ilişki |
| `shortVideoCommentLikes` | ShortVideoCommentLike[] | — | evet | ilişki |
| `shortVideoMentions` | ShortVideoMention[] | — | evet | ilişki |
| `blockedUsers` | UserBlock[] | — | evet | ilişki |
| `blockedByUsers` | UserBlock[] | — | evet | ilişki |
| `reportsMade` | UserReport[] | — | evet | ilişki |
| `reportsReceived` | UserReport[] | — | evet | ilişki |
| `animationAssignments` | AnimationAssignment[] | — | evet | ilişki |
| `animationAssignmentsGiven` | AnimationAssignment[] | — | evet | ilişki |
| `animationPlaybackLogs` | AnimationPlaybackLog[] | — | evet | ilişki |
| `commissionsEarned` | ReferralCommission[] | — | evet | ilişki |
| `commissionsGenerated` | ReferralCommission[] | — | evet | ilişki |
| `leaderboardEntries` | LeaderboardEntry[] | — | evet | ilişki |
| `leaderboardRewards` | LeaderboardReward[] | — | evet | ilişki |
| `onlineEvents` | UserOnlineEvent[] | — | evet | ilişki |
| `isBanned` | Boolean | bool | hayır | default=false |
| `banReason` | String? | String? | hayır |  |
| `bannedAt` | DateTime? | DateTime? | hayır |  |
| `bannedUntil` | DateTime? | DateTime? | hayır |  |
| `bannedBy` | String? | String? | hayır |  |
| `canBroadcast` | Boolean | bool | hayır | default=true |
| `canCreateRoom` | Boolean | bool | hayır | default=true |
| `canChat` | Boolean | bool | hayır | default=true |
| `canSendGift` | Boolean | bool | hayır | default=true |
| `canPK` | Boolean | bool | hayır | default=true |
| `isVerifiedUser` | Boolean | bool | hayır | default=false |
| `phoneVerified` | Boolean | bool | hayır | default=false |
| `permissionOverrides` | UserPermissionOverride[] | — | evet | ilişki |
| `adminActions` | AdminUserAction[] | — | evet | ilişki |
| `vipXp` | Int | int | hayır | default=0 |
| `customUserId` | String? | String? | hayır |  |
| `vipTitle` | String? | String? | hayır |  |
| `isFrozen` | Boolean | bool | hayır | default=false |
| `frozenAt` | DateTime? | DateTime? | hayır |  |
| `frozenReason` | String? | String? | hayır |  |
| `hiddenFromDiscovery` | Boolean | bool | hayır | default=false |
| `warningCount` | Int | int | hayır | default=0 |
| `latitude` | Float? | double? | hayır |  |
| `longitude` | Float? | double? | hayır |  |
| `locationEnabled` | Boolean | bool | hayır | default=false |
| `showDistance` | Boolean | bool | hayır | default=true |
| `discoveryPriority` | Int | int | hayır | default=0 |
| `socialLinks` | String? | String? | hayır |  |
| `socialLinksPublic` | Boolean | bool | hayır | default=false |
| `hobbies` | String? | String? | hayır |  |
| `showAge` | Boolean | bool | hayır | default=true |
| `showCity` | Boolean | bool | hayır | default=true |
| `showLastActive` | Boolean | bool | hayır | default=true |
| `socialActionsReceived` | SocialAction[] | — | evet | ilişki |
| `socialActionsPerformed` | SocialAction[] | — | evet | ilişki |
| `warningsReceived` | UserWarning[] | — | evet | ilişki |
| `timelineEvents` | UserTimelineEvent[] | — | evet | ilişki |
| `vipPreference` | UserVipPreference? | — | hayır | ilişki |
| `membershipGrantsReceived` | MembershipGrant[] | — | evet | ilişki |
| `membershipGrantsGiven` | MembershipGrant[] | — | evet | ilişki |
| `vipXpEntries` | VipXpLedger[] | — | evet | ilişki |
| `profileVisitsMade` | ProfileVisit[] | — | evet | ilişki |
| `profileVisitsReceived` | ProfileVisit[] | — | evet | ilişki |

## UserAchievement

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `achievementId` | String | String | evet |  |
| `earnedAt` | DateTime | DateTime | hayır | default=now( |
| `progress` | Int | int | hayır | default=0 |
| `isCompleted` | Boolean | bool | hayır | default=false |

## UserBlock

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `blockerId` | String | String | evet |  |
| `blockedId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `blocker` | User | — | evet | ilişki |
| `blocked` | User | — | evet | ilişki |

## UserDailyActivity

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `date` | DateTime | DateTime | evet |  |
| `minutesSpent` | Int | int | hayır | default=0 |
| `fortunesViewed` | Int | int | hayır | default=0 |
| `postsCreated` | Int | int | hayır | default=0 |
| `messagesCount` | Int | int | hayır | default=0 |
| `streamsWatched` | Int | int | hayır | default=0 |
| `creditsSpent` | Int | int | hayır | default=0 |
| `creditsEarned` | Int | int | hayır | default=0 |

## UserDevice

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `token` | String | String | evet |  |
| `platform` | String | String | hayır | default="android" |
| `appVersion` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `user` | User | — | evet | ilişki |

## UserFortuneStreak

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet | unique |
| `currentStreak` | Int | int | hayır | default=0 |
| `longestStreak` | Int | int | hayır | default=0 |
| `lastFortuneDate` | DateTime? | DateTime? | hayır |  |
| `totalFortunes` | Int | int | hayır | default=0 |

## UserGameProfile

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet | unique |
| `totalJetons` | Int | int | hayır | default=0 |
| `totalGames` | Int | int | hayır | default=0 |
| `level` | Int | int | hayır | default=1 |
| `levelTitle` | String | String | hayır | default="Yeni Üye" |
| `dailySpinsUsed` | Int | int | hayır | default=0 |
| `lastSpinDate` | DateTime? | DateTime? | hayır |  |
| `referralCode` | String? | String? | hayır | unique |
| `referralCount` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## UserHourlyActivity

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `hour` | Int | int | evet |  |
| `totalMinutes` | Int | int | hayır | default=0 |
| `loginCount` | Int | int | hayır | default=0 |

## UserLoginSession

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `loginAt` | DateTime | DateTime | hayır | default=now( |
| `logoutAt` | DateTime? | DateTime? | hayır |  |
| `duration` | Int | int | hayır | default=0 |
| `deviceType` | String? | String? | hayır |  |
| `browser` | String? | String? | hayır |  |

## UserMissionProgress

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `missionId` | String | String | evet |  |
| `dayKey` | String | String | evet |  |
| `progress` | Int | int | hayır | default=0 |
| `completed` | Boolean | bool | hayır | default=false |
| `claimed` | Boolean | bool | hayır | default=false |
| `updatedAt` | DateTime | DateTime | hayır | default=now( |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## UserOnlineEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `username` | String | String | evet |  |
| `avatarUrl` | String? | String? | hayır |  |
| `effectId` | String? | String? | hayır |  |
| `effectUrl` | String? | String? | hayır |  |
| `effectType` | String? | String? | hayır |  |
| `durationMs` | Int | int | hayır | default=4000 |
| `animationType` | String | String | hayır | default="slide_lr" |
| `tier` | String | String | hayır | default="gold" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## UserPermissionOverride

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `permissionKey` | String | String | evet |  |
| `granted` | Boolean | bool | hayır | default=true |
| `grantedBy` | String | String | evet |  |
| `reason` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## UserReport

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `reporterId` | String | String | evet |  |
| `reportedId` | String | String | evet |  |
| `reason` | String | String | evet |  |
| `details` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
| `reporter` | User | — | evet | ilişki |
| `reported` | User | — | evet | ilişki |

## UserStory

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `mediaUrl` | String | String | evet |  |
| `mediaType` | String | String | hayır | default="image" |
| `caption` | String? | String? | hayır |  |
| `viewCount` | Int | int | hayır | default=0 |
| `isActive` | Boolean | bool | hayır | default=true |
| `expiresAt` | DateTime | DateTime | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## UserTimelineEvent

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `type` | String | String | evet |  |
| `title` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `metadata` | String? | String? | hayır |  |
| `occurredAt` | DateTime | DateTime | hayır | default=now( |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## UserTokenRevocation

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `userId` | String | String | hayır | PK |
| `revokedAt` | DateTime | DateTime | hayır | default=now( |
| `reason` | String? | String? | hayır |  |
| `updatedAt` | DateTime | DateTime | evet |  |

## UserVipPreference

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet | unique |
| `user` | User | — | evet | ilişki |
| `hideVipBadge` | Boolean | bool | hayır | default=false |
| `hideOnlineStatus` | Boolean | bool | hayır | default=false |
| `hideLastSeen` | Boolean | bool | hayır | default=false |
| `hideProfileVisit` | Boolean | bool | hayır | default=false |
| `hiddenRoomEntry` | Boolean | bool | hayır | default=false |
| `hideVipStatus` | Boolean | bool | hayır | default=false |
| `disableEntranceEffects` | Boolean | bool | hayır | default=false |
| `muteOthersEntrance` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## UserWarning

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `user` | User | — | evet | ilişki |
| `adminId` | String | String | evet |  |
| `adminName` | String? | String? | hayır |  |
| `reason` | String | String | evet |  |
| `severity` | String | String | hayır | default="info" |
| `expiresAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## Verification

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `type` | String | String | hayır | default="identity" |
| `status` | String | String | hayır | default="pending" |
| `fullName` | String? | String? | hayır |  |
| `documentType` | String? | String? | hayır |  |
| `documentUrls` | Json? | dynamic? | hayır |  |
| `note` | String? | String? | hayır |  |
| `reviewNote` | String? | String? | hayır |  |
| `reviewedBy` | String? | String? | hayır |  |
| `reviewedAt` | DateTime? | DateTime? | hayır |  |
| `metadata` | Json? | dynamic? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |

## VerificationToken

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `identifier` | String | String | evet |  |
| `token` | String | String | evet | unique |
| `expires` | DateTime | DateTime | evet |  |

## VideoStream

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `title` | String? | String? | hayır |  |
| `description` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="live" |
| `viewerCount` | Int | int | hayır | default=0 |
| `likeCount` | Int | int | hayır | default=0 |
| `roomId` | String | String | hayır | unique, default=cuid( |
| `category` | String? | String? | hayır |  |
| `thumbnailUrl` | String? | String? | hayır |  |
| `broadcastImage` | String? | String? | hayır |  |
| `isImageMode` | Boolean | bool | hayır | default=false |
| `backgroundUrl` | String? | String? | hayır |  |
| `lastGiftAt` | DateTime? | DateTime? | hayır |  |
| `lastMediaAt` | DateTime? | DateTime? | hayır |  |
| `autoClosedAt` | DateTime? | DateTime? | hayır |  |
| `startedAt` | DateTime | DateTime | hayır | default=now( |
| `endedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |
| `comments` | VideoStreamComment[] | — | evet | ilişki |
| `likes` | VideoStreamLike[] | — | evet | ilişki |
| `viewers` | VideoStreamViewer[] | — | evet | ilişki |
| `gifts` | StreamGift[] | — | evet | ilişki |

## VideoStreamComment

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `content` | String | String | evet |  |
| `nickname` | String? | String? | hayır |  |
| `isHidden` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `stream` | VideoStream | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## VideoStreamLike

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `stream` | VideoStream | — | evet | ilişki |
| `user` | User | — | evet | ilişki |

## VideoStreamSignal

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `senderId` | String | String | evet |  |
| `receiverId` | String? | String? | hayır |  |
| `signalType` | String | String | evet |  |
| `signalData` | String | String | evet |  |
| `processed` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## VideoStreamViewer

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `streamId` | String | String | evet |  |
| `viewerId` | String | String | evet |  |
| `viewerName` | String? | String? | hayır |  |
| `nickname` | String? | String? | hayır |  |
| `isHidden` | Boolean | bool | hayır | default=false |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `leftAt` | DateTime? | DateTime? | hayır |  |
| `stream` | VideoStream | — | evet | ilişki |

## VipXpLedger

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `amount` | Int | int | evet |  |
| `source` | String | String | evet |  |
| `refId` | String? | String? | hayır |  |
| `note` | String? | String? | hayır |  |
| `balanceAfter` | Int | int | hayır | default=0 |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## VoiceSession

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `userName` | String | String | evet |  |
| `trtcUid` | Int | int | hayır | default=0 |
| `joinedAt` | DateTime | DateTime | hayır | default=now( |
| `lastPing` | DateTime | DateTime | hayır | default=now( |
| `isActive` | Boolean | bool | hayır | default=true |

## VoiceSignal

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `roomId` | String | String | evet |  |
| `fromUserId` | String | String | evet |  |
| `fromUserName` | String | String | evet |  |
| `toUserId` | String? | String? | hayır |  |
| `type` | String | String | evet |  |
| `data` | String? | String? | hayır |  |
| `processed` | Boolean | bool | hayır | default=false |
| `createdAt` | DateTime | DateTime | hayır | default=now( |

## WeeklyDreamReport

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `weekStart` | DateTime | DateTime | evet |  |
| `weekEnd` | DateTime | DateTime | evet |  |
| `reportContent` | String | String | evet |  |
| `dreamCount` | Int | int | hayır | default=0 |
| `topSymbols` | String[] | List<String> | hayır | default=[] |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `user` | User | — | evet | ilişki |

## WeeklyTournament

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `weekStart` | DateTime | DateTime | evet |  |
| `weekEnd` | DateTime | DateTime | evet |  |
| `type` | String | String | hayır | default="jeton_spend" |
| `title` | String | String | evet |  |
| `description` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="active" |
| `rewards` | String? | String? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `category` | String? | String? | hayır |  |
| `coverImage` | String? | String? | hayır |  |
| `registrationStart` | DateTime? | DateTime? | hayır |  |
| `registrationEnd` | DateTime? | DateTime? | hayır |  |
| `minParticipants` | Int? | int? | hayır |  |
| `maxParticipants` | Int? | int? | hayır |  |
| `visibility` | String? | String? | hayır | default="public" |
| `scoringType` | String? | String? | hayır |  |
| `eliminationType` | String? | String? | hayır |  |
| `roundCount` | Int? | int? | hayır | default=1 |
| `createdBy` | String? | String? | hayır |  |
| `updatedAt` | DateTime? | DateTime? | hayır |  |
| `rewardedAt` | DateTime? | DateTime? | hayır |  |
| `entries` | WeeklyTournamentEntry[] | — | evet | ilişki |
| `rounds` | TournamentRound[] | — | evet | ilişki |

## WeeklyTournamentEntry

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `tournamentId` | String | String | evet |  |
| `userId` | String | String | evet |  |
| `score` | Int | int | hayır | default=0 |
| `rank` | Int? | int? | hayır |  |
| `rewarded` | Boolean | bool | hayır | default=false |
| `updatedAt` | DateTime | DateTime | evet |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `tournament` | WeeklyTournament | — | evet | ilişki |

## WithdrawalRequest

| Alan | Tip | Dart | Zorunlu | Not |
|---|---|---|---|---|
| `id` | String | String | hayır | PK, default=cuid( |
| `userId` | String | String | evet |  |
| `amount` | Int | int | evet |  |
| `amountTL` | Float | double | evet |  |
| `method` | String | String | evet |  |
| `accountDetails` | String? | String? | hayır |  |
| `status` | String | String | hayır | default="pending" |
| `agencyId` | String? | String? | hayır |  |
| `agencyApprovedBy` | String? | String? | hayır |  |
| `agencyApprovedAt` | DateTime? | DateTime? | hayır |  |
| `agencyNote` | String? | String? | hayır |  |
| `adminNote` | String? | String? | hayır |  |
| `processedBy` | String? | String? | hayır |  |
| `processedAt` | DateTime? | DateTime? | hayır |  |
| `createdAt` | DateTime | DateTime | hayır | default=now( |
| `updatedAt` | DateTime | DateTime | evet |  |
