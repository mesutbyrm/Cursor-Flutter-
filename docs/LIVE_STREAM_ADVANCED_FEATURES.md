# Canlı Yayın Sistemi - İleri Özellikler Analizi & Önerileri

> **Tarih:** 2026-09-21  
> **Kapsam:** Yayın açma, PK, hediye, misafirlik, monetizasyon, efektler, reklamlar  
> **Durum:** Yeni özellik analizi

---

## ✅ Mevcut Özellikler (Temel)

### Canlı Yayın Tarafı
- ✅ Yayın başlat/bitir
- ✅ Izleyici sayısı takibi
- ✅ Chat sistemi
- ✅ Moderasyon (mute/ban)
- ✅ Co-broadcast (misafir davet)

### Etkileşim Tarafı
- ✅ Hediye sistemi (15+ hediye türü)
- ✅ PK savaşları (voice room + live stream)
- ✅ Fal istekleri
- ✅ Müzik oynatıcısı

### İstatistik Tarafı
- ✅ Live analytics (viewers, gifts, engagement)
- ✅ Host stats (revenue, followers, streams)
- ✅ Leaderboards

---

## 🆕 ÖNERİLEN İLERİ ÖZELLİKLER

### 1️⃣ **Yayın Açma Kampanyaları & Promosyonlar** (YÜKSEK)

**Problem:** Yayıncı/izleyici teşvik sistemi yok, yayın başlatma ödülü yok

**Çözüm:**

```prisma
model StreamLaunchCampaign {
  id String @id @default(cuid())
  hostId String
  host User @relation("StreamCampaigns", fields: [hostId], references: [id], onDelete: Cascade)
  
  campaignType String  // "first_stream", "daily_streak", "gift_milestone"
  title String
  description String?
  
  // Ödül
  rewardType String  // "tokens", "cfc", "membership"
  rewardValue Int
  rewardMultiplier Float @default(1.0)  // Saatlik vb.
  
  // Koşullar
  minViewers Int @default(0)
  minDuration Int @default(0)  // Dakika
  targetGiftAmount Int @default(0)
  
  // Durum
  status String @default("active")  // active, paused, completed
  startedAt DateTime
  endsAt DateTime?
  claimedRewardAt DateTime?
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@index([hostId, status])
  @@index([rewardType])
  @@map("stream_launch_campaigns")
}

model DailyStreamBonus {
  id String @id @default(cuid())
  hostId String @unique
  host User @relation("DailyStreamBonus", fields: [hostId], references: [id], onDelete: Cascade)
  
  streakDays Int @default(0)
  lastStreamDate DateTime?
  
  totalBonusEarned Int @default(0)
  bonusPerStream Int @default(100)
  streakMultiplier Float @default(1.0)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@map("daily_stream_bonuses")
}
```

**Endpoints:**
- `POST /api/video-streams/:streamId/campaign/start` — Kampanya başlat
- `GET /api/video-streams/:streamId/campaign` — Kampanya detayı
- `POST /api/video-streams/:streamId/campaign/claim-reward` — Ödül talep et
- `GET /api/users/me/daily-bonus` — Günlük bonus durumu
- `POST /api/users/me/daily-bonus/claim` — Bonus talep et

---

### 2️⃣ **PK Savaşı İleri Özellikleri** (YÜKSEK)

**Problem:** PK'ye katılımı artıracak ödüller, sponsorluk, özel efektler yok

**Çözüm:**

