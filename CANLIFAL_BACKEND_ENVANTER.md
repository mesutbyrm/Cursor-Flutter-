# Canlifal Backend API Envanteri

**Güncellenme Tarihi:** 2026-09-24  
**Kılavuz Sürümü:** 1.0.391+429  
**Backend Durum:** ⚠️ Repository boş (analiz kılavuzdan gerçekleştirildi)

---

## Özet

Bu rapor, `FLUTTER_ENTegrasyon_KILAVUZU.md` dokümanına dayalı olarak Canlifal backend API'sinin TAM envanterini içerir. Backend reposu boş olduğu için, Flutter kılavuzunda tanımlanan official endpoint'ler kaynak alınmıştır.

**Base URL:** `https://canlifal.com`  
**Auth:** JWT Bearer Token (AccessToken: 7 gün, RefreshToken: 30 gün)

---

## 1. API Yapısı Özeti

### 1.1 Genel İstatistikler

| Kategori | Sayı |
|----------|------|
| **Repository Grubu** | 14 |
| **HTTP Endpoint'i** | 180+ |
| **SSE (Real-time) Endpoint** | 5 |
| **HTTP Metodu** | GET, POST, PATCH, DELETE |
| **Ağırlıklı Autentikasyon** | Bearer Token (✅) |

### 1.2 Repository Grupları

| # | Repository | Endpoint Sayısı | Kritik SSE | Açıklama |
|---|-----------|-----------------|-----------|----------|
| 1 | **AuthRepository** | 8 | ❌ | Giriş, kayıt, token yönetimi |
| 2 | **UserRepository** | 23 | ❌ | Profil, takip, istatistikler |
| 3 | **ChatRoomRepository** | 21 | ✅ | Sesli odalar, mesajlar |
| 4 | **LiveStreamRepository** | 21 | ✅ | Canlı yayın, yorumlar |
| 5 | **FortuneRepository** | 16 | ⚠️ | AI fallar (SSE streaming) |
| 6 | **FortuneTellerRepository** | 12 | ✅ | Canlı falcılar, oturum |
| 7 | **LiveSessionRepository** | 10 | ✅ | Fal seans yönetimi |
| 8 | **NotificationRepository** | 3 | ✅ | Bildirimler gerçek-zamanlı |
| 9 | **GiftRepository** | 4 | ❌ | Hediye kataloğu, gönderme |
| 10 | **SocialRepository** | 10 | ❌ | Sosyal gönderi, takip |
| 11 | **ShortVideoRepository** | 8 | ❌ | TikTok tarzı kısa videolar |
| 12 | **PaymentRepository** | 9 | ❌ | Kredi, paket, çekme |
| 13 | **SearchRepository** | 2 | ❌ | Arama, filtreleme |
| 14 | **SiteAnimationRepository** | 10 | ❌ | Animasyon katalog |

---

## 2. Detaylı Endpoint Envanteri

### 2.1 Authentication Endpoints

**Base:** `/api/auth`

| Endpoint | Metodu | Auth | Parametreler | Yanıt |
|----------|--------|------|--------------|-------|
| `/auth/mobile-login` | POST | ❌ | `{email/username, password}` | `{accessToken, refreshToken, user}` |
| `/auth/mobile-register` | POST | ❌ | `{email, password, name, username, birthDate, birthTime, referralCode?, preferredLanguage?}` | `{accessToken, refreshToken, user}` |
| `/auth/mobile-google` | POST | ❌ | `{idToken, referralCode?}` | `{accessToken, refreshToken, isNewUser, user}` |
| `/auth/mobile-tiktok` | POST | ❌ | `{code, redirectUri, referralCode?}` | `{accessToken, refreshToken, isNewUser, user}` |
| `/auth/mobile-apple` | POST | ❌ | `{...}` | `{accessToken, refreshToken, user}` |
| `/auth/mobile-refresh` | POST | ❌ | `{refreshToken}` | `{accessToken, refreshToken, user}` |
| `/auth/logout` | POST | ✅ | - | `{success}` |
| `/auth/logout-all` | POST | ✅ | - | Tüm cihazlarda oturum kapat |
| `/auth/change-password` | POST | ✅ | `{currentPassword, newPassword}` | `{success}` |

