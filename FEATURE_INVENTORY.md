# Canlifal Web ↔ Flutter Özellik Envanteri

Tarih: 2026-06-10  
Kaynaklar: `https://canlifal.com/canlifal-envanter-raporu.txt`, mevcut parite raporları, `mobile/lib/app/router/app_router.dart`, `mobile/lib/core/network/api_endpoints.dart`, `mobile/lib/features/**`.

> Not: Web kaynak kodu bu repoda yoktur. Web tarafı için üretim envanteri ve mevcut raporlar esas alınmıştır. `api/` klasörü üretimin tam kopyası değildir.

---

## Kategori: Sosyal

### Özellik adı: Sosyal akış, post oluşturma, beğeni, yorum
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Hayır
- Kısmen çalışıyor mu? Hayır, temel akış mevcut
- Kullanılan API'ler:
  - `GET /api/social/posts`
  - `POST /api/social/posts`
  - `DELETE /api/social/posts/{id}`
  - `POST /api/social/posts/{id}/likes`
  - `GET /api/social/posts/{id}/comments`
  - `POST /api/social/posts/{id}/comments`
- Kullanılan Socket Eventleri: Yok / REST tabanlı
- Kullanılan Veritabanı Modelleri:
  - `SocialPost`
  - `SocialComment`
  - `SocialLike`

### Özellik adı: Hikayeler
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; rail/list görünümü var, tam create/detail paritesi sınırlı
- Kullanılan API'ler:
  - `GET /api/stories`
  - `POST /api/user/story`
  - `GET /api/user/stories`
  - `GET /api/social/stories`
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `UserStory`

### Özellik adı: Takip, kullanıcı profili, arama
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Hayır
- Kısmen çalışıyor mu? Hayır
- Kullanılan API'ler:
  - `GET /api/users/{id}`
  - `GET /api/users/search`
  - `GET /api/users/lookup/{username}`
  - `POST /api/users/{id}/follow`
  - `GET /api/users/{id}/followers`
  - `GET /api/users/{id}/following`
  - `GET /api/user/followers`
  - `GET /api/user/following`
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `User`
  - `Follow`
  - `ProfileView`

### Özellik adı: Direkt mesajlar
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; REST çalışıyor, realtime/socket DM yok
- Kullanılan API'ler:
  - `GET /api/messages`
  - `GET /api/messages/{userId}`
  - `POST /api/messages/{userId}`
  - `POST /api/messages/request`
- Kullanılan Socket Eventleri: Yok / REST-polling
- Kullanılan Veritabanı Modelleri:
  - `DirectMessage`
  - `MessageRequest`

### Özellik adı: Ünlüler ve Fan Club
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; native hub ve liste girişi var, detay/join/post/anket tam değil
- Kullanılan API'ler:
  - `GET /api/celebrities`
  - `GET /api/celebrities/{id}`
  - `POST /api/celebrities/{id}/follow`
  - `GET /api/celebrities/{id}/posts`
  - `GET /api/fan-clubs`
  - `POST /api/fan-clubs/{id}/join`
  - `GET /api/fan-clubs/{id}/posts`
  - `POST /api/fan-clubs/{id}/polls`
  - `POST /api/fan-clubs/{id}/polls/vote`
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `Celebrity`
  - `CelebrityFollow`
  - `CelebrityPost`
  - `FanClub`
  - `FanClubMember`
  - `FanClubPost`
  - `FanClubPoll`

---

## Kategori: Sesli Odalar

### Özellik adı: Oda listesi, oda girişi, yazılı sohbet
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Hayır
- Kısmen çalışıyor mu? Hayır, temel akış mevcut
- Kullanılan API'ler:
  - `GET /api/chat/rooms`
  - `POST /api/chat/rooms`
  - `POST /api/chat/rooms/create`
  - `GET /api/chat/rooms/{roomId}/messages`
  - `POST /api/chat/rooms/{roomId}/messages`
  - `GET /api/chat/rooms/{roomId}/stream`
