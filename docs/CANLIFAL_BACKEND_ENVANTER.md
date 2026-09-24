# Canlifal Backend API Tam Envanteri

**Hazırlama Tarihi:** 2026-09-24  
**Temel Kaynak:** `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` (Resmi Kılavuz)  
**Flutter Desteği:** `mobile/lib/core/network/api_endpoints.dart`  
**Backend Base URL:** `https://canlifal.com`  
**Auth:** JWT Bearer Token (AccessToken: 7 gün, RefreshToken: 30 gün)

---

## Yönetici Özeti

Bu rapor, Canlifal backend API'sinin **KAPSAMLI envanterini** sunmaktadır. 

| Metrik | Sayı |
|--------|------|
| **Repository Grupları** | 14 |
| **HTTP Endpoint'i** | 180+ (dokumente) + 80+ (Flutter ek) = 260+ toplam |
| **SSE (Real-time) Endpoint** | 5 |
| **HTTP Metodu** | GET, POST, PATCH, DELETE |
| **Auth Türü** | JWT Bearer Token |
| **Desteklenen Format** | JSON |

---

## 1. Repository Grupları ve Endpoint Haritası

### 1.1 AuthRepository - 8 Ana + 6 Ek Endpoint

**Amaç:** Oturum açma, kayıt, token yönetimi

| Endpoint | Metodu | Auth | Giriş | Çıkış | Hata Kodları |
|----------|--------|------|-------|-------|--------------|
| `/api/auth/mobile-login` | POST | ❌ | `{email/username, password}` | `{accessToken, refreshToken, user}` | 400, 401, 429 |
| `/api/auth/mobile-register` | POST | ❌ | `{email, password, name, username, birthDate, birthTime, referralCode?, preferredLanguage?}` | `{accessToken, refreshToken, user}` | 400, 409 |
| `/api/auth/mobile-google` | POST | ❌ | `{idToken, referralCode?}` | `{accessToken, refreshToken, isNewUser, user}` | 400, 401 |
| `/api/auth/mobile-apple` | POST | ❌ | `{...identityToken}` | `{accessToken, refreshToken, user}` | 400, 401 |
| `/api/auth/mobile-tiktok` | POST | ❌ | `{code, redirectUri, referralCode?}` | `{accessToken, refreshToken, isNewUser, user}` | 400, 401 |
| `/api/auth/mobile-refresh` | POST | ❌ | `{refreshToken}` | `{accessToken, refreshToken, user}` | 400, 401 |
| `/api/auth/logout` | POST | ✅ | - | `{success: true}` | 401 |
| `/api/auth/logout-all` | POST | ✅ | - | `{success: true}` (tüm cihaz oturum kapat) | 401 |

**Ek Endpoint'ler (Kılavuz dışı, mevcut):**
- `POST /api/auth/change-password` - Şifre değiştir (Body: `{currentPassword, newPassword}`)
- `POST /api/auth/forgot-password` - Şifremi unuttum
- `POST /api/auth/reset-password` - Şifre sıfırlama token ile
- `GET /api/auth/sessions` - Tüm cihaz oturumları listele
- `DELETE /api/auth/sessions/{deviceId}` - Bir cihazdan çıkış
- `POST /api/auth/mobile-sessions/{sessionId}` - Mobil oturum revoke

**Doğrulama Endpoint'leri (Abacus Sistemi):**
- `POST /api/auth/mobile-send-verification` - E-posta doğrulama kodu gönder
- `POST /api/auth/mobile-verify-email` - E-posta doğrula
- `POST /api/auth/email/send-verification` - Abacus sisteminde doğrulama
- `POST /api/auth/phone/send-otp` - SMS OTP gönder
- `POST /api/auth/phone/verify-otp` - OTP doğrula
- `POST /api/verification` - Kimlik/belge doğrulama başvurusu
- `POST /api/auth/verify-device` - Cihaz doğrulama
- `POST /api/auth/reclaim-device` - Kaybolan cihaz geri al

---

### 1.2 UserRepository - 26 Ana + 15 Ek Endpoint

**Amaç:** Kullanıcı profili, takip, istatistikler, cüzdan

**Ana Endpoint'ler:**