```prisma
model PkBattleReward {
  id String @id @default(cuid())
  battleId String
  
  winnerRewardTokens Int @default(0)
  winnerRewardCfc Int @default(0)
  loserConsolationTokens Int @default(0)
  
  totalViewersCost Int @default(0)
  totalGiftsCost Int @default(0)
  
  distributedAt DateTime?
  
  createdAt DateTime @default(now())
  
  @@unique([battleId])
  @@map("pk_battle_rewards")
}

model PkBattleEffect {
  id String @id @default(cuid())
  battleId String
  
  winnerId String
  loserId String
  
  effectType String  // "confetti", "fireworks", "crown", "lightning", "explosion"
  intensity String @default("normal")  // low, normal, high
  durationSeconds Int @default(5)
  
  soundEnabled Boolean @default(true)
  particleCount Int @default(100)
  
  createdAt DateTime @default(now())
  
  @@index([battleId])
  @@map("pk_battle_effects")
}

model PkBattleSponsor {
  id String @id @default(cuid())
  battleId String
  sponsorId String
  sponsor User @relation("PkSponsors", fields: [sponsorId], references: [id], onDelete: Cascade)
  
  sponsoredTeamId String  // Winner/Loser ID (user)
  sponsorshipAmount Int
  rewardShare Float @default(0.1)  // %10
  
  sponsorshipMessage String?
  isHighlighted Boolean @default(false)
  
  createdAt DateTime @default(now())
  
  @@index([battleId])
  @@index([sponsorId])
  @@map("pk_battle_sponsors")
}
```

**Endpoints:**
- `POST /api/pk/battles/:battleId/reward/distribute` — Ödülü dağıt
- `POST /api/pk/battles/:battleId/effect/trigger` — Efekt tetikle
- `POST /api/pk/battles/:battleId/sponsor` — Savaşı sponsor et
- `GET /api/pk/battles/:battleId/sponsors` — Sponsorları listele
- `GET /api/users/me/pk-reward-history` — Ödül geçmişi

---

### 3️⃣ **Hediye Sistemi İleri Özellikleri** (YÜKSEK)

**Problem:** Hediye combo, ekstra efektler, hediye açma animasyonları yok

**Çözüm:**

```prisma
model GiftCombo {
  id String @id @default(cuid())
  
  name String
  description String?
  
  // Hediye kombinasyonu
  requiredGiftIds String[]  // ["rose", "diamond", "ring"]
  comboEffectType String  // "mega_animation", "special_message", "profile_badge"
  
  bonusMultiplier Float @default(1.5)  // Combo bonusu
  extraTokenReward Int @default(0)
  exclusiveEmoji String?
  
  isLimited Boolean @default(false)
  limitEndDate DateTime?
  
  createdAt DateTime @default(now())
  
  @@index([comboEffectType])
  @@map("gift_combos")
}

model GiftBox {
  id String @id @default(cuid())
  streamId String
  hostId String
  
  name String  // "Valentines Box", "Mystery Box"
  description String?
  
  possibleGifts String[]
  boxPrice Int  // Token fiyatı
  expectedValue Int
  rarity String  // common, uncommon, rare, epic, legendary
  
  animation String?
  unboxEffect String  // "explosion", "sparkle", "glow"
  
  totalBoxesSold Int @default(0)
  
  createdAt DateTime @default(now())
  
  @@index([streamId, rarity])
  @@map("gift_boxes")
}

model AnimatedGiftEffect {
  id String @id @default(cuid())
  giftId String
  
  effectName String
  effectType String  // "full_screen", "corner", "floating", "rain"
  
  duration Int @default(3000)  // ms
  animationUrl String
  soundUrl String?
  
  particleType String?  // "confetti", "hearts", "stars"
  particleColor String?
  
  isExclusive Boolean @default(false)
  requiresPremium Boolean @default(false)
  
  createdAt DateTime @default(now())
  
  @@unique([giftId, effectType])
  @@map("animated_gift_effects")
}
```

**Endpoints:**
- `POST /api/gifts/send-combo` — Combo hediye gönder
- `GET /api/gifts/combos` — Combo listesi
- `POST /api/video-streams/:streamId/gift-box/open` — Hediye kutusu aç
- `GET /api/gifts/boxes/:streamId` — Yayın hediye kutuları
- `GET /api/gifts/:giftId/effects` — Hediye efektleri

---

### 4️⃣ **Co-Broadcast İleri Özellikleri** (ORTA)

