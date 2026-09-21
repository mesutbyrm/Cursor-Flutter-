# Canlı Yayın Sistemi - Eksik Özellikler Analizi

## ✅ Mevcut Özellikler

### Backend (Express/Prisma)
- ✅ Canlı yayın oluşturma/yönetimi (liveStreamStore)
- ✅ PK savaşları (pk_battles.ts)
- ✅ Hediye sistemi (video_streams.ts)
- ✅ Konuk davet & co-broadcast (liveStreamExtrasStore)
- ✅ Fal istekleri (streamFortuneRequestService)
- ✅ Müzik kontrolleri
- ✅ Moderasyon (mute/ban/add moderator)
- ✅ Chat sistemi (messages)
- ✅ Izleyici takibi (joinLiveStream, leaveLiveStream)
- ✅ Yayın Kaydı başlatma (endLiveStream)

### Mobile (Flutter)
- ✅ Canlı yayın sayfası (live_page.dart)
- ✅ Broadcast prep (live_broadcast_prep_page.dart)
- ✅ PK savaş sayfası (live_pk_battle_page.dart)
- ✅ Hediye sistemi
- ✅ Chat overlay
- ✅ Konuk grid
- ✅ Güzellik filtreleri
- ✅ Kalite seçimi
- ✅ Yayın planlama (broadcast_schedule_service.dart)
- ✅ Host dashboard (live_host_dashboard_provider.dart)

---

## ⚠️ Eksik Özellikler & Boşluklar

### 1️⃣ **Canlı Yayın Analytics & İçgörüler** (YÜKSEK ÖNCELIK)
**Problem:** Yayın performansı, viewer engagement metrikleri yok
**Çözüm:**
```prisma
model LiveStreamAnalytics {
  id String @id @default(cuid())
  streamId String
  
  totalViewers Int @default(0)
  peakViewers Int @default(0)
  averageViewers Int @default(0)
  
  totalMinutesWatched Int @default(0)
  averageWatchDuration Int @default(0)
  
  totalMessagesCount Int @default(0)
  totalGiftsCount Int @default(0)
  totalGiftValue Int @default(0)
  
  engagementScore Float @default(0)
  retentionRate Float @default(0)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([streamId])
  @@index([updatedAt])
}

model StreamViewerSession {
  id String @id @default(cuid())
  streamId String
  userId String
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  joinedAt DateTime
  leftAt DateTime?
  watchDurationSeconds Int @default(0)
  
  isGifter Boolean @default(false)
  giftCount Int @default(0)
  
  messageCount Int @default(0)
  likeCount Int @default(0)
  
  @@unique([streamId, userId, joinedAt])
  @@index([streamId, joinedAt])
  @@index([userId])
}
```
**Endpoints:** 
- `GET /api/video-streams/:streamId/analytics`
- `GET /api/video-streams/:streamId/viewer-sessions`
- `GET /api/video-streams/:streamId/performance-report`

### 2️⃣ **Moderasyon Logları & Audit** (ORTA ÖNCELIK)
**Problem:** Ban/mute işlemleri kaydedilmiyor
**Çözüm:**
```prisma
model StreamModerationLog {
  id String @id @default(cuid())
  streamId String
  
  action String  // "mute", "unmute", "ban", "unban", "kick"
  targetUserId String
  targetUser User @relation("StreamModerationsTarget", fields: [targetUserId], references: [id], onDelete: Cascade)
  
  moderatorId String?
  moderator User? @relation("StreamModerationsModerator", fields: [moderatorId], references: [id], onDelete: SetNull)
  
  reason String?
  duration Int?  // Saniye (null = kalıcı)
  metadata Json?
  
  createdAt DateTime @default(now())
  
  @@index([streamId, createdAt])
  @@index([targetUserId])
  @@index([action])
}
```
**Endpoints:**
- `GET /api/video-streams/:streamId/moderation-logs`
- `POST /api/video-streams/:streamId/moderation-logs`

### 3️⃣ **Chat Filtreleme & Moderation** (ORTA ÖNCELIK)
**Problem:** Sohbet mesajları filtrelenmiyor, ban kelime listesi yok
**Çözüm:**
```prisma
model ChatFilter {
  id String @id @default(cuid())
  streamId String
  
  bannedWords String[]
  autoModEnabled Boolean @default(true)
  
  reportedMessagesCount Int @default(0)
  deletedMessagesCount Int @default(0)
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([streamId])
}

model ReportedStreamMessage {
  id String @id @default(cuid())
  streamId String
  messageId String
  userId String
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  reportReason String
  reportedByUserId String
  reportedBy User @relation("ReportedMessages", fields: [reportedByUserId], references: [id], onDelete: Cascade)
  
  isModerationRejected Boolean @default(false)
  moderationRejectionReason String?
  
  createdAt DateTime @default(now())
  
  @@index([streamId])
  @@index([userId])
  @@index([createdAt])
}
```