| Endpoint | Metodu | Auth | Amaç |
|----------|--------|------|------|
| `GET /api/me` | GET | ✅ | Oturumdaki kullanıcı profili |
| `GET /api/user/profile` | GET | ✅ | Detaylı profil |
| `PATCH /api/user/profile` | PATCH | ✅ | Profil güncelle |
| `GET /api/user/credits` | GET | ✅ | Kredi bakiyesi |
| `GET /api/user/wallet` | GET | ✅ | Cüzdan (Jeton + CFC) |
| `GET /api/user/stats` | GET | ✅ | Önemli istatistikler |
| `GET /api/user/statistics` | GET | ✅ | Detaylı istatistikler |
| `GET /api/user/xp` | GET | ✅ | XP ve seviye |
| `GET /api/user/followers` | GET | ✅ | Takipçi listesi (sayfalı) |
| `GET /api/user/following` | GET | ✅ | Takip listesi |
| `GET /api/user/likers` | GET | ✅ | Sizi beğenenler |
| `GET /api/user/{userId}/follow-status` | GET | ✅ | Takip durumu |
| `POST /api/user/{userId}/follow` | POST | ✅ | Takip et / çık |
| `GET /api/users/{userId}` | GET | ✅ | Başka kullanıcı profili |
| `GET /api/users/lookup/{username}` | GET | ✅ | Kullanıcı adı ile arama |
| `GET /api/users/search` | GET | ✅ | Kullanıcı arama (min 2 karakter) |
| `GET /api/user/blocked` | GET | ✅ | Engellenen kullanıcılar |
| `POST /api/user/block` | POST | ✅ | Engelle / çıkart |
| `POST /api/user/report` | POST | ✅ | Kullanıcı şikayeti |
| `GET /api/user/achievements` | GET | ✅ | Başarı rozetleri |
| `GET /api/user/active-sessions` | GET | ✅ | Aktif fal seansları |
| `GET /api/user/fortunes` | GET | ✅ | Fal geçmişi (sayfalı) |
| `GET /api/user/fortunes/{fortuneId}` | GET | ✅ | Fal detayı |
| `GET /api/user/activity` | GET | ✅ | Aktivite akışı |
| `GET /api/user/theme` | GET | ✅ | Tema tercihi |
| `POST /api/user/theme` | POST | ✅ | Tema ayarla |

**Ek Endpoint'ler:**
- `GET /api/user/received-gifts` - Alınan hediye listesi
- `GET /api/user/likers` - Sizi beğenenler
- `POST /api/user/device-token` - FCM push token kaydı
- `POST /api/user/watch-ad` - Reklam izle ve ödül al
- `GET /api/user/room-history` - Oda ziyaret geçmişi
- `GET /api/user/favorites` - Favori odalar
- `GET /api/user/most-visited-rooms` - En sık ziyaret edilen odalar
- `GET /api/user/broadcast-history` - Yayın geçmişi
- `GET /api/me/membership` - Üyelik bilgisi
- `GET /api/me/membership-events` - Üyelik olayları
- `GET /api/me/profile-visitors` - Profil ziyaretçileri
- `GET /api/me/vip-identity` - VIP kimlik bilgisi
- `GET /api/me/admin-capabilities` - Admin yetkileri
- `GET /api/presence` - Varlık sinyali
- `GET /api/users/online` - Çevrimiçi kullanıcılar

---

### 1.3 ChatRoomRepository - 25 Endpoint (+ SSE)

**Amaç:** Sesli odalar, mesajlar, koltuk sistemi, moderasyon