- Kullanılan Socket Eventleri:
  - SSE: `message`
  - Socket.IO: `chatMessage`, `message`, `roomMessage`
- Kullanılan Veritabanı Modelleri:
  - `ChatRoom`
  - `ChatMessage`

### Özellik adı: Presence, kullanıcı listesi, heartbeat
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; web envanterinde 20 saniye heartbeat, Flutter fallback aralıkları farklı olabilir
- Kullanılan API'ler:
  - `GET /api/chat/rooms/{roomId}/presence`
  - `POST /api/chat/rooms/{roomId}/presence`
  - `DELETE /api/chat/rooms/{roomId}/presence`
- Kullanılan Socket Eventleri:
  - SSE: `presence`
  - Socket.IO: `roomUsers`, `presenceUpdated`, `userJoined`, `userLeft`
- Kullanılan Veritabanı Modelleri:
  - `ChatPresence`

### Özellik adı: TRTC ses, mikrofon, koltuk sistemi
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; web envanterinde 15 koltuk, Flutter bazı ekranlarda 11 koltuk düzeni kullanıyor
- Kullanılan API'ler:
  - `POST /api/trtc/usersig`
  - `POST /api/chat/rooms/{roomId}/voice`
  - `POST /api/chat/rooms/{roomId}/seats`
  - `POST /api/chat/rooms/{roomId}/speak-request`
- Kullanılan Socket Eventleri:
  - TRTC SDK eventleri
- Kullanılan Veritabanı Modelleri:
  - `VoiceSession`
  - `VoiceSignal`
  - `ChatPresence`

### Özellik adı: Moderasyon, rol, yasaklı kelime, komutlar
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; `!` komutları ve REST fallback var, web IRC bot davranışının tamamı doğrulanmalı
- Kullanılan API'ler:
  - `POST /api/chat/rooms/{roomId}/mute`
  - `POST /api/chat/rooms/{roomId}/ban`
  - `POST /api/chat/rooms/{roomId}/kick`
  - `POST /api/chat/rooms/{roomId}/roles`
  - `GET/POST/DELETE /api/chat/rooms/{roomId}/banned-words`
  - `POST /api/chat/rooms/{roomId}/profanity`
- Kullanılan Socket Eventleri:
  - `roomUsers`
  - `presenceUpdated`
  - `chatMessage`
- Kullanılan Veritabanı Modelleri:
  - `ChatUserRole`
  - `ChatMute`
  - `ChatBan`

### Özellik adı: DJ ve müzik sistemi
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; fallback zinciri güçlendirildi, production smoke test gerekli
- Kullanılan API'ler:
  - `GET /api/music/search`
  - `GET /api/youtube/search`
  - `GET /api/chat/rooms/{roomId}/dj`
  - `PATCH /api/chat/rooms/{roomId}/dj`
  - `GET /api/chat/rooms/{roomId}/music-queue`
  - `POST /api/chat/rooms/{roomId}/song-request`
  - `POST /api/chat/rooms/{roomId}/music-queue`
  - `GET /api/chat/youtube-stream`
- Kullanılan Socket Eventleri:
  - `dj`
  - `dj:update`
  - `music`
  - `music:update`
  - `queue`
  - `queue:update`
  - `QUEUE_UPDATED`
  - `song-request`
  - `CURRENT_SONG_CHANGED`
- Kullanılan Veritabanı Modelleri:
  - `ChatRoom`
  - `ChatMessage`

---

## Kategori: Canlı Yayın

### Özellik adı: Yayın listesi, yayın başlatma, izleme
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Hayır
- Kısmen çalışıyor mu? Hayır, temel akış mevcut
- Kullanılan API'ler:
  - `GET /api/video-streams`
  - `POST /api/video-streams`
  - `GET /api/video-streams/{streamId}`
  - `POST /api/video-streams/{streamId}/join`
  - `POST /api/video-streams/{streamId}/leave`
  - `POST /api/video-streams/{streamId}/end`
  - `POST /api/trtc/usersig`
