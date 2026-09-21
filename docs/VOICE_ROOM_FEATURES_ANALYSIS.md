# Sesli Oda Sistemi - Analiz & Öneriler

## ✅ Mevcut Özellikler

### Backend (Express/Prisma)
- ✅ Oda oluşturma/yönetimi (VoiceRoom model)
- ✅ Kullanıcı presence (joinPresence, leavePresence, heartbeat)
- ✅ Ban/unban sistemi (listRoomBans, banRoomUser)
- ✅ Konuşma isteği (requestSpeak, approveSpeak, listSpeakRequests)
- ✅ Koltuk atama (assignSeat)
- ✅ Oda sahipliği transferi
- ✅ DJ müzik kontrolleri (setDjMusic, getMusicQueue)
- ✅ Oda arka planı değiştirme
- ✅ Mikrofon durumu yönetimi (setVoiceMicState)
- ✅ Mesaj yönetimi (addTextMessage, clearRoomMessages)
- ✅ Yasaklı kelime filtrelemesi
- ✅ Admin ayarlar (VoiceRoomSettings model)
- ✅ Finansal denetim (VoiceRoomFinanceAuditLog)
- ✅ **YENİ** Agora token yönetimi (agoraRouter)
- ✅ **YENİ** Sesli oturum persistence (voice_sessions.ts)

### Mobile (Flutter)
- ✅ Temel oda görüntüleme
- ✅ SSE ile gerçek zamanlı güncellemeler
- ✅ Mikrofon kontrolü (TRTC)
- ✅ Müzik oynatıcı ve kuyruk
- ✅ Hediye sistemi
- ✅ PK savaşları
- ✅ Tema seçimi
- ✅ **YENİ** Enhanced Presence (audioLevel, micEnabled)
- ✅ **YENİ** Voice Moderation Screen (3 sekme)
- ✅ **YENİ** Audio Level Monitoring (VoiceAudioLevelMonitor)

---

## ⚠️ Eksik Özellikler & Boşluklar

### 1️⃣ **Oda Bilgi Sistemi** (ORTA ÖNCELIK)
**Problem:** Oda açıklaması, kategorisi, konusu gibi temel metaveri yok
**Çözüm:**
```prisma
model VoiceRoom {
  // Mevcut: id, slug, nameTr, descTr, icon, backgroundImage, ownerId, roomType, maxUsers
  // Eksik:
  category String?          // "Sohbet", "Müzik", "Oyun", vb.
  topic String?             // Geçici konu/tema
  language String @default("tr")
  isVerified Boolean @default(false)
  tags String[]  // ["müzik", "kültür", "sohbet"]
  description String?  // Daha detaylı açıklama
}
```
**Endpoint:** `GET /api/chat/rooms/:roomId/info`, `PATCH /api/chat/rooms/:roomId/info`

### 2️⃣ **Gelişmiş Kullanıcı Rolleri** (YÜKSEK ÖNCELIK)
**Problem:** Sadece sahip vs. normal kullanıcı, moderator/speaker rolu yok
**Çözüm:**
```prisma
model VoiceRoomRole {
  id String @id @default(cuid())
  roomId String
  userId String
  role "owner" | "moderator" | "speaker" | "listener"
  permissions String[]  // ["mute_others", "kick", "manage_queue"]
  assignedAt DateTime @default(now())
  assignedBy String?
  
  @@unique([roomId, userId])
}
```
**Endpoints:** 
- `POST /api/chat/rooms/:roomId/roles/:userId` (rol atama)
- `DELETE /api/chat/rooms/:roomId/roles/:userId` (rol silme)
- `GET /api/chat/rooms/:roomId/roles` (oda rolleri listesi)

### 3️⃣ **Odanın Gizlilik Seviyeleri** (ORTA ÖNCELIK)
**Problem:** Tüm odalar açık, private/friends-only seçeneği yok
**Çözüm:**
```prisma
model VoiceRoom {
  privacy "public" | "friends_only" | "private" | "password_protected" @default("public")
  passwordHash String?  // Şifre korumalı odalar için
}
```
**Endpoint:** `PATCH /api/chat/rooms/:roomId/privacy`

### 4️⃣ **Kullanıcı İstatistikleri & Leaderboard** (YÜKSEK ÖNCELIK)
**Problem:** Kullanıcı konuşma süresi, toplam dakika, katılım skoru yok
**Çözüm:**
```prisma
model UserVoiceStats {
  id String @id @default(cuid())
  userId String
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  totalMinutesSpeaking Int @default(0)
  totalMinutesListening Int @default(0)
  totalRoomsJoined Int @default(0)
  favoriteRoomId String?
  
  engagementScore Int @default(0)  // Algoritma-based
  lastActivityAt DateTime?
  
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([userId])
}

model RoomLeaderboard {
  id String @id @default(cuid())
  roomId String
  userId String
  
  speakingDuration Int  // Dakika
  messagesCount Int
  giftsReceived Int
  rank Int
  weeklyRank Int
  
  @@unique([roomId, userId])
  @@index([roomId, rank])
}
```
**Endpoints:**
- `GET /api/chat/rooms/:roomId/leaderboard`
- `GET /api/voice/user-stats`
- `GET /api/voice/leaderboard?period=week|month|alltime`