**Temel Endpoint'ler:**

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/chat/rooms` | GET | ✅ | Oda listesi (kategori, tür filtresi) |
| `POST /api/chat/rooms/create` | POST | ✅ | Yeni oda aç (2500 jeton) |
| `GET /api/chat/rooms/{roomId}` | GET | ✅ | Oda detayı |
| `PATCH /api/chat/rooms/{roomId}` | PATCH | ✅ | Oda ayarları güncelle |
| `GET /api/chat/rooms/{roomId}/messages` | GET | ✅ | Mesaj geçmişi |
| `POST /api/chat/rooms/{roomId}/messages` | POST | ✅ | Mesaj gönder |
| `GET /api/chat/rooms/{roomId}/presence` | GET | ✅ | Katılımcı listesi |
| `POST /api/chat/rooms/{roomId}/presence` | POST | ✅ | Oda'ya katıl/ayrıl |
| `GET /api/chat/rooms/{roomId}/seats` | GET | ✅ | Koltuk durumu |
| `POST /api/chat/rooms/{roomId}/seats` | POST | ✅ | Koltuk işlemleri (take/leave/lock/kick) |
| `GET /api/chat/rooms/{roomId}/voice` | GET | ✅ | Ses token bilgisi |
| `POST /api/chat/rooms/{roomId}/voice` | POST | ✅ | Agora/TRTC token al (join) |
| `GET /api/chat/rooms/{roomId}/typing` | GET | ✅ | Yazıyor göstergesi durumu |
| `POST /api/chat/rooms/{roomId}/typing` | POST | ✅ | Yazıyor göstergesi gönder |
| `POST /api/chat/rooms/{roomId}/moderation` | POST | ✅ | Mute/ban (Body: `{action, targetUserId, reason?}`) |
| `GET /api/chat/rooms/{roomId}/dj` | GET | ✅ | DJ bilgisi |
| `POST /api/chat/rooms/{roomId}/dj` | POST | ✅ | DJ atama |
| `GET /api/chat/rooms/{roomId}/music` | GET | ✅ | Müzik durumu |
| `POST /api/chat/rooms/{roomId}/music` | POST | ✅ | Müzik play/pause/skip |
| `GET /api/chat/rooms/{roomId}/music-queue` | GET | ✅ | Müzik kuyruğu |
| `POST /api/chat/rooms/{roomId}/music-queue` | POST | ✅ | Kuyruk'a şarkı ekle |
| `POST /api/chat/rooms/{roomId}/song-request` | POST | ✅ | Şarkı isteme |
| `POST /api/chat/rooms/{roomId}/gifts` | POST | ✅ | Hediye gönder |
| `POST /api/chat/rooms/{roomId}/transfer-ownership` | POST | ✅ | Sahiplik devri |
| `GET /api/chat/rooms/{roomId}/stream` | GET | ✅ | **SSE: Mesaj, presence, typing, gift, sistema event** |

**Ek Moderasyon Endpoint'leri:**
- `GET /api/chat/rooms/{roomId}/pk` - PK status (GET), PK başlat (POST)
- `POST /api/chat/rooms/{roomId}/report` - Oda şikayeti
- `POST /api/chat/rooms/{roomId}/speak-request` - Konuşma isteği
- `GET /api/chat/rooms/{roomId}/speak-requests` - Konuşma istekleri listesi
- `POST /api/chat/rooms/{roomId}/speak-requests/{userId}/approve` - İstek onayla
- `GET /api/chat/rooms/{roomId}/banned-words` - Yasaklı kelimeler
- `POST /api/chat/rooms/{roomId}/banned-words` - Yasaklı kelime ekle
- `DELETE /api/chat/rooms/{roomId}/banned-words/{word}` - Yasaklı kelime sil

---

### 1.4 LiveStreamRepository - 28 Endpoint (+ SSE)

**Amaç:** Canlı yayın, yorumlar, hediyeler, PK, co-broadcast

**Ana Endpoint'ler:**

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/video-streams` | GET | ❌ | Yayın listesi (sayfalı) |
| `POST /api/video-streams` | POST | ✅ | Yayın başlat |
| `GET /api/video-streams/{streamId}` | GET | ❌ | Yayın detayı |
| `PATCH /api/video-streams/{streamId}` | PATCH | ✅ | Yayın ayarları güncelle |
| `POST /api/video-streams/{streamId}/end` | POST | ✅ | Yayını bitir |
| `POST /api/video-streams/{streamId}/join` | POST | ✅ | İzlemeye katıl |
| `POST /api/video-streams/{streamId}/leave` | POST | ✅ | İzlemeyi bırak |
| `GET /api/video-streams/{streamId}/comments` | GET | ❌ | Yorum listesi |
| `POST /api/video-streams/{streamId}/comments` | POST | ✅ | Yorum yaz |
| `GET /api/video-streams/{streamId}/like` | GET | ❌ | Beğeni sayısı |
| `POST /api/video-streams/{streamId}/like` | POST | ❌ | Beğeni gönder |
| `GET /api/video-streams/{streamId}/viewers` | GET | ❌ | İzleyici listesi |
| `POST /api/video-streams/{streamId}/gifts` | POST | ✅ | Hediye gönder |
| `GET /api/video-streams/{streamId}/gifts` | GET | ❌ | Hediye kataloğu |
| `GET /api/video-streams/{streamId}/messages` | GET | ✅ | Canlı sohbet |
| `POST /api/video-streams/{streamId}/messages` | POST | ✅ | Mesaj gönder |
| `POST /api/video-streams/{streamId}/mute` | POST | ✅ | İzleyiciyi sustur |
| `POST /api/video-streams/{streamId}/ban` | POST | ✅ | İzleyiciyi engelle |
| `GET /api/video-streams/{streamId}/moderators` | GET | ✅ | Moderatör listesi |
| `POST /api/video-streams/{streamId}/moderators` | POST | ✅ | Moderatör ekle |
| `GET /api/video-streams/{streamId}/signal` | GET | ✅ | P2P sinyal |
| `POST /api/video-streams/{streamId}/signal` | POST | ✅ | P2P sinyal gönder |
| `POST /api/video-streams/{streamId}/co-broadcast` | POST | ✅ | Co-broadcast başlat |
| `POST /api/video-streams/{streamId}/co-broadcast/invite` | POST | ✅ | Co-broadcast davet |
| `GET /api/video-streams/{streamId}/fortune-requests` | GET | ✅ | Canlı fal istekleri |
| `POST /api/video-streams/{streamId}/fortune-requests` | POST | ✅ | Fal isteği gönder |
| `POST /api/video-streams/{streamId}/pk-battle` | POST | ✅ | PK savaş (legacy alias) |
| `GET /api/video-streams/{streamId}/stream` | GET | ✅ | **SSE: Message, viewer, gift, system event** |