**Problem:** Misafir özel yetkiler, kazanç paylaşımı, misafir sırasına alma yok

**Çözüm:**

```prisma
model CoBroadcastSession {
  id String @id @default(cuid())
  streamId String
  hostId String
  
  guestId String
  guest User @relation("CoBroadcastGuests", fields: [guestId], references: [id], onDelete: Cascade)
  
  guestRole String  // "co-host", "speaker", "interviewer"
  
  guestPermissions String[]  // ["can_speak", "can_mute_others", "can_control_music"]
  guestRevenueShare Float @default(0.2)  // %20
  
  joinedAt DateTime
  leftAt DateTime?
  durationSeconds Int @default(0)
  
  giftRevenueEarned Int @default(0)
  revenueDistributedAt DateTime?
  
  createdAt DateTime @default(now())
  
  @@index([streamId])
  @@index([guestId])
  @@map("co_broadcast_sessions")
}

model CoBroadcastWaitlist {
  id String @id @default(cuid())
  streamId String
  
  waitlistUserId String
  user User @relation("CoBroadcastWaitlist", fields: [waitlistUserId], references: [id], onDelete: Cascade)
  
  joinPosition Int
  duration Int @default(300)  // Dakika
  
  inviteExpiration DateTime
  status String @default("waiting")  // waiting, invited, joined, expired
  
  createdAt DateTime @default(now())
  
  @@unique([streamId, waitlistUserId])
  @@index([streamId, joinPosition])
  @@map("co_broadcast_waitlists")
}
```

**Endpoints:**
- `POST /api/video-streams/:streamId/co-broadcast/invite-guest` — Misafir davet et
- `POST /api/video-streams/:streamId/co-broadcast/guest/:guestId/permissions` — Yetkiler ver
- `POST /api/video-streams/:streamId/co-broadcast/guest/:guestId/end` — Misafir seans bitir
- `POST /api/video-streams/:streamId/co-broadcast/distribute-revenue` — Kazancı paylaş
- `POST /api/video-streams/:streamId/co-broadcast/waitlist/add` — Bekleme listesine ekle
- `GET /api/video-streams/:streamId/co-broadcast/waitlist` — Bekleme listesi

---

### 5️⃣ **Yayın İçi Üyelik & Token İndirim Sistemi** (YÜKSEK)

**Problem:** Yayın sırasında special offers, indirimli membership, token paketi yok

**Çözüm:**

```prisma
model LiveStreamMembershipOffer {
  id String @id @default(cuid())
  streamId String
  hostId String
  
  membershipType String  // "gold", "platinum", "vip"
  basePriceTokens Int
  discountPercent Int @default(0)
  
  discount_starts_at DateTime
  discount_ends_at DateTime?
  
  limitPerStream Int?  // Max kaç kişi satılabilir
  soldCount Int @default(0)
  
  offerMessage String?
  badgeForPurchasers String?
  
  createdAt DateTime @default(now())
  
  @@index([streamId])
  @@map("live_stream_membership_offers")
}

model LiveStreamTokenPackage {
  id String @id @default(cuid())
  streamId String
  hostId String
  
  packageName String  // "Lover's Pack", "Diamond Pack"
  tokenAmount Int
  baseCost Int  // Gerçek para
  discountedCost Int  // Yayın sırasında fiyat
  bonusTokens Int @default(0)
  
  bonusMessage String?
  limitPerStream Int?
  soldCount Int @default(0)
  
  createdAt DateTime @default(now())
  
  @@index([streamId, tokenAmount])
  @@map("live_stream_token_packages")
}

model StreamPurchaseReward {
  id String @id @default(cuid())
  purchaseId String  // Membership/Token purchase ID
  userId String
  user User @relation("StreamPurchaseRewards", fields: [userId], references: [id], onDelete: Cascade)
  
  rewardType String  // "badge", "exclusive_gift", "custom_frame", "animation"
  rewardValue String
  
  giftedToStreamHostId String?  // Host'a hemen gift olarak da gönderilebilir
  
  createdAt DateTime @default(now())
  
  @@index([userId])
  @@map("stream_purchase_rewards")
}
```

