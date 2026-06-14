/// canlifal.com ile uyumlu uçlar. Özel backend için `API_BASE_URL` ve bu dosyayı güncelleyin.
///
/// Flutter istekleri (canlifal.com dokümanı):
/// ```dart
/// headers: {
///   'Authorization': 'Bearer $accessToken',
///   'Content-Type': 'application/json',
/// }
/// ```
/// `dio_provider` Bearer + JSON başlıklarını otomatik ekler.
abstract final class ApiEndpoints {
  // --- canlifal.com mobil JWT (SQL, WebView yok) ---
  static const authMobileRegister = '/api/auth/mobile-register';
  static const authMobileLogin = '/api/auth/mobile-login';
  static const authMobileGoogle = '/api/auth/mobile-google';
  static const authMobileTiktok = '/api/auth/mobile-tiktok';
  static const authMobileRefresh = '/api/auth/mobile-refresh';
  static const authForgotPassword = '/api/auth/forgot-password';
  static const authResetPassword = '/api/auth/reset-password';
  static const authChangePassword = '/api/auth/change-password';
  static const me = '/api/me';
  static const meStats = '/api/users/me/stats';
  static const meGiftsReceived = '/api/users/me/gifts-received';
  static const meBroadcastHistory = '/api/users/me/broadcast-history';
  static const meActivity = '/api/users/me/activity';

  // --- Eski / self-hosted (geriye dönük) ---
  static const authLogin = '/api/auth/login';
  static const authRegister = '/api/auth/register';
  static const authRefresh = '/api/auth/refresh';
  static const authMe = '/api/auth/me';
  static const authGoogle = '/api/auth/google';
  static const authTiktok = '/api/auth/tiktok';

  /// DM sohbet listesi (Bearer).
  static const messages = '/api/messages';
  static String messagesWithUser(String userId) => '/api/messages/$userId';
  static const messagesRequest = '/api/messages/request';

  /// Eski konuşma API (self-hosted).
  static const messagesConversations = '/api/messages/conversations';

  // --- Uygulama API (çerez veya Bearer) ---
  static const feed = '/api/stories';

  /// canlifal.com sosyal akış (web `/sosyal` ile aynı veri).
  static const socialPosts = '/api/social/posts';
  static const socialStories = '/api/social/stories';

  /// Site geneli istatistikler (mobil ana sayfa).
  static const socialPublicStats = '/api/social/public-stats';

  /// Ana sayfa promosyon slider.
  static const homeBanners = '/api/banners';

  /// Ana sayfa fal kartları vitrin.
  static const homepageFortuneCards = '/api/homepage-fortune-cards';

  /// Çevrimiçi falcılar / danışmanlar.
  static const homeAdvisorsOnline = '/api/advisors/online';

  /// Canlı falcılar listesi (canlifal.com `/canli-falcilar`).
  static const fortuneTellers = '/api/fortune-tellers';

  static const fortuneTellerSession = '/api/fortune-tellers/session';

  static const fortuneTellerIncomingSessions =
      '/api/fortune-tellers/sessions/incoming';

  static String fortuneTellerSessionStatus(String sessionId) =>
      '/api/fortune-tellers/session/$sessionId';

  static String fortuneTellerSessionRespond(String sessionId) =>
      '/api/fortune-tellers/session/$sessionId/respond';

  static String fortuneTeller(String id) => '/api/fortune-tellers/$id';

  /// Oyunlar ve etkinlikler.
  static const homeGames = '/api/games';
  static const gameRooms = '/api/games/rooms';
  static const gameAutoMatch = '/api/games/auto-match';
  static const gameLeaderboard = '/api/games/leaderboard';
  static const gameHistory = '/api/games/history';
  static const gameProfile = '/api/games/profile';
  static const gameMiniScores = '/api/games/mini-scores';
  static const tournaments = '/api/tournaments';
  static const tournamentsJoin = '/api/tournaments/join';
  static String gameRoom(String roomId) => '/api/games/room/$roomId';
  static String gameRoomJoin(String roomId) => '/api/games/room/$roomId/join';
  static String gameRoomChat(String roomId) => '/api/games/room/$roomId/chat';
  static String gameRoomViewers(String roomId) =>
      '/api/games/room/$roomId/viewers';
  static const gameSosCreate = '/api/games/sos/create';
  static String gameSos(String gameId) => '/api/games/sos/$gameId';
  static String gameSosChat(String gameId) => '/api/games/sos/$gameId/chat';
  static String gameSosViewers(String gameId) =>
      '/api/games/sos/$gameId/viewers';