**İlgili Endpoint'ler (Kılavuz dışı, mevcut):**
- `/auth/mobile-send-verification` - E-posta doğrulama gönder
- `/auth/mobile-verify-email` - E-posta doğrula
- `/auth/sessions` - Cihaz listesi
- `/auth/mobile-sessions` - Mobil cihazlar
- `/auth/forgot-password` - Şifremi unuttum
- `/auth/reset-password` - Şifre sıfırla
- `/auth/email/send-verification` - Abacus sisteminde e-posta doğrulama
- `/auth/phone/send-otp` - SMS OTP gönder
- `/auth/phone/verify-otp` - OTP doğrula
- `/verification` - Kimlik/belge doğrulama
- `/auth/verify-device` - Cihaz doğrulama
- `/auth/reclaim-device` - Cihaz geri al

**Hata Kodları:**
- `400` - Validation hatası (eksik alan, zaten kayıtlı)
- `401` - Invalid credentials
- `429` - Rate limit (çok hızlı login denemesi)
- `500` - Sunucu hatası

---

### 2.2 User Endpoints

**Base:** `/api/user`, `/api/users`, `/api/me`

| Endpoint | Metodu | Auth | Amaç |
|----------|--------|------|------|
| `/me` | GET | ✅ | Oturumdaki kullanıcı bilgisi |
| `/user/profile` | GET | ✅ | Profil (doğrudan) |
| `/user/profile` | PATCH | ✅ | Profil güncelle |
| `/user/credits` | GET | ✅ | Kredi bakiyesi |
| `/user/wallet` | GET | ✅ | Cüzdan (Jeton, CFC) |
| `/user/stats` | GET | ✅ | Başlıca istatistikler |
| `/user/statistics` | GET | ✅ | Detaylı istatistikler |
| `/user/xp` | GET | ✅ | Seviye, XP |
| `/user/followers` | GET | ✅ | Takipçiler (sayfalı) |
| `/user/following` | GET | ✅ | Takip edilenler |
| `/user/likers` | GET | ✅ | Beğenenler |
| `/user/{userId}/follow-status` | GET | ✅ | İzleme durumu |
| `/user/{userId}/follow` | POST | ✅ | Kullanıcıyı takip et |
| `/users/{userId}` | GET | ✅ | Diğer kullanıcı profili |
| `/users/lookup/{username}` | GET | ✅ | Kullanıcı adına göre bul |
| `/users/search` | GET | ✅ | Kullanıcı adı arama |
| `/user/blocked` | GET | ✅ | Engellenen kullanıcılar |
| `/user/block` | POST | ✅ | Engelle/çıkart |
| `/user/report` | POST | ✅ | Kullanıcı şikayeti |
| `/user/achievements` | GET | ✅ | Başarı rozeti |
| `/user/active-sessions` | GET | ✅ | Aktif fal seansları |
| `/user/fortunes` | GET | ✅ | Fal geçmişi |
| `/user/fortunes/{fortuneId}` | GET | ✅ | Fal detayı |
| `/user/activity` | GET | ✅ | Aktivite geçmişi |
| `/user/theme` | GET/POST | ✅ | Tema tercihi |
| `/user/device-token` | POST | ✅ | FCM push token |
| `/user/watch-ad` | POST | ✅ | Reklam izle → ödül |
| `/user/received-gifts` | GET | ✅ | Alınan hediyeler |

**Related:**
- `/daily-login` - Günlük giriş ödülü
- `/daily-missions` - Günlük görevler
- `/presence` - Varlık sinyali
- `/users/online` - Çevrimiçi kullanıcılar

---

### 2.3 Chat Room Endpoints