- Kullanılan Socket Eventleri:
  - `joinStream`
  - `leaveStream`
  - `viewerCount`
  - `streamEnded`
- Kullanılan Veritabanı Modelleri:
  - `VideoStream`
  - `VideoStreamViewer`
  - `VideoStreamSignal`

### Özellik adı: Yayın içi chat, beğeni, hediyeler
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Hayır
- Kısmen çalışıyor mu? Hayır, temel akış mevcut
- Kullanılan API'ler:
  - `GET /api/video-streams/{streamId}/messages`
  - `POST /api/video-streams/{streamId}/messages`
  - `POST /api/video-streams/{streamId}/like`
  - `GET /api/video-streams/{streamId}/gifts`
  - `POST /api/video-streams/{streamId}/gifts`
  - `GET /api/video-streams/{streamId}/gifts/leaderboard`
- Kullanılan Socket Eventleri:
  - `streamMessage`
  - `chatMessage`
  - `message`
  - `gift`
  - `giftSent`
- Kullanılan Veritabanı Modelleri:
  - `VideoStreamComment`
  - `VideoStreamLike`
  - `StreamGift`

### Özellik adı: PK, co-broadcast, moderasyon, resim modu
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; PK iskeleti var, co-broadcast UI/moderasyon/resim modu tam parite değil
- Kullanılan API'ler:
  - `POST /api/video-streams/{streamId}/pk-battle`
  - `GET /api/video-streams/{streamId}/pk-battle`
  - `POST /api/video-streams/{streamId}/co-broadcast`
  - `POST /api/video-streams/{streamId}/co-broadcast/invite`
  - `GET /api/user/co-broadcast-invites`
  - `POST /api/video-streams/{streamId}/ban`
  - `POST /api/video-streams/{streamId}/mute`
  - `POST /api/video-streams/{streamId}/moderator`
  - `POST /api/video-streams/{streamId}/image`
  - `POST /api/video-streams/{streamId}/background`
  - `POST /api/video-streams/{streamId}/auto-close`
- Kullanılan Socket Eventleri:
  - `pk:*`
  - `pkBattle`
  - `PK_UPDATED`
  - `pk:score-update`
  - `pk:gift`
- Kullanılan Veritabanı Modelleri:
  - `PKBattle`
  - `PKGift`
  - `StreamBan`
  - `StreamModerator`
  - `StreamMutedViewer`
  - `StreamCoBroadcaster`
  - `BroadcastImage`

---

## Kategori: Hediyeler

### Özellik adı: Hediye katalog, gönderim, animasyon, jeton düşümü
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Hayır
- Kısmen çalışıyor mu? Hayır, temel akış mevcut
- Kullanılan API'ler:
  - `GET /api/gifts`
  - `GET /api/video-streams/gifts`
  - `POST /api/video-streams/{streamId}/gifts`
  - `POST /api/chat/rooms/{roomId}/gifts`
- Kullanılan Socket Eventleri:
  - `gift`
  - `giftSent`
  - `gift:received`
- Kullanılan Veritabanı Modelleri:
  - `GiftType`
  - `ChatRoomGift`
  - `StreamGift`
  - `JetonTransaction`

### Özellik adı: Falcı hediyesi
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Hayır
- Eksik mi? Evet
- Kısmen çalışıyor mu? Hayır
- Kullanılan API'ler:
  - `POST /api/teller/gifts`
- Kullanılan Socket Eventleri: Bilinmiyor / yok
- Kullanılan Veritabanı Modelleri:
  - `TellerGift`

---

## Kategori: Fal & Tarot