### 4️⃣ **Viewer Demografikleri & Insights** (ORTA ÖNCELIK)
**Problem:** Izleyici yaş, ülke, cihaz tipi vb. bilgiler yok
**Çözüm:**
```prisma
model StreamViewerDemographics {
  id String @id @default(cuid())
  streamId String
  
  ageRange String?  // "13-17", "18-25", "26-35", vb.
  country String?
  deviceType String?  // "mobile", "desktop", "tablet"
  appVersion String?
  
  totalViewers Int @default(0)
  totalWatchTime Int @default(0)
  
  createdAt DateTime @default(now())
  
  @@index([streamId, createdAt])
}
```

### 5️⃣ **Trending & Popular Streams Discovery** (ORTA ÖNCELIK)
**Problem:** Yayınlar kategorize edilmiyor, trend algoritması yok
**Çözüm:**
- Most viewed streams (24h, 7d, 30d)
- Categories/topics ranking
- Viewer growth trend
- Recommendation algorithm
**Endpoint:** 
- `GET /api/video-streams/trending?period=24h`
- `GET /api/video-streams/category/:category`

### 6️⃣ **Yayın Kalitesi Monitoring** (ORTA ÖNCELIK)
**Problem:** Connection quality, bitrate, FPS tracking yok
**Çözüm:**
```prisma
model StreamQualityMetrics {
  id String @id @default(cuid())
  streamId String
  userId String?
  
  bitrate Int
  fps Int
  resolution String
  encoder String?
  
  packetLoss Float
  latency Int
  bufferCount Int
  
  recordedAt DateTime @default(now())
  
  @@index([streamId, recordedAt])
}
```

### 7️⃣ **VIP Izleyici Yönetimi** (ORTA ÖNCELIK)
**Problem:** VIP izleyici özel yetkiler yok (pinned messages, vb.)
**Çözüm:**
```prisma
model StreamVipViewer {
  id String @id @default(cuid())
  streamId String
  userId String
  user User @relation("StreamVipViewers", fields: [userId], references: [id], onDelete: Cascade)
  
  tier String  // "bronze", "silver", "gold", "platinum"
  privileges String[]  // ["pin_message", "custom_badge", "skip_mute"]
  
  addedAt DateTime @default(now())
  expiresAt DateTime?
  
  @@unique([streamId, userId])
  @@index([streamId])
}
```

### 8️⃣ **Yayın Başarıları/Rozetler** (DÜŞÜK ÖNCELIK)
**Problem:** Yayıncı başarıları ve milestone rozetleri yok
**Çözüm:**
```prisma
model StreamAchievement {
  id String @id @default(cuid())
  hostId String
  
  name String  // "İlk Yayın", "1000 İzleyici", vb.
  icon String?
  description String?
  
  triggerType String  // "total_viewers", "total_gifts", "duration"
  triggerValue Int
  
  unlockedAt DateTime?
  
  @@unique([hostId, triggerType])
}
```

### 9️⃣ **Host Sosyal Analitiği** (DÜŞÜK ÖNCELIK)
**Problem:** Yayıncının takipçi artışı, engagement oranı, vs. tracking yok
**Çözüm:**
```prisma
model HostStreamStats {
  id String @id @default(cuid())
  hostId String
  host User @relation("HostStreamStats", fields: [hostId], references: [id], onDelete: Cascade)
  
  totalLiveStreams Int @default(0)
  totalViewerMinutes Int @default(0)
  totalGiftsReceived Int @default(0)
  totalRevenue Int @default(0)
  
  averageViewersPerStream Int @default(0)
  averageStreamDuration Int @default(0)
  
  followerGainFromStreams Int @default(0)
  
  lastStreamAt DateTime?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([hostId])
  @@index([totalViewerMinutes])
}
```

### 🔟 **Canlı Yayın Kaydı & Replay Yönetimi** (DÜŞÜK ÖNCELIK - Premium)
**Problem:** Yayın replay'leri depolanmıyor
**Çözüm:**
```prisma
model StreamRecording {
  id String @id @default(cuid())
  streamId String
  hostId String
  host User @relation("HostRecordings", fields: [hostId], references: [id], onDelete: Cascade)
  
  recordingUrl String
  duration Int  // Saniye
  fileSize Int  // Byte
  
  isPublic Boolean @default(false)
  viewCount Int @default(0)
  
  startedAt DateTime
  endedAt DateTime?
  
  createdAt DateTime @default(now())
  
  @@index([streamId])
  @@index([hostId, createdAt])
  @@index([isPublic])
}
```

---

## 🎯 Implementasyon Önceliği

### 🔴 YÜKSEK ÖNCELIK (Hemen)
1. **Canlı Yayın Analytics** - Engagement takibi
2. **Moderasyon Logları** - Audit trail
3. **Chat Filtreleme** - Güvenlik

### 🟠 ORTA ÖNCELIK (Hafta İçinde)
1. **Viewer Demographics** - Personalization
2. **Trending Discovery** - User retention
3. **Kalite Monitoring** - UX
4. **VIP Izleyici** - Monetization
5. **Host Sosyal Analytics** - Creator tools

### 🟡 DÜŞÜK ÖNCELIK (İleride)
1. **Yayın Başarıları** - Gamification
2. **Canlı Kayıt & Replay** - Premium feature

---

## 📊 Toplam Eksik Özellik: 10

| Kategori | Sayı |
|----------|------|
| Yüksek | 1 |
| Orta | 6 |
| Düşük | 3 |