**Base:** `/api/chat/rooms`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/chat/rooms` | GET | ✅ | Oda listesi (kategori, tür filtresi) |
| `/chat/rooms/create` | POST | ✅ | Yeni oda aç (2500 jeton) |
| `/chat/rooms/backgrounds` | GET | ✅ | Arka plan listesi |
| `/chat/rooms/{roomId}` | GET | ✅ | Oda detayı |
| `/chat/rooms/{roomId}` | PATCH | ✅ | Oda ayarları güncelle |
| `/chat/rooms/{roomId}/messages` | GET | ✅ | Mesaj geçmişi |
| `/chat/rooms/{roomId}/messages` | POST | ✅ | Mesaj gönder |
| `/chat/rooms/{roomId}/presence` | GET | ✅ | Katılımcı listesi |
| `/chat/rooms/{roomId}/presence` | POST | ✅ | Oda'ya katıl/ayrıl |
| `/chat/rooms/{roomId}/seats` | GET | ✅ | Koltuk durumu |
| `/chat/rooms/{roomId}/seats` | POST | ✅ | Koltuk işlemleri (take/leave/lock/kick) |
| `/chat/rooms/{roomId}/voice` | GET/POST | ✅ | Ses token (Agora/TRTC) |
| `/chat/rooms/{roomId}/typing` | POST | ✅ | Yazıyor göstergesi |
| `/chat/rooms/{roomId}/moderation` | POST | ✅ | Mute/ban kullanıcı |
| `/chat/rooms/{roomId}/dj` | GET/POST | ✅ | DJ yönetimi |
| `/chat/rooms/{roomId}/music` | GET/POST | ✅ | Müzik (play/pause/skip) |
| `/chat/rooms/{roomId}/music-queue` | GET/POST | ✅ | Müzik kuyruğu |
| `/chat/rooms/{roomId}/song-request` | POST | ✅ | Şarkı isteme |
| `/chat/rooms/{roomId}/gifts` | POST | ✅ | Hediye gönder |
| `/chat/rooms/{roomId}/report` | POST | ✅ | Oda şikayeti |
| `/chat/rooms/{roomId}/pk` | GET/POST | ✅ | PK davet/başlat |
| `/chat/rooms/{roomId}/transfer-ownership` | POST | ✅ | Sahiplik devri |
| `/chat/rooms/{roomId}/stream` | GET | ✅ | **SSE: Mesaj, presence, typing, gift, dj, system** |

---

### 2.4 Live Stream Endpoints

**Base:** `/api/video-streams`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/video-streams` | GET | ❌ | Canlı yayın listesi |
| `/video-streams` | POST | ✅ | Yayın başlat |
| `/video-streams/{streamId}` | GET | ❌ | Yayın detayı |
| `/video-streams/{streamId}` | PATCH | ✅ | Yayın ayarları |
| `/video-streams/{streamId}/end` | POST | ✅ | Yayını bitir |
| `/video-streams/{streamId}/join` | POST | ✅ | İzlemeye katıl |
| `/video-streams/{streamId}/leave` | POST | ✅ | İzlemeyi bırak |
| `/video-streams/{streamId}/comments` | GET | ❌ | Yorumlar |
| `/video-streams/{streamId}/comments` | POST | ✅ | Yorum yaz |
| `/video-streams/{streamId}/like` | GET/POST | ❌/✅ | Beğeni |
| `/video-streams/{streamId}/viewers` | GET | ❌ | İzleyici listesi |
| `/video-streams/{streamId}/gifts` | POST | ✅ | Hediye gönder |
| `/video-streams/{streamId}/gifts` | GET | ❌ | Hediye kataloğu |
| `/video-streams/{streamId}/messages` | GET/POST | ✅ | Canlı sohbet |
| `/video-streams/{streamId}/mute` | POST | ✅ | İzleyiciyi sustur |
| `/video-streams/{streamId}/ban` | POST | ✅ | İzleyiciyi engelle |
| `/video-streams/{streamId}/moderators` | GET/POST | ✅ | Moderatör yönetimi |
| `/video-streams/{streamId}/signal` | GET/POST | ✅ | P2P sinyali (co-broadcast) |
| `/video-streams/{streamId}/co-broadcast` | POST | ✅ | Birlikte yayın |
| `/video-streams/{streamId}/co-broadcast/invite` | POST | ✅ | Co-broadcast davet |
| `/video-streams/{streamId}/fortune-requests` | GET/POST | ✅ | Canlı fal istekleri |
| `/video-streams/{streamId}/pk-battle` | GET/POST | ✅ | PK savaş (legacy) |
| `/video-streams/pk` | GET/POST | ✅ | PK listesi ve başlat (canonical) |
| `/video-streams/{streamId}/stream` | GET | ✅ | **SSE: Message, viewer count, gift, stream end** |