  /// Günlük ödüller.
  static const homeDailyRewards = '/api/daily-rewards';
  static const userDailyTasks = '/api/user/daily-tasks';
  static const userAchievements = '/api/user/achievements';
  static const userWatchAd = '/api/user/watch-ad';

  static const dreams = '/api/dreams';
  static const dreamSymbols = '/api/dream-symbols';
  static const dreamContest = '/api/dream-contest';
  static const dreamDiary = '/api/dream-diary';
  static const dreamStats = '/api/dream-stats';
  static const weeklyDreamReport = '/api/weekly-dream-report';

  static const blog = '/api/blog';
  static const blogCategories = '/api/blog/categories';
  static const blogRecent = '/api/blog/recent';
  static String blogPost(String slug) => '/api/blog/$slug';
  static const blogLike = '/api/blog/like';
  static const blogFavorite = '/api/blog/favorite';
  static const blogComments = '/api/blog/comments';

  /// Ajans sistemi (canlifal.com §17).
  static const agencyMy = '/api/agency/my';
  static const agencyApply = '/api/agency/apply';
  static const agencyMembers = '/api/agency/members';
  static const agencyInvite = '/api/agency/invite';
  static const agencyJoin = '/api/agency/join';
  static const agencyEarnings = '/api/agency/earnings';
  static const agencyLeaderboard = '/api/agency/leaderboard';
  static const agencyWithdrawals = '/api/agency/withdrawals';
  static const agencyTasks = '/api/agency/tasks';

  static const celebrities = '/api/celebrities';
  static String celebrity(String id) => '/api/celebrities/$id';
  static String celebrityFollow(String id) => '/api/celebrities/$id/follow';
  static String celebrityPosts(String id) => '/api/celebrities/$id/posts';
  static const fanClubs = '/api/fan-clubs';
  static String fanClubJoin(String id) => '/api/fan-clubs/$id/join';
  static String fanClubPosts(String id) => '/api/fan-clubs/$id/posts';
  static String fanClubPolls(String id) => '/api/fan-clubs/$id/polls';

  /// Ana sayfa trend videolar (canlifal.com).
  static const trendVideos = '/api/trend-videos';

  /// Geriye dönük (self-hosted seed).
  static const socialAnnouncements = '/api/social/announcements';
  static const socialFortuneTellers = '/api/social/fortune-tellers';

  /// Sosyal akış (ana sayfa feed bölümü).
  static const feedPosts = '/api/social/posts';

  /// Okunmamış bildirim sayısı (yoksa liste üzerinden hesaplanır).
  static const notificationsUnread = '/api/notifications/unread';
  static const socialPostsAutoFortune = '/api/social/posts/auto-fortune';
  static String socialPostDelete(String id) => '/api/social/posts/$id';

  /// Beğeni toggle — POST (canlifal.com).
  static String socialPostLikes(String postId) =>
      '/api/social/posts/$postId/likes';

  static String socialPostComments(String postId) =>
      '/api/social/posts/$postId/comments';

  /// Oturumlu kullanıcının takipçi / takip listesi.
  static const userFollowers = '/api/user/followers';
  static const userFollowing = '/api/user/following';

  /// Başka kullanıcının takipçileri (dizi döner).
  static String userPublicFollowers(String userId) =>
      '/api/users/$userId/followers';

  /// canlifal.com ana sayfa canlı yayın listesi (JSON dizi).
  static const videoStreams = '/api/video-streams';