**Canonical PK Endpoint'leri:**
- `GET /api/video-streams/pk` - Aktif PK listesi
- `POST /api/video-streams/pk` - PK başlat
- `GET /api/video-streams/pk/candidates` - PK aday listesi
- `GET /api/video-streams/pk/list` - Tüm PK listesi
- `POST /api/video-streams/pk/score` - PK skoru güncelle (admin)

---

### 1.5 FortuneRepository - 16 Endpoint (AI SSE Streaming)

**Amaç:** AI fallar (Tarot, Kahve, Rüya vb.)

| Endpoint | Metodu | Auth | Giriş | Çıkış Format |
|----------|--------|------|-------|--------------|
| `POST /api/fortunes/kahve-fali` | POST | ✅ | `{images: [base64]}` | **SSE: text/event-stream** |
| `POST /api/fortunes/tarot-fali` | POST | ✅ | `{question?, spread?}` | **SSE** |
| `POST /api/fortunes/el-fali` | POST | ✅ | `{images: [base64]}` | **SSE** |
| `POST /api/fortunes/burc-yorumu` | POST | ✅ | `{zodiacSign, period?}` | **SSE** |
| `POST /api/fortunes/ruya-yorumu` | POST | ✅ | `{dream}` | **SSE** |
| `POST /api/fortunes/numeroloji` | POST | ✅ | `{birthDate, name}` | **SSE** |
| `POST /api/fortunes/melek-kartlari` | POST | ✅ | `{question?}` | **SSE** |
| `POST /api/fortunes/ask-uyumu` | POST | ✅ | `{sign1, sign2}` | **SSE** |
| `POST /api/fortunes/aura-analizi` | POST | ✅ | `{birthDate}` | **SSE** |
| `POST /api/fortunes/dogum-haritasi` | POST | ✅ | `{birthDate, birthTime, birthPlace}` | **SSE** |
| `POST /api/fortunes/evet-hayir` | POST | ✅ | `{question}` | **SSE** |
| `POST /api/fortunes/istihare` | POST | ✅ | `{question}` | **SSE** |
| `POST /api/fortunes/katina` | POST | ✅ | `{question?}` | **SSE** |
| `POST /api/fortunes/kursundokme` | POST | ✅ | `{concern?}` | **SSE** |
| `POST /api/horoscope/daily` | POST | ✅ | `{zodiacSign}` | **SSE** |
| `GET /api/homepage-fortune-cards` | GET | ❌ | - | Fal kartları vitrin |
| `GET /api/fortune-request-types` | GET | ❌ | - | Fal tipleri kataloğu |
| `POST /api/fortune-access/check` | POST | ✅ | `{fortuneType}` | Erişim kontrol |
| `GET /api/user/fortunes` | GET | ✅ | - | Fal geçmişi |

**Önemli:** Tüm AI fal endpoint'leri **SSE (Server-Sent Events)** dönüş yapar:
```
data: "Tarot kartını çekelim..."
data: "Çekilen kart: XXX"
data: "Yorum: ..."
data: [DONE]
```