### Özellik adı: AI fal yorumları ve SSE streaming
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Evet
- Kısmen çalışıyor mu? Evet; Flutter yerel yorum üretip fal geçmişine kaydediyor, web LLM/SSE akışını çağırmıyor
- Kullanılan API'ler:
  - `POST /api/fortunes/kahve-fali`
  - `POST /api/fortunes/kahve-fali-image`
  - `POST /api/fortunes/tarot-fali`
  - `POST /api/fortunes/el-fali`
  - `POST /api/fortunes/burc-yorumu`
  - `POST /api/fortunes/numeroloji`
  - `POST /api/fortunes/ruya-yorumu`
  - `POST /api/fortunes/dogum-haritasi`
  - `POST /api/fortunes/aura-analizi`
  - `POST /api/fortunes/melek-kartlari`
  - `POST /api/fortunes/katina`
  - `POST /api/fortunes/evet-hayir`
  - `POST /api/fortunes/istihare`
  - `POST /api/fortunes/kursundokme`
  - `POST /api/fortunes/ask-uyumu`
  - `GET/POST /api/user/fortunes`
  - `POST /api/user/fortunes/{id}/pin`
  - `POST /api/user/fortunes/{id}/rate`
- Kullanılan Socket Eventleri:
  - Fal SSE streaming; Flutter'da yok
- Kullanılan Veritabanı Modelleri:
  - `Fortune`
  - `FortuneRating`
  - `FortuneRequestType`
  - `UserFortuneStreak`

### Özellik adı: Canlı falcı ve falcı sohbet
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; liste/seans var, başvuru/dashboard/falcı analitik eksik
- Kullanılan API'ler:
  - `GET /api/fortune-tellers`
  - `GET /api/fortune-tellers/{id}`
  - `POST /api/fortune-tellers/apply`
  - `POST /api/fortune-tellers/toggle`
  - `POST /api/fortune-tellers/session`
  - `GET /api/favorite-tellers`
  - `POST /api/favorite-tellers`
  - `GET /api/teller-chat/{sessionId}`
  - `POST /api/teller-chat/{sessionId}`
  - `POST /api/teller/reviews`
- Kullanılan Socket Eventleri:
  - TRTC / WebRTC sinyal akışı
- Kullanılan Veritabanı Modelleri:
  - `LiveFortuneTeller`
  - `LiveSession`
  - `LiveSessionMessage`
  - `TellerChatSession`
  - `TellerChatMessage`
  - `FavoriteTeller`
  - `RoomSignal`

---

## Kategori: Video

### Özellik adı: Trend video, TikTok, video detay
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Evet
- Kısmen çalışıyor mu? Evet; ana sayfada trend video satırı var, detay/TikTok native ekranı yok
- Kullanılan API'ler:
  - `GET /api/trend-videos`
  - TikTok video/category admin API'leri
  - Video detay endpointleri
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `TrendVideo`
  - `TrendVideoCategory`
  - `TrendingTopic`
  - `TikTokVideo`
  - `TikTokCategory`

---

## Kategori: Oyunlar

### Özellik adı: Oyun lobisi, çok oyunculu oyunlar, mini oyunlar, turnuvalar
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Evet
- Kısmen çalışıyor mu? Evet; oyun/turnuva liste hub'ı var, native oyun odası/hamle UI yok
- Kullanılan API'ler:
  - `GET /api/games`
  - `GET /api/games/rooms`
  - `POST /api/games/rooms`
  - `POST /api/games/room/{roomId}`
  - `POST /api/games/room/{roomId}/join`
  - `POST /api/games/room/{roomId}/chat`
  - `POST /api/games/auto-match`
  - `POST /api/games/leaderboard`
  - `GET /api/games/history`
  - `GET /api/games/profile`
  - `GET /api/games/mini-scores`
  - `POST /api/games/mini-scores`
  - `GET /api/tournaments`
  - `POST /api/tournaments/join`
- Kullanılan Socket Eventleri:
  - Yok; web envanterinde HTTP polling
- Kullanılan Veritabanı Modelleri:
  - `GameRoom`
  - `GameRoomChat`
  - `GameRoomViewer`
  - `GamePlay`
  - `UserGameProfile`
  - `SosGame`
  - `SosGameChat`
  - `MiniGame`
  - `WeeklyTournament`
  - `WeeklyTournamentEntry`