  /// Sesli / metin sohbet odaları (web `/sohbet/{slug}`).
  static const chatRooms = '/api/chat/rooms';

  /// Sesli sohbet odası aç — canlifal.com (normal 100 / VIP 5000 jeton).
  static const chatRoomCreate = '/api/chat/rooms/create';

  static String chatRoomMessages(String roomId) =>
      '/api/chat/rooms/$roomId/messages';

  static String chatRoomPresence(String roomId) =>
      '/api/chat/rooms/$roomId/presence';

  /// SSE — mesaj / presence anlık akışı (Bearer gerekli).
  static String chatRoomStream(String roomId) =>
      '/api/chat/rooms/$roomId/stream';

  static String chatRoomDj(String roomId) => '/api/chat/rooms/$roomId/dj';

  static String chatRoomGifts(String roomId) => '/api/chat/rooms/$roomId/gifts';

  static String chatRoomPkBattle(String roomId) =>
      '/api/chat/rooms/$roomId/pk-battle';

  static String videoStreamPkBattle(String streamId) =>
      '/api/video-streams/$streamId/pk-battle';

  static const pkHistory = '/api/pk/history';

  static String pkBattle(String battleId) => '/api/pk/battles/$battleId';

  static String pkBattleAccept(String battleId) =>
      '/api/pk/battles/$battleId/accept';

  static String pkBattleReject(String battleId) =>
      '/api/pk/battles/$battleId/reject';

  static String pkBattleEnd(String battleId) => '/api/pk/battles/$battleId/end';

  static const musicSearch = '/api/music/search';

  /// Oturumlu kullanıcı profili (takipçi, bio, görsel — NextAuth çerezi).
  static const userSiteProfile = '/api/user/profile';

  /// Jeton / kredi bakiyesi (NextAuth).
  static const userCredits = '/api/user/credits';

  /// Jeton paketleri / fiyat listesi (oturum gerekir).
  static const jetonCatalog = '/api/jeton';

  static const membershipPackages = '/api/membership/packages';
  static const membershipPurchase = '/api/membership/purchase';

  static const paymentConfig = '/api/payment/config';
  static const paymentRequests = '/api/payment/requests';
  static const adminCfcPaymentRequests = '/api/admin/cfc-payment-requests';
  static const adminCfcPaymentPatch = '/api/admin/cfc-payment-requests';
  static const adminCfcSettings = '/api/admin/cfc-settings';

  /// Geriye dönük
  static const adminPaymentRequests = '/api/admin/payment-requests';
  static const adminNotifications = '/api/admin/notifications';

  /// Arkadaş daveti — bağlantı veya kod (oturum gerekir).
  static const referral = '/api/referral';

  /// Diğer ortamlar için genel canlı listesi.
  static const liveStreams = '/api/live';

  /// Tencent TRTC UserSig (POST: userId, roomId).
  static const trtcUserSig = '/api/trtc/usersig';
  static const livekitToken = '/api/livekit/token';

  /// Canlı yayın hediye kataloğu (Tencent / site ile aynı liste).
  static const videoStreamGiftsCatalog = '/api/video-streams/gifts';

  static String videoStream(String streamId) => '/api/video-streams/$streamId';

  static String videoStreamEnd(String streamId) =>
      '/api/video-streams/$streamId/end';

  static String videoStreamJoin(String streamId) =>
      '/api/video-streams/$streamId/join';

  static String videoStreamLeave(String streamId) =>
      '/api/video-streams/$streamId/leave';

  static String videoStreamMessages(String streamId) =>
      '/api/video-streams/$streamId/messages';

  static String videoStreamLiveStarted(String streamId) =>
      '/api/video-streams/$streamId/live-started';

  static String videoStreamGifts(String streamId) =>
      '/api/video-streams/$streamId/gifts';

  static String videoStreamGiftLeaderboard(String streamId) =>
      '/api/video-streams/$streamId/gifts/leaderboard';

  static String videoStreamLike(String streamId) =>
      '/api/video-streams/$streamId/like';

  static String videoStreamSignal(String streamId) =>
      '/api/video-streams/$streamId/signal';