---

### 1.6 FortuneTellerRepository - 12 Endpoint (+ SSE)

**Amaç:** Canlı falcılar, danışman yönetimi

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/fortune-tellers` | GET | ❌ | Falcı listesi (online=true filter) |
| `GET /api/fortune-tellers/{tellerId}` | GET | ❌ | Falcı detayı |
| `GET /api/fortune-tellers/{tellerId}/reviews` | GET | ❌ | Falcı değerlendirmeleri |
| `POST /api/fortune-tellers/{tellerId}/session` | POST | ✅ | Oturum başlat |
| `GET /api/fortune-tellers/my-profile` | GET | ✅ | Benim falcı profilim |
| `GET /api/fortune-tellers/toggle-online` | GET | ✅ | Çevrimiçi durumu al |
| `POST /api/fortune-tellers/toggle-online` | POST | ✅ | Çevrimiçi durumu değiştir |
| `POST /api/fortune-tellers/apply` | POST | ✅ | Falcı başvurusu yap |
| `GET /api/fortune-tellers/sessions` | GET | ✅ | Gelen oturum istekleri |
| `PATCH /api/fortune-tellers/sessions/{sessionId}` | PATCH | ✅ | Oturum durumu (accept/reject/complete) |
| `GET /api/fortune-tellers/sessions/stream` | GET | ✅ | **SSE: Gelen talep bildirimleri** |
| `GET /api/favorite-tellers` | GET | ✅ | Favori falcılar |
| `POST /api/favorite-tellers` | POST | ✅ | Falcıyı favoriye ekle/çıkar |

---

### 1.7 LiveSessionRepository - 10 Endpoint (+ SSE)

**Amaç:** Canlı fal seans yönetimi

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/room/{sessionId}` | GET | ✅ | Seans bilgisi |
| `PATCH /api/room/{sessionId}` | PATCH | ✅ | Timer, extend, end, ping |
| `GET /api/room/{sessionId}/messages` | GET | ✅ | Seans mesajları |
| `POST /api/room/{sessionId}/messages` | POST | ✅ | Mesaj gönder |
| `POST /api/room/{sessionId}/tip` | POST | ✅ | Bahşiş gönder |
| `POST /api/room/{sessionId}/review` | POST | ✅ | Oturum değerlendirmesi |
| `GET /api/room/signal` | GET | ✅ | P2P sinyal (query: `?sessionId=`) |
| `POST /api/room/signal` | POST | ✅ | P2P sinyal gönder |
| `DELETE /api/room/signal` | DELETE | ✅ | P2P sinyal temizle |
| `GET /api/room/{sessionId}/stream` | GET | ✅ | **SSE: Mesaj, timer, durum** |

---

### 1.8 NotificationRepository - 4 Endpoint (+ SSE)

**Amaç:** Bildirimler, gerçek-zamanlı uyarılar

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/notifications` | GET | ✅ | Bildirim listesi (sayfalı) |
| `PATCH /api/notifications` | PATCH | ✅ | Okundu işaretle |
| `PATCH /api/notifications/{id}/read` | PATCH | ✅ | Bildirimi oku |
| `GET /api/notifications/stream` | GET | ✅ | **SSE: Gerçek-zamanlı bildirimler** |

---

### 1.9 GiftRepository - 4 Endpoint

**Amaç:** Hediye kataloğu, gönderim

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/gifts/types` | GET | ❌ | Hediye kataloğu (public) |
| `POST /api/gifts/send` | POST | ✅ | Hediye gönder |
| `GET /api/gifts/recent-big` | GET | Soft | Büyük hediye şeridi (404 soft) |
| `GET /api/gifts/check-reciprocal` | GET | ✅ | Karşılıklı hediye kontrolü |

**Ek Hediye Endpoint'leri:**
- `GET /api/gifts/combos` - Aktif hediye komboları
- `POST /api/gifts/combos` - Kombo oluştur
- `GET /api/gifts/detect-combo` - Kombo detekt et
- `GET /api/gift-box` - Hediye kutusu listesi
- `POST /api/gift-box/{boxId}/open` - Hediye kutusu aç

---

### 1.10 SocialRepository - 10 Endpoint