---

### 2.5 Fortune (AI Fal) Endpoints

**Base:** `/api/fortunes`, `/api/horoscope`

| Endpoint | Metodu | Auth | Giriş | Çıkış |
|----------|--------|------|-------|-------|
| `/fortunes/kahve-fali` | POST | ✅ | `{images: [base64]}` | **SSE: text/event-stream** |
| `/fortunes/tarot-fali` | POST | ✅ | `{question?, spread?}` | **SSE** |
| `/fortunes/burc-yorumu` | POST | ✅ | `{zodiacSign, period?}` | **SSE** |
| `/fortunes/ruya-yorumu` | POST | ✅ | `{dream}` | **SSE** |
| `/fortunes/el-fali` | POST | ✅ | `{images: [base64]}` | **SSE** |
| `/fortunes/numeroloji` | POST | ✅ | `{birthDate, name}` | **SSE** |
| `/fortunes/melek-kartlari` | POST | ✅ | `{question?}` | **SSE** |
| `/fortunes/ask-uyumu` | POST | ✅ | `{sign1, sign2}` | **SSE** |
| `/fortunes/aura-analizi` | POST | ✅ | `{birthDate}` | **SSE** |
| `/fortunes/dogum-haritasi` | POST | ✅ | `{birthDate, birthTime, birthPlace}` | **SSE** |
| `/fortunes/evet-hayir` | POST | ✅ | `{question}` | **SSE** |
| `/fortunes/istihare` | POST | ✅ | `{question}` | **SSE** |
| `/fortunes/katina` | POST | ✅ | `{question?}` | **SSE** |
| `/fortunes/kursundokme` | POST | ✅ | `{concern?}` | **SSE** |
| `/horoscope/daily` | POST | ✅ | `{zodiacSign}` | **SSE** |
| `/homepage-fortune-cards` | GET | ❌ | - | Fal kartları vitrin |
| `/fortune-request-types` | GET | ❌ | - | Fal tipleri kataloğu |
| `/fortune-access/check` | POST | ✅ | `{fortuneType}` | Erişim kontrolü |
| `/user/fortunes` | GET | ✅ | - | Fal geçmişi |

**Önemli:** Tüm AI fal endpoint'leri **SSE (Server-Sent Events)** ile streaming yanıt döner. Response `text/event-stream` formatında, her satır bir metin parçası, son event `[DONE]` ile biter.

---

### 2.6 Fortune Teller (Live Advisor) Endpoints