### 5️⃣ **Oda Aktivite Logları & Analitiği** (ORTA ÖNCELIK)
**Problem:** Oda aktivitesinin geçmişi ve analytics yok
**Çözüm:**
```prisma
model VoiceRoomActivityLog {
  id String @id @default(cuid())
  roomId String
  userId String?
  eventType "join" | "leave" | "speak" | "mute" | "ban" | "music_play" | "gift_sent"
  metadata Json?
  createdAt DateTime @default(now())
  
  @@index([roomId, createdAt])
  @@index([eventType, createdAt])
}

model VoiceRoomDailyStats {
  id String @id @default(cuid())
  roomId String
  date DateTime
  
  peakUsers Int  // Maksimum eş zamanlı kullanıcı
  avgUsers Int
  totalJoins Int
  totalSpeakers Int
  totalDuration Int  // Dakika
  totalGifts Int
  totalRevenue Int
  
  @@unique([roomId, date])
  @@index([roomId, date])
}
```
**Endpoint:** `GET /api/chat/rooms/:roomId/analytics?period=week&metrics=peak_users,avg_users,total_gifts`

### 6️⃣ **Oda Önerileri Algoritması** (YÜKSEK ÖNCELIK)
**Problem:** Kullanıcılara uygun odalar önerilmiyor
**Çözüm:**
- Tarihçeye dayalı (sık ziyaret edilen odalar)
- Benzerliklere dayalı (benzer kategori/dil)
- Trend-based (popüler odalar)
- Sosyal (arkadaşların bulunduğu odalar)

**Endpoint:** `GET /api/chat/rooms/recommended?limit=20`

### 7️⃣ **Acil Moderation Araçları** (YÜKSEK ÖNCELIK)
**Problem:** Hızlı moderasyon seçenekleri eksik
**Çözüm:**
```typescript
// Endpoints:
POST /api/chat/rooms/:roomId/moderation/mute-all
POST /api/chat/rooms/:roomId/moderation/unmute-all
POST /api/chat/rooms/:roomId/moderation/kick-all
POST /api/chat/rooms/:roomId/moderation/lock-room
POST /api/chat/rooms/:roomId/moderation/unlock-room
```

### 8️⃣ **Oda Ziyaret Tarihi & Favoriler** (ORTA ÖNCELIK)
**Problem:** Kullanıcı geçmişi ve favoriler takip edilmiyor
**Çözüm:**
```prisma
model UserRoomHistory {
  id String @id @default(cuid())
  userId String
  roomId String
  lastVisitedAt DateTime @updatedAt
  visitCount Int @default(0)
  isFavorite Boolean @default(false)
  
  @@unique([userId, roomId])
  @@index([userId, lastVisitedAt])
}
```
**Endpoint:** 
- `GET /api/voice/room-history`
- `POST /api/voice/favorites/:roomId`
- `DELETE /api/voice/favorites/:roomId`

### 9️⃣ **Oda Kayıt & Arşiv** (DÜŞÜK ÖNCELIK - İleride)
**Problem:** Odaların kaydedilmesi ve playback yok
**Not:** AWS S3 + TRTC recording SDK gerekli

### 🔟 **Kullanıcı Başarılar/Rozetler** (ORTA ÖNCELIK)
**Problem:** Oda-spesifik başarılar ve rozetler yok
**Çözüm:**
```prisma
model VoiceRoomBadge {
  id String @id @default(cuid())
  userId String
  roomId String
  badgeType "first_visit" | "10hours" | "speaker" | "gifter" | "moderator"
  earnedAt DateTime @default(now())
  
  @@unique([userId, roomId, badgeType])
}
```

---

## 🎯 Implementasyon Önceliği

### 🔴 YÜKSEK ÖNCELIK (Hemen Yap)
1. **Gelişmiş Kullanıcı Rolleri** - Moderation kalitesi
2. **Acil Moderation Araçları** - Güvenlik
3. **Kullanıcı İstatistikleri** - Engagement
4. **Oda Önerileri** - Kullanıcı akışı

### 🟠 ORTA ÖNCELIK (Hafta İçinde)
1. **Oda Bilgi Sistemi** - UX
2. **Gizlilik Seviyeleri** - Güvenlik
3. **Oda Aktivite Logları** - Analytics
4. **Oda Ziyaret Tarihi** - Personalization
5. **Başarılar/Rozetler** - Engagement

### 🟡 DÜŞÜK ÖNCELIK (İleride)
1. **Kayıt & Arşiv** - Premium feature
2. **Gelişmiş Analytics** - Business intelligence

---

## 📊 Tahmini İmpact

| Özellik | Kullanıcı Engagement | Moderation | Revenue | Zorluk |
|---------|------|---------------|---------|--------|
| Roller | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | Orta |
| İstatistikler | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | Orta |
| Öneriler | ⭐⭐⭐⭐ | - | ⭐⭐⭐ | Zor |
| Moderation | ⭐⭐ | ⭐⭐⭐⭐ | - | Kolay |
| Gizlilik | ⭐⭐ | ⭐⭐⭐ | ⭐ | Kolay |