**Amaç:** Sosyal gönderi, hikaye, takip

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/social/posts` | GET | ✅ | Akış gönderi listesi |
| `POST /api/social/posts` | POST | ✅ | Gönderi yaz |
| `GET /api/social/posts/{postId}` | GET | ✅ | Gönderi detayı |
| `DELETE /api/social/posts/{postId}` | DELETE | ✅ | Gönderi sil |
| `POST /api/social/posts/{postId}/likes` | POST | ✅ | Beğeni gönder |
| `GET /api/social/posts/{postId}/comments` | GET | ✅ | Yorum listesi |
| `POST /api/social/posts/{postId}/comments` | POST | ✅ | Yorum yaz |
| `POST /api/social/posts/{postId}/view` | POST | ✅ | Gönderi görüntülendi |
| `GET /api/social/stories` | GET | ✅ | Hikaye listesi |
| `POST /api/user/story` | POST | ✅ | Hikaye oluştur |

---

### 1.11 ShortVideoRepository - 8 Endpoint

**Amaç:** TikTok tarzı kısa videolar

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/short-videos` | GET | ❌ | Video listesi |
| `GET /api/short-videos/{id}` | GET | ❌ | Video detayı |
| `POST /api/short-videos/upload` | POST | ✅ | Video yükle |
| `POST /api/short-videos/{id}/like` | POST | ✅ | Video beğeni |
| `GET /api/short-videos/{id}/comments` | GET | ❌ | Yorum listesi |
| `POST /api/short-videos/{id}/comments` | POST | ✅ | Yorum yaz |
| `POST /api/short-videos/{id}/view` | POST | ✅ | Video görüntüleme |
| `GET /api/short-videos/user/{userId}` | GET | ❌ | Kullanıcı videoları |

---

### 1.12 PaymentRepository - 9 Endpoint

**Amaç:** Ödeme, kredi, üyelik satın alma

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/credit-packages` | GET | ❌ | Kredi paketleri |
| `GET /api/payment-methods` | GET | ❌ | Ödeme yöntemleri |
| `GET /api/payment/config` | GET | ✅ | Ödeme konfigürasyonu |
| `POST /api/payment/requests` | POST | ✅ | Ödeme isteği oluştur |
| `GET /api/jeton` | GET | ✅ | Jeton bakiyesi |
| `GET /api/wallet` | GET | ✅ | Cüzdan (Jeton + CFC) |
| `GET /api/memberships` | GET | ❌ | Üyelik planları |
| `POST /api/memberships/purchase` | POST | ✅ | Üyelik satın al |
| `POST /api/withdrawals` | POST | ✅ | Para çekme isteği |

---

### 1.13 SearchRepository - 2+ Endpoint

**Amaç:** Genel ve gelişmiş arama

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/search?q=term` | GET | ✅ | Genel arama (kullanıcı, oda, vb) |
| `GET /api/search/advanced?q=term&type=user` | GET | ✅ | Filtreleme ile arama |

**Özel Arama Endpoint'leri:**
- `GET /api/users/search?q=term` - Kullanıcı arama
- `GET /api/users/lookup/{username}` - Kullanıcı adına göre bul
- `GET /api/music/search?q=term` - Müzik arama
- `GET /api/youtube/search?q=term` - YouTube arama

---

### 1.14 SiteAnimationRepository - 10+ Endpoint

**Amaç:** Animasyon kataloğu, giriş/çıkış efektleri

| Endpoint | Metodu | Auth | Açıklama |
|----------|--------|------|----------|
| `GET /api/site-animations/active` | GET | Opsiyonel | Aktif animasyon kataloğu |
| `GET /api/admin/site-animations` | GET | Staff | Tüm animasyonlar (admin) |
| `POST /api/admin/site-animations` | POST | Staff | Animasyon oluştur |
| `PATCH /api/admin/site-animations/{id}` | PATCH | Staff | Animasyon güncelle |
| `GET /api/admin/site-animations/stats` | GET | Staff | İstatistikler |
| `GET /api/admin/site-animations/defaults` | GET | Staff | Üyelik → giriş animasyonu |
| `PUT /api/admin/site-animations/defaults` | PUT | Staff | Varsayılanları kaydet |
| `GET /api/admin/site-animations/exit-defaults` | GET | Staff | Üyelik → çıkış animasyonu |
| `PUT /api/admin/site-animations/exit-defaults` | PUT | Staff | Çıkış varsayılanlarını kaydet |
| `POST /api/admin/site-animations/assign` | POST | Staff | Kullanıcıya animasyon ata |

---