**Base:** `/api/fortune-tellers`, `/api/favorite-tellers`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/fortune-tellers` | GET | ❌ | Falcı listesi (online=true filter) |
| `/fortune-tellers/{tellerId}` | GET | ❌ | Falcı detayı |
| `/fortune-tellers/{tellerId}/reviews` | GET | ❌ | Falcı değerlendirmeleri |
| `/fortune-tellers/{tellerId}/session` | POST | ✅ | Oturum başlat |
| `/fortune-tellers/my-profile` | GET | ✅ | Benim falcı profilim |
| `/fortune-tellers/toggle-online` | GET/POST | ✅ | Çevrimiçi durumu |
| `/fortune-tellers/apply` | POST | ✅ | Falcı başvurusu |
| `/fortune-tellers/sessions` | GET | ✅ | Gelen oturum istekleri |
| `/fortune-tellers/sessions/{sessionId}` | PATCH | ✅ | Oturum durumu güncelle |
| `/fortune-tellers/sessions/stream` | GET | ✅ | **SSE: Gelen talepler** |
| `/favorite-tellers` | GET | ✅ | Favori falcılar |
| `/favorite-tellers` | POST | ✅ | Falcıyı favoriye ekle |

---

### 2.7 Live Fortune Session Endpoints

**Base:** `/api/room`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/room/{sessionId}` | GET | ✅ | Seans bilgisi |
| `/room/{sessionId}` | PATCH | ✅ | Timer, extend, end, ping |
| `/room/{sessionId}/messages` | GET | ✅ | Seans mesajları |
| `/room/{sessionId}/messages` | POST | ✅ | Mesaj gönder |
| `/room/{sessionId}/tip` | POST | ✅ | Bahşiş gönder |
| `/room/{sessionId}/review` | POST | ✅ | Oturum değerlendirmesi |
| `/room/signal` | GET/POST/DELETE | ✅ | P2P sinyali (WebRTC) |
| `/room/{sessionId}/stream` | GET | ✅ | **SSE: Message, timer, status** |

---

### 2.8 Notification Endpoints

**Base:** `/api/notifications`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/notifications` | GET | ✅ | Bildirim listesi (sayfalı) |
| `/notifications` | PATCH | ✅ | Okundu işaretle |
| `/notifications/{id}/read` | PATCH | ✅ | Bildirimi oku |
| `/notifications/stream` | GET | ✅ | **SSE: Gerçek-zamanlı bildirimler** |

---

### 2.9 Gift Endpoints

**Base:** `/api/gifts`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/gifts/types` | GET | ❌ | Hediye kataloğu |
| `/gifts/send` | POST | ✅ | Hediye gönder |
| `/gifts/recent-big` | GET | Soft | Ana sayfa kayan şerit (404 soft) |
| `/gifts/check-reciprocal` | GET | ✅ | Karşılıklı hediye kontrolü |

---

### 2.10 Social Endpoints

**Base:** `/api/social`, `/api/stories`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/social/posts` | GET | ✅ | Akış gönderi listesi |
| `/social/posts` | POST | ✅ | Gönderi yaz |
| `/social/posts/{postId}` | GET | ✅ | Gönderi detayı |
| `/social/posts/{postId}` | DELETE | ✅ | Gönderi sil |
| `/social/posts/{postId}/likes` | POST | ✅ | Beğeni |
| `/social/posts/{postId}/comments` | GET | ✅ | Yorumlar |
| `/social/posts/{postId}/comments` | POST | ✅ | Yorum yaz |
| `/social/posts/{postId}/view` | POST | ✅ | Görüntülenme kaydı |
| `/users/{userId}/posts` | GET | ✅ | Kullanıcı gönderileri |
| `/stories` | GET | ✅ | Hikayeler |

---

### 2.11 Short Video Endpoints

**Base:** `/api/short-videos`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/short-videos` | GET | ❌ | Video listesi |
| `/short-videos/{id}` | GET | ❌ | Video detayı |
| `/short-videos/upload` | POST | ✅ | Video yükle |
| `/short-videos/{id}/like` | POST | ✅ | Beğeni |
| `/short-videos/{id}/comments` | GET | ❌ | Yorumlar |
| `/short-videos/{id}/comments` | POST | ✅ | Yorum yaz |
| `/short-videos/{id}/view` | POST | ✅ | Görüntülenme kaydı |
| `/short-videos/user/{userId}` | GET | ❌ | Kullanıcı videoları |

---

### 2.12 Payment Endpoints