---

## Kategori: Görevler

### Özellik adı: Günlük görev, başarımlar, XP, giriş ödülü
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Evet
- Kısmen çalışıyor mu? Evet; Flutter growth hub mevcut sinyallerden hesaplıyor, sunucu görev/başarım API'si tam bağlı değil
- Kullanılan API'ler:
  - `GET /api/user/achievements`
  - `GET /api/user/daily-tasks`
  - `POST /api/user/daily-tasks`
  - `GET /api/daily-rewards`
  - `GET /api/user/fortune-streak`
  - `POST /api/user/watch-ad`
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `Achievement`
  - `UserAchievement`
  - `DailyTask`
  - `DailyQuest`
  - `DailyLoginReward`
  - `DailyReward`
  - `UserFortuneStreak`

---

## Kategori: Üyelikler

### Özellik adı: Üyelik planları, VIP/Gold, rozet, profil çerçevesi
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Kısmen
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; paket/gold hub var, profil çerçeve/efekt/tier rozet tam değil
- Kullanılan API'ler:
  - `GET /api/membership/packages`
  - `POST /api/membership/purchase`
  - `GET /api/user/credits`
  - `GET /api/jeton`
  - `GET /api/payment/config`
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `MembershipPlan`
  - `MembershipPurchase`
  - `MembershipBadge`
  - `ProfileFrame`
  - `CustomBadge`

---

## Kategori: Bildirimler

### Özellik adı: Uygulama içi bildirim ve push
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Evet
- Eksik mi? Kısmen
- Kısmen çalışıyor mu? Evet; liste/push var, e-posta/admin bildirim yönetimi mobilde tam değil
- Kullanılan API'ler:
  - `GET /api/notifications`
  - `GET /api/notifications/unread`
  - `PATCH /api/notifications/{id}/read`
  - `POST /api/devices/fcm`
  - `POST /api/user/device-token`
  - `GET/POST /api/admin/notifications`
- Kullanılan Socket Eventleri:
  - OneSignal / Firebase push eventleri
- Kullanılan Veritabanı Modelleri:
  - `Notification`
  - `PushNotificationLog`

---

## Kategori: Ajans Sistemi

### Özellik adı: Ajans başvuru, panel, üyeler, kazanç, görev, sıralama
- Webde mevcut mu? Evet
- Flutterda mevcut mu? Hayır
- Eksik mi? Evet
- Kısmen çalışıyor mu? Hayır
- Kullanılan API'ler:
  - `GET /api/agency/my`
  - `POST /api/agency/apply`
  - `POST /api/agency/join`
  - `POST /api/agency/invite`
  - `POST /api/agency/leave`
  - `GET /api/agency/members`
  - `GET /api/agency/earnings`
  - `GET /api/agency/tasks`
  - `GET /api/agency/leaderboard`
  - `GET /api/agency/withdrawals`
- Kullanılan Socket Eventleri: Yok
- Kullanılan Veritabanı Modelleri:
  - `Agency`
  - `AgencyUser`
  - `AgencyTask`
  - `AgencyEarning`
  - `AgencyPenalty`
  - `AgencyLeaveRequest`

---

## Öncelikli Eksikler

1. Fal & Tarot: Web LLM/SSE fal yorum API'leri Flutter'a bağlanmalı.
2. Oyunlar: Native oyun odası, hamle, sohbet, skor ve turnuva akışı eksik.
3. Ajans Sistemi: Flutter'da hiç native modül yok.
4. Görevler: Sunucu görev/başarım/XP API'leri growth hub'a bağlanmalı.
5. Video: TikTok, video detay ve trend konu native ekranları eksik.
6. Canlı Yayın: Co-broadcast, moderasyon, resim modu ve PK sonuç ekranı kısmi.
7. Sesli Odalar: 15 koltuk/web heartbeat/yazıyor göstergesi tam doğrulanmalı.