  static String videoStreamCoBroadcast(String streamId) =>
      '/api/video-streams/$streamId/co-broadcast';

  static String videoStreamCoBroadcastInvite(String streamId) =>
      '/api/video-streams/$streamId/co-broadcast/invite';

  static const coBroadcastInvites = '/api/user/co-broadcast-invites';

  static String videoStreamBan(String streamId) =>
      '/api/video-streams/$streamId/ban';

  static String videoStreamMute(String streamId) =>
      '/api/video-streams/$streamId/mute';

  static String videoStreamModerator(String streamId) =>
      '/api/video-streams/$streamId/moderator';

  static String videoStreamImage(String streamId) =>
      '/api/video-streams/$streamId/image';

  static String videoStreamBackground(String streamId) =>
      '/api/video-streams/$streamId/background';

  static String videoStreamAutoClose(String streamId) =>
      '/api/video-streams/$streamId/auto-close';

  static const giftsCatalog = '/api/gifts';

  static String userProfile(String userId) => '/api/users/$userId';

  /// Kullanıcı adı ile profil — Flutter API dokümanı.
  static String userLookup(String username) =>
      '/api/users/lookup/${Uri.encodeComponent(username.trim())}';

  /// İsim veya kullanıcı adı ile arama (min 2 karakter, Bearer).
  static String usersSearch(String query) =>
      '/api/users/search?q=${Uri.encodeComponent(query.trim())}';

  /// Oturumlu kullanıcının fal geçmişi.
  static const userFortunes = '/api/user/fortunes';

  static String fortuneReading(String slug) => '/api/fortunes/$slug';

  static String userFortuneDetail(String fortuneId) =>
      '/api/user/fortunes/$fortuneId';

  static String userFortunePin(String fortuneId) =>
      '/api/user/fortunes/$fortuneId/pin';

  static String userFortuneRate(String fortuneId) =>
      '/api/user/fortunes/$fortuneId/rate';

  static const tellerGifts = '/api/teller/gifts';

  static const dailyLogin = '/api/daily-login';
  static const dailyMissions = '/api/daily-missions';

  static const userFavorites = '/api/user/favorites';

  static String userFavoriteDelete(String id) => '/api/user/favorites/$id';

  static const userStory = '/api/user/story';

  /// Yayın geçmişi (site dokümanı: `/api/user/broadcast-history`).
  static const userBroadcastHistory = '/api/user/broadcast-history';

  /// Aktivite / bildirimler (site dokümanı: `/api/user/activity`).
  static const userActivity = '/api/user/activity';

  /// Takip et / çık (site dokümanı — toggle POST).
  static String userFollow(String userId) => '/api/user/$userId/follow';

  static String follow(String userId) => '/api/users/$userId/follow';
  static String followers(String userId) => '/api/users/$userId/followers';
  static String following(String userId) => '/api/users/$userId/following';

  static const conversations = messages;
  static String conversationMessages(String id) =>
      '/api/messages/conversations/$id/messages';

  static const notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id/read';

  /// FCM cihaz token kaydı (canlifal.com veya self-hosted API).
  static const registerFcmDevice = '/api/devices/fcm';

  static const wallet = '/api/wallet';

  /// İçerik / kullanıcı şikayeti (canlifal moderasyon API).
  static const reports = '/api/reports';

  /// @deprecated — `musicSearch` kullanın.
  static const youtubeSearch = '/api/youtube/search';

  // --- Kısa videolar (TikTok tarzı, R2 CDN) ---
  static const shortVideos = '/api/short-videos';
  static const shortVideosUpload = '/api/short-videos/upload';
  static String shortVideoLike(String id) => '/api/short-videos/$id/like';
  static String shortVideoComments(String id) =>
      '/api/short-videos/$id/comments';
  static String shortVideoView(String id) => '/api/short-videos/$id/view';
  static String shortVideoDelete(String id) => '/api/short-videos/$id';
  static String shortVideosByUser(String userId) =>
      '/api/short-videos/user/$userId';
}