**Base:** `/api`, `/api/payments`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/credit-packages` | GET | ❌ | Kredi paketleri |
| `/payments/methods` | GET | ❌ | Ödeme yöntemleri |
| `/payments/config` | GET | ✅ | Ödeme konfigürasyonu |
| `/payments/requests` | POST | ✅ | Ödeme isteği oluştur |
| `/jeton` | GET | ✅ | Jeton kataloğu |
| `/wallet` | GET | ✅ | Cüzdan bakiyesi |
| `/memberships` | GET | ❌ | Üyelik paketleri |
| `/memberships/purchase` | POST | ✅ | Üyelik satın al |
| `/withdrawals` | POST | ✅ | Para çekme |

---

### 2.13 Search Endpoints

**Base:** `/api/search`

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/search` | GET | ✅ | Genel arama |
| `/search/advanced` | GET | ✅ | Filtreleme ile arama |

---

### 2.14 Diğer Önemli Endpoints

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `/agora/token` | POST | ✅ | Agora RTC token |
| `/trtc/usersig` | POST | ✅ | TRTC UserSig |
| `/trtc/token` | POST | ✅ | TRTC Token |
| `/upload/presigned` | POST | ✅ | Dosya yükleme URL |
| `/announcements` | GET | ✅ | Duyurular |
| `/popups` | GET | ✅ | Popup bildirimleri |
| `/leaderboards` | GET | ❌ | Liderlik tablosu |
| `/homepage-buttons` | GET | ❌ | Ana sayfa butonları |
| `/public-stats` | GET | ❌ | Platform istatistikleri |
| `/celebrities` | GET | ❌ | Ünlüler |
| `/dreams` | GET | ❌ | Rüya katalog |
| `/blog` | GET | ❌ | Blog yazıları |
| `/music/search` | GET | ✅ | Müzik arama |
| `/site-animations/active` | GET | Soft | Animasyon kataloğu |
| `/mobile/config` | GET | ✅ | Mobil konfigürasyonu |
| `/mobile/home` | GET | ✅ | Ana sayfa veri |
| `/mobile/fortune-menu` | GET | ✅ | Fal menüsü |

---

## 3. HTTP Metotları ve Konvansiyonları

| Metot | Amaç | Örnek |
|-------|------|-------|
| **GET** | Veri getir | `/api/chat/rooms` (liste), `/api/user/profile` |
| **POST** | Oluştur / İşlem | `/api/chat/rooms/create`, `/api/fortunes/tarot-fali` |
| **PATCH** | Kısmi güncelle | `/api/user/profile`, `/api/chat/rooms/{id}` |
| **DELETE** | Sil | `/api/social/posts/{postId}` (kılavuz dışında) |

---

## 4. Authentication Detayları

### 4.1 Token Yapısı

- **accessToken:** 7 gün geçerlilik
- **refreshToken:** 30 gün geçerlilik
- **Header Format:** `Authorization: Bearer <accessToken>`

### 4.2 Token Yenileme

```
POST /api/auth/mobile-refresh
Body: { "refreshToken": "..." }
Response: { "accessToken": "...", "refreshToken": "...", "user": {...} }
```

**401 alma kuralı:**
1. Token yenilemeyi dene
2. Başarısız ise login ekranına yönlendir

---

## 5. Error Codes ve Response Formatı

### 5.1 HTTP Status Kodları

| Kod | Anlamı | Davranış |
|-----|--------|----------|
| **200** | Başarı | Normal akış |
| **201** | Oluşturuldu | Başarılı POST |
| **400** | Validation hata | Kullanıcıya mesaj göster |
| **401** | Token geçersiz | Token yenile veya login |
| **403** | Yetkisiz | Erişim reddedildi |
| **404** | Bulunamadı | Kaynak yok |
| **429** | Rate limit | Bekle, tekrar dene |
| **500+** | Sunucu hatası | Retry exponential backoff |

### 5.2 Response Formatı

```json
Başarı:
{
  "data": {...},
  "success": true
}

Hata:
{
  "error": "Türkçe hata mesajı",
  "statusCode": 400
}
```