**Endpoints:**
- `POST /api/video-streams/:streamId/membership-offer` — Üyelik teklifi oluştur
- `POST /api/video-streams/:streamId/membership-offer/:offerId/buy` — Üyelik satın al
- `POST /api/video-streams/:streamId/token-package` — Token paketi oluştur
- `POST /api/video-streams/:streamId/token-package/:packageId/buy` — Token paketi satın al
- `GET /api/video-streams/:streamId/active-offers` — Aktif teklifleri listele

---

### 6️⃣ **Reklam & İçerik Sponsor Sistemi** (ORTA)

**Problem:** Yayın sırasında reklam, sponsor, ürün tanıtımı, overlay yok

**Çözüm:**

```prisma
model StreamAdPlacement {
  id String @id @default(cuid())
  streamId String
  
  adType String  // "banner", "overlay", "pop-up", "ticker", "host_mention"
  adContent String
  adImageUrl String?
  adVideoUrl String?
  
  advertiserName String
  advertiserLogoUrl String?
  advertiserLink String?
  
  displayDuration Int @default(5000)  // ms
  displayCount Int @default(1)
  displayedCount Int @default(0)
  
  scheduledAt DateTime?
  
  createdAt DateTime @default(now())
  
  @@index([streamId])
  @@map("stream_ad_placements")
}

model StreamSponsorBundle {
  id String @id @default(cuid())
  streamId String
  hostId String
  
  sponsorName String
  sponsorLogoUrl String?
  sponsorLink String?
  sponsorshipAmount Int
  
  bundleFeatures String[]  // ["banner", "mention", "gift_animation", "ticker"]
  
  startTime DateTime
  endTime DateTime?
  
  createdAt DateTime @default(now())
  
  @@index([streamId])
  @@map("stream_sponsor_bundles")
}

model AnimatedStreamOverlay {
  id String @id @default(cuid())
  
  name String  // "Cherry Blossom Rain", "Neon Border"
  overlayType String  // "rain", "border", "corner", "full_screen"
  
  animationUrl String
  effectColor String?
  intensity String @default("medium")
  
  duration Int @default(30)  // Dakika
  requiresPremium Boolean @default(false)
  requiresMembership Boolean @default(false)
  
  createdAt DateTime @default(now())
  
  @@map("animated_stream_overlays")
}
```

**Endpoints:**
- `POST /api/video-streams/:streamId/ad/schedule` — Reklam planla
- `POST /api/video-streams/:streamId/sponsor-bundle` — Sponsor paketi oluştur
- `GET /api/video-streams/:streamId/ad-placements` — Reklam yerleri
- `POST /api/video-streams/:streamId/overlay/activate` — Overlay efekti aktif et
- `GET /api/overlays/available` — Mevcut overlay efektleri

---

### 7️⃣ **Yayıncı Düzey Sistemi & Rozet Sınıflandırması** (ORTA)

**Problem:** Yayıncı tier'i, level-up mekanizması, özel ünvanlar yok

**Çözüm:**

```prisma
model HostBroadcasterTier {
  id String @id @default(cuid())
  hostId String @unique
  host User @relation("BroadcasterTier", fields: [hostId], references: [id], onDelete: Cascade)
  
  tierLevel Int @default(1)  // 1-10
  tierName String  // "Novice", "Rising Star", "Legend"
  
  experiencePoints Int @default(0)
  experienceNeeded Int @default(1000)
  
  // Tier yetkiği
  maxCoGuests Int @default(1)
  canCustomizeBorder Boolean @default(false)
  canUseAnimatedOverlay Boolean @default(false)
  canScheduleStream Boolean @default(false)
  specialBadgeColor String?
  
  // Tier bonu
  revenueBonus Float @default(1.0)  // Gelir çarpanı
  giftBonus Float @default(1.0)
  
  unlockedAt DateTime?
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@map("host_broadcaster_tiers")
}

model HostAchievementBadge {
  id String @id @default(cuid())
  hostId String
  host User @relation("HostAchievementBadges", fields: [hostId], references: [id], onDelete: Cascade)
  
  badgeType String  // "marathon", "gifter_magnet", "community_leader", "viral_star"
  badgeName String
  badgeIcon String
  badgeColor String?
  
  achievedValue Int  // İlgili metrik değeri
  achievedAt DateTime
  
  pinnedToProfile Boolean @default(false)
  
  @@unique([hostId, badgeType])
  @@map("host_achievement_badges")
}
```