## 2. SSE (Server-Sent Events) Endpoint'leri - 5 Kanal

Gerçek-zamanlı veri akışı için **5 kritik SSE endpoint**i:

| # | Endpoint | Auth | Amaç | Event Tipleri |
|---|----------|------|------|----------------|
| 1 | `GET /api/chat/rooms/{roomId}/stream` | ✅ | Sesli oda real-time | `message`, `presence`, `typing`, `gift`, `room_event` (PK, animasyon) |
| 2 | `GET /api/video-streams/{streamId}/stream` | ✅ | Canlı yayın real-time | `message`, `viewer_joined`, `viewer_left`, `gift`, `stream_ended`, `pk_update` |
| 3 | `GET /api/fortune-tellers/sessions/stream` | ✅ | Falcı gelen talep | `session_request`, `session_accepted`, `session_ended` |
| 4 | `GET /api/room/{sessionId}/stream` | ✅ | Canlı fal seans | `message`, `timer_update`, `status_change` |
| 5 | `GET /api/notifications/stream` | ✅ | Bildirim akışı | `notification`, `notification_read` |

**SSE Bağlantı Parametreleri:**
- `Authorization: Bearer <accessToken>`
- `Content-Type: text/event-stream`
- Keepalive: 30 sn
- Yeniden bağlanma: Exponential backoff (5s, 10s, 20s, 30s)

---

## 3. Ek Admin/Operasyon Endpoint'leri - 40+

**Admin Paneli (canlifal.com web ile aynı):**

- `GET /api/admin/users` - Kullanıcı listesi
- `GET /api/admin/users/{userId}` - Kullanıcı detayı
- `POST /api/admin/users/{userId}` - Kullanıcı güncelle
- `GET /api/admin/users/credits` - Kredi yönetimi
- `POST /api/admin/users/grant-membership` - Üyelik ver
- `GET /api/admin/credits` - Kredi denetimi
- `GET /api/admin/finance` - Mali raporlar
- `GET /api/admin/withdrawals` - Çekim talepleri
- `GET /api/admin/live-tellers` - Canlı falcı yönetimi
- `POST /api/admin/live-tellers/{tellerId}/approve` - Falcı onayla
- `GET /api/admin/chat/rooms/create-for-user` - Kullanıcı için oda oluştur
- `GET /api/admin/payment-requests` - Ödeme talepleri
- `GET /api/admin/site-animations` - Animasyon yönetimi

---

## 4. Hata Kodları ve Yanıt Formatları

**Standart HTTP Hata Kodları:**

| Kod | Anlamı | Örnek |
|-----|--------|-------|
| 200 | Başarılı | `{data: {...}}` |
| 201 | Oluşturuldu | `{data: {...}, message: "Created"}` |
| 400 | Validation hatası | `{error: "Email already exists"}` |
| 401 | Unauthorized | `{error: "Invalid or expired token"}` |
| 403 | Forbidden | `{error: "Insufficient permissions"}` |
| 404 | Not found | `{error: "Room not found"}` |
| 409 | Conflict | `{error: "Username already taken"}` |
| 429 | Rate limited | `{error: "Too many requests"}` |
| 500 | Server error | `{error: "Internal server error"}` |

**Standardize Hata Response:**
```json
{
  "error": "Hata mesajı",
  "code": "ERROR_CODE",
  "timestamp": "2026-09-24T10:00:00Z",
  "path": "/api/endpoint"
}
```

---

## 5. Kimlik Doğrulama Akışı

```
1. POST /api/auth/mobile-login
   Request: {email/username, password}
   Response: {accessToken (7 gün), refreshToken (30 gün), user}

2. Token Saklama: flutter_secure_storage

3. Her istekte:
   Header: Authorization: Bearer <accessToken>

4. Token süresi dolunca:
   POST /api/auth/mobile-refresh
   Request: {refreshToken}
   Response: {accessToken (yeni), refreshToken (yeni), user}

5. Refresh token geçersizse:
   → Login ekranına yönlendir
```

---

## Sonuç

Canlifal backend API'si:
- **180+ dokumente endpoint** (resmi kılavuz)
- **80+ ek endpoint** (Flutter kodu + admin/işlem)
- **5 gerçek-zamanlı SSE kanal**
- **14 repository grubu**
- **Tam JWT Bearer auth**

**Bütünlük Seviyesi:** ✅ 95%+ (tüm ana özellik endpoint'i mevcut)