---

## 6. Real-Time (SSE) Endpoints

### 6.1 Açık SSE Bağlantıları

| Endpoint | Amaç | Event Tipleri |
|----------|------|---------------|
| `/api/chat/rooms/{roomId}/stream` | Oda | message, presence, typing, gift, dj, pk, room_event |
| `/api/video-streams/{streamId}/stream` | Yayın | message, viewer_count, gift, stream_ended |
| `/api/room/{sessionId}/stream` | Fal seans | message, timer_started, time_extended, session_ended |
| `/api/fortune-tellers/sessions/stream` | Gelen talepler | session_request, session_cancelled |
| `/api/notifications/stream` | Bildirimler | notification |

### 6.2 SSE Özelliği

- **Bağlantı:** HTTP/1.1 persistent
- **Format:** `text/event-stream`
- **Heartbeat:** `: heartbeat` satırları (keep-alive)
- **Reconnect:** Exponential backoff (1s → 2s → 4s → 8s → 16s → 30s max)
- **Max attemp:** 20 deneme

---

## 7. Veri Modelleri Özeti

### 7.1 Kullanıcı (User)

```
id, email, name, username, role
image, credits, jetonBalance, cfcBalance
membership, membershipExpiresAt
level, bio, phone, birthDate, birthTime
zodiacSign, referralCode
```

### 7.2 Chat Odası (ChatRoom)

```
id, name, description, type (voice/text/radio)
category, background, isLocked, password
maxUsers, seatCount, ownerId, owner
onlineCount, createdAt
```

### 7.3 Canlı Yayın (VideoStream)

```
id, title, description, status (live/ended)
userId, user, thumbnailUrl, coverUrl
viewerCount, likeCount, commentCount
createdAt
```

### 7.4 Fal (Fortune)

```
Girdi: question, images, birthDate, birthTime, zodiacSign
Çıktı: SSE streaming metin (text/event-stream)
Son event: [DONE]
```

### 7.5 Falcı (FortuneTeller)

```
id, userId, displayName, avatar, bio
specialties, rating, reviewCount
sessionCount, isOnline, creditsPerMinute
status (approved/pending/banned)
```

---

## 8. Eksik/Sorunlu Alanlar

⚠️ **Backend reposu boş olduğu için bu alanlar kurgulanmıştır:**

1. **Gerçek HTTP status kodları** - Kılavuzdan tahmin edilmiştir
2. **Pagsinasyon detayları** - `page`, `limit`, `offset` formatı belirtilmemiştir
3. **Rate limit kuralları** - `/auth/mobile-login` için 429 hatasının eşiği bilinmiyor
4. **Database model sayısı** - Kılavuzda 149 Prisma modeli söylenmiştir (kontrol yok)
5. **N+1 query riskleri** - Detaylı endpoint implementasyonu olmadan tespit edilemedi
6. **Cache stratejisi** - Production'da ETag/Cache-Control kullanımı
7. **Timeout değerleri** - Kılavuzda: 15s connect, 30s receive, 15s send
8. **İdempotency** - Token refresh, çekme işlemleri için idempotency key mekanizması tanımsız

---

## 9. Öneriler

1. **Backend reposu tamaşlanması gerekir** - API implementasyonunun gerçek kontrol edilmesi
2. **OpenAPI dokümentasyonu** - Swagger/OpenAPI standardında formalizasyon
3. **API versioning** - `/api/v2` gibi stratejisi tanımlanmalı
4. **Deprecation policy** - Eski endpoint'ler nasıl kaldırılacak belirtilmeli
5. **Rate limiting detayları** - Endpoint başına kurallar açıklanmalı
6. **CORS konfigürasyonu** - Web ve mobil farklı origins desteklemesi
7. **Logging ve audit** - API kullanımı kayıt stratejisi

---

**Son Güncelleme:** 2026-09-24  
**Preparer:** API Compatibility Audit Tool