**Endpoints:**
- `GET /api/users/me/broadcaster-tier` — Yayıncı tier detayı
- `POST /api/users/me/broadcaster-tier/upgrade` — Tier'i yükselt
- `GET /api/users/:userId/achievements/badges` — Yayıncı rozetleri
- `GET /api/broadcasters/leaderboard/by-tier` — Tier leaderboard

---

## 🎯 Implementasyon Önceliği

### 🔴 YÜKSEK (Hemen)
1. **Yayın Açma Kampanyaları** — Yayıncı katılımı
2. **PK Savaşı Ödülleri & Efektleri** — Eğlence & monetizasyon
3. **Hediye Combo Sistemi** — Engagement artırıcı
4. **Yayın İçi Üyelik Indirimleri** — Doğrudan gelir

### 🟠 ORTA (Hafta İçinde)
1. **Co-Broadcast Kazanç Paylaşımı** — Mizaçlı yayıncı
2. **Sponsor & Reklam Sistemi** — B2B gelir
3. **Yayıncı Tier Sistemi** — Progression & motivation
4. **Animated Overlays** — Görsel iyileştirme

### 🟡 DÜŞÜK (İleride)
1. **Stream Token Paketleri** — Premium monetizasyon
2. **Gift Box Mystery Boxes** — Gacha mekanikleri

---

## 📊 Teknik Öneriler

### Veritabanı Tasarımı
- Her feature için ayrı model (normalizasyon)
- Proper indexes (streamId, hostId, createdAt)
- Soft delete pattern (deletedAt nullable)

### API Tasarımı
- RESTful POST/GET/PATCH yapısı
- Paginate list endpoints
- Real-time SSE events
- Transaction handling (ödül dağıtımı)

### Frontend İntegrasyonları
- Stream dashboard'a campaign widgets
- Gift selection modal'da combo göster
- Guest queue UI
- Membership offer banner
- Ad/overlay system toggle

### Real-time Events (Socket.IO/SSE)
```
- campaign:awarded
- pk:battle-start, pk:effect-triggered
- gift:combo-activated
- membership:purchased
- ad:displayed
- overlay:activated
- tier:leveled-up
```

---

## 💰 Tahmini Gelir Artışı

| Feature | Yeni Gelir | Engagement | Uygulanabilirlik |
|---------|-----------|-----------|-----------------|
| Campaign Rewards | ⭐⭐⭐ | ⭐⭐⭐⭐ | Kolay |
| Membership Offers | ⭐⭐⭐⭐ | ⭐⭐⭐ | Orta |
| Sponsor Bundles | ⭐⭐⭐⭐ | ⭐⭐ | Zor |
| Gift Combos | ⭐⭐⭐ | ⭐⭐⭐⭐ | Kolay |
| Token Packages | ⭐⭐⭐⭐ | ⭐⭐⭐ | Orta |
| PK Rewards | ⭐⭐ | ⭐⭐⭐⭐ | Kolay |

---

## 🚀 Sonraki Adımlar

1. Yüksek öncelik 4 özelliğin Prisma modellerini ekle
2. Express route handlers'ları yaz
3. Mobile endpoints'leri güncelle
4. Real-time event emit'lerini ekle
5. Admin paneli için schema designer
6. User testing & iteration
