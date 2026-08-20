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
  static const authMobileApple = '/api/auth/mobile-apple';
  static const authMobileTiktok = '/api/auth/mobile-tiktok';
  static const authMobileRefresh = '/api/auth/mobile-refresh';
  static const authLogout = '/api/auth/logout';
  static const authMobileSendVerification = '/api/auth/mobile-send-verification';
  static const authMobileVerifyEmail = '/api/auth/mobile-verify-email';
  static const authMobileSessions = '/api/auth/mobile-sessions';
  static String authMobileSessionRevoke(String id) =>
      '/api/auth/mobile-sessions/$id';
  static const authMobileDeviceToken = '/api/auth/mobile/device-token';
  static const authForgotPassword = '/api/auth/forgot-password';
  static const authResetPassword = '/api/auth/reset-password';
  static const authChangePassword = '/api/auth/change-password';
  /// PART10 — cihaz doğrulama (metot: GET vs POST doküman çelişkisi; bkz. uyumluluk raporu).
  static const authVerifyDevice = '/api/auth/verify-device';
  static const authReclaimDevice = '/api/auth/reclaim-device';
  static const mobileConfig = '/api/mobile/config';
  static const mobileHome = '/api/mobile/home';
  static String sitePage(String slug) => '/api/site-pages/$slug';
  /// Çocuk güvenliği — site-pages slug'ı yok; ayrı legal uç (canlifal.com).
  static const legalChildSafety = '/api/legal/child-safety';
  static const mobileFortuneMenu = '/api/mobile/fortune-menu';
  static String mobileUserProfile(String userId) =>
      '/api/mobile/user-profile/$userId';
  static const userPresence = '/api/presence';
  static const userPresenceSections = '/api/presence/sections';

  static const me = '/api/me';
  static const meStats = '/api/users/me/stats';
  /// Kılavuz §9.2 — alınan hediyeler (eski `/api/users/me/gifts-received` yedek).
  static const userReceivedGifts = '/api/user/received-gifts';
  @Deprecated('Kılavuz §9.2: userReceivedGifts kullanın')
  static const meGiftsReceived = userReceivedGifts;
  static const meBroadcastHistory = '/api/users/me/broadcast-history';
  static const meActivity = '/api/users/me/activity';
  static const meProfileVisitors = '/api/users/me/profile-visitors';
  static const userStats = '/api/user/stats';
  static const userStatistics = '/api/user/statistics';
  static const userXp = '/api/user/xp';

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
  static String messageWithId(String userId, String messageId) =>
      '/api/messages/$userId/$messageId';
  static const messagesRequest = '/api/messages/request';

  /// Eski konuşma API (self-hosted).
  static const messagesConversations = '/api/messages/conversations';

  // --- Uygulama API (çerez veya Bearer) ---
  static const feed = '/api/stories';

  /// canlifal.com sosyal akış (web `/sosyal` ile aynı veri).
  static const socialPosts = '/api/social/posts';
  static const socialStories = '/api/social/stories';

  static const chatMusicPopular = '/api/chat/music/popular';
  static const adminVoiceRoomBackgrounds = '/api/admin/voice-room-backgrounds';
  static const adminGifts = '/api/admin/gifts';
  static String adminGift(String id) => '/api/admin/gifts/$id';
  static const adminGiftsStats = '/api/admin/gifts/stats';

  static const giftsBattles = '/api/gifts/battles';
  static String giftsBattle(String id) => '/api/gifts/battles/$id';
  static const giftsGoals = '/api/gifts/goals';
  static const giftsMissions = '/api/gifts/missions';
  static const giftsMissionsMe = '/api/gifts/missions/me';
  static const giftsInsightsLeaderboard = '/api/gifts/insights/leaderboard';
  static String giftsInsightsBadge(String userId) =>
      '/api/gifts/insights/badge/$userId';
  static const giftsInsightsMeBadge = '/api/gifts/insights/me/badge';
  static String giftsInsightsCollection(String userId) =>
      '/api/gifts/insights/collection/$userId';
  static String giftsInsightsAlbum(String userId) =>
      '/api/gifts/insights/album/$userId';
  static String giftsInsightsFirstGifter(String context, String contextId) =>
      '/api/gifts/insights/first-gifter/$context/$contextId';
  static const giftsInsightsFeed = '/api/gifts/insights/feed';
  static const giftsInsightsMap = '/api/gifts/insights/map';
  static const giftsInsightsMeRecommendations =
      '/api/gifts/insights/me/recommendations';
  static const giftsInsightsMeHistory = '/api/gifts/insights/me/history';
  static String giftsMissionClaim(String id) => '/api/gifts/missions/$id/claim';

  /// Site geneli istatistikler (kılavuz §9.13 — web ile aynı).
  static const publicStats = '/api/public-stats';
  static const platformStats = '/api/platform-stats';

  /// @deprecated — [publicStats] kullanın.
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

  /// Üretim: falcı gelen istekler + danışan oturum durumu (web ile aynı).
  static const fortuneTellerSessions = '/api/fortune-tellers/sessions';

  /// Falcı — bekleyen canlı fal istekleri SSE (Bearer zorunlu).
  static const fortuneTellerSessionsStream =
      '/api/fortune-tellers/sessions/stream';

  /// Üretim: `GET /api/fortune-tellers/session?sessionId=`
  static String fortuneTellerSessionQuery(String sessionId) =>
      '/api/fortune-tellers/session?sessionId=${Uri.encodeComponent(sessionId.trim())}';

  static String fortuneTellerSessionPatch(String sessionId) =>
      '/api/fortune-tellers/sessions/$sessionId';

  /// Falcı bekleyen istekler — `GET ?status=pending`
  static String fortuneTellerSessionsWithStatus(String status) =>
      '$fortuneTellerSessions?status=${Uri.encodeComponent(status.trim())}';

  /// Canlı fal oda — timer, ping, extend, end (üretim §9–13).
  static String liveFortuneRoom(String sessionId) =>
      '/api/room/${Uri.encodeComponent(sessionId.trim())}';

  static String liveFortuneRoomMessages(String sessionId) =>
      '${liveFortuneRoom(sessionId)}/messages';

  /// Canlı fal seans SSE — mesaj, timer, durum (üretim `GET /api/room/{id}/stream`).
  static String liveFortuneRoomStream(String sessionId) =>
      '${liveFortuneRoom(sessionId)}/stream';

  static String liveFortuneRoomTip(String sessionId) =>
      '${liveFortuneRoom(sessionId)}/tip';

  static String liveFortuneRoomReview(String sessionId) =>
      '${liveFortuneRoom(sessionId)}/review';

  static const liveFortuneRoomSignal = '/api/room/signal';

  static String liveFortuneRoomSignalQuery(String sessionId) =>
      '$liveFortuneRoomSignal?sessionId=${Uri.encodeComponent(sessionId.trim())}';

  static const fortuneTellerApply = '/api/fortune-tellers/apply';

  static String fortuneTellerReviews(String tellerId) =>
      '/api/fortune-tellers/${Uri.encodeComponent(tellerId.trim())}/reviews';

  static String fortuneTellerAwards(String tellerId) =>
      '/api/fortune-tellers/awards?tellerId=${Uri.encodeComponent(tellerId.trim())}';

  static String fortuneTellerGifts(String tellerId) =>
      '/api/fortune-tellers/gifts?tellerId=${Uri.encodeComponent(tellerId.trim())}';

  static String fortuneTeller(String id) => '/api/fortune-tellers/$id';

  /// `POST /api/fortune-tellers/{tellerId}/session`
  static String fortuneTellerSessionFor(String tellerId) =>
      '/api/fortune-tellers/$tellerId/session';

  static const fortuneTellerMyProfile = '/api/fortune-tellers/my-profile';
  static const fortuneTellerToggleOnline = '/api/fortune-tellers/toggle-online';

  static const favoriteTellers = '/api/favorite-tellers';

  /// Aktif seanslar — kullanıcı uygulama açılışında (üretim prompt §8).
  static const userActiveSessions = '/api/user/active-sessions';

  /// Oyunlar ve etkinlikler.
  static const homeGames = '/api/games';
  static const gameRooms = '/api/games/rooms';
  /// Üretimde oda oluşturma (çoğu sürümde `/rooms` yerine bu uç).
  static const gameRoomCreate = '/api/games/room';
  static const gamePlay = '/api/games/play';
  static const gameAutoMatch = '/api/games/auto-match';
  static const gameLeaderboard = '/api/games/leaderboard';
  static const gameHistory = '/api/games/history';
  static const gameProfile = '/api/games/profile';
  static const gameMiniScores = '/api/games/mini-scores';
  static const tournaments = '/api/tournaments';
  static const tournamentsJoin = '/api/tournaments/join';
  static String gameRoom(String roomId) => '/api/games/room/$roomId';
  /// Yeni backend: `POST /api/games/room/:id` (gövdesiz katılma).
  static String gameRoomJoin(String roomId) => '/api/games/room/$roomId';
  /// Eski sürüm yedeği.
  static String gameRoomJoinLegacy(String roomId) =>
      '/api/games/room/$roomId/join';

  /// Public warmup/health kontrolü — backend canonical `/api/warmup`.
  static const apiHealth = '/api/warmup';
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
  static const football = '/api/football';
  static String translations({String lang = 'tr'}) =>
      '/api/translations?lang=${Uri.encodeComponent(lang)}';
  static const broadcastImages = '/api/broadcast-images';
  static const onlineFal = '/api/online-fal';
  static const fanClubs = '/api/fan-clubs';
  static const fanClubsPopular = '/api/fan-clubs/popular';
  static String fanClubJoin(String id) => '/api/fan-clubs/$id/join';
  static String fanClubPosts(String id) => '/api/fan-clubs/$id/posts';
  static String fanClubPolls(String id) => '/api/fan-clubs/$id/polls';

  /// Ana sayfa trend videolar (canlifal.com).
  static const trendVideos = '/api/trend-videos';
  static const trends = '/api/trends';

  /// Geriye dönük (self-hosted seed).
  static const socialAnnouncements = '/api/social/announcements';
  static const socialFortuneTellers = '/api/social/fortune-tellers';

  /// Sosyal akış (ana sayfa feed bölümü).
  static const feedPosts = '/api/social/posts';

  /// Okunmamış bildirim sayısı (yoksa liste üzerinden hesaplanır).
  static const notificationsUnread = '/api/notifications/unread';
  static const socialPostsAutoFortune = '/api/social/posts/auto-fortune';
  /// Tek gönderi detayı — kılavuz §9.10 `getPost`.
  static String socialPost(String postId) => '/api/social/posts/$postId';

  static String socialPostDelete(String id) => socialPost(id);

  /// Beğeni toggle — POST (canlifal.com).
  static String socialPostLikes(String postId) =>
      '/api/social/posts/$postId/likes';

  static String socialPostComments(String postId) =>
      '/api/social/posts/$postId/comments';

  /// Gönderi görüntülenme — kılavuz §9.10.
  static String socialPostView(String postId) =>
      '/api/social/posts/$postId/view';

  /// Kullanıcı profil paylaşımları — kılavuz §9.10.
  static String userPosts(String userId) => '/api/users/$userId/posts';

  /// Oturumlu kullanıcının takipçi / takip listesi.
  static const userFollowers = '/api/user/followers';
  static const userFollowing = '/api/user/following';
  static const userLikers = '/api/user/likers';

  /// Başka kullanıcının takipçileri (dizi döner).
  static String userPublicFollowers(String userId) =>
      '/api/users/$userId/followers';

  /// canlifal.com ana sayfa canlı yayın listesi (JSON dizi).
  static const videoStreams = '/api/video-streams';

  /// Sesli / metin sohbet odaları (web `/sohbet/{slug}`).
  static const chatRooms = '/api/chat/rooms';

  /// Sesli sohbet odası aç — canlifal.com (normal 2500 / VIP 5000 jeton).
  static const chatRoomCreate = '/api/chat/rooms/create';

  static String chatRoomMessages(String roomId) =>
      '/api/chat/rooms/$roomId/messages';

  static String chatRoomMessage(String roomId, String messageId) =>
      '/api/chat/rooms/$roomId/messages/$messageId';

  static String chatRoomPresence(String roomId) =>
      '/api/chat/rooms/$roomId/presence';

  /// Tek kaynaklı oda durumu — katılımcılar, koltuklar, TRTC, owner.
  static String chatRoomState(String roomId) =>
      '/api/chat/rooms/$roomId/state';

  /// Koltuk yönetimi — kılavuz §9.3 `POST` (`action`, `seatIndex`).
  static String chatRoomSeats(String roomId) =>
      '/api/chat/rooms/$roomId/seats';

  /// DJ müzik durumu — `GET/POST /api/chat/rooms/{roomId}/music`.
  static String chatRoomMusic(String roomId) =>
      '/api/chat/rooms/$roomId/music';

  /// Şarkı isteği — `POST /api/chat/rooms/{roomId}/song-request`.
  static String chatRoomSongRequest(String roomId) =>
      '/api/chat/rooms/$roomId/song-request';

  /// SongQueueService — FIFO kuyruk.
  static String chatRoomSongQueue(String roomId) =>
      '/api/chat/rooms/$roomId/queue';

  /// MUSIC_API canonical skip: `DELETE /api/chat/rooms/{roomId}/music`.
  static String chatRoomSongSkip(String roomId) => chatRoomMusic(roomId);

  /// MUSIC_API canonical stop: `POST /api/chat/rooms/{roomId}/music/stop`.
  static String chatRoomSongStop(String roomId) =>
      '${chatRoomMusic(roomId)}/stop';

  @Deprecated('Backend docs do not define pause; keep local UI state only.')
  static String chatRoomSongPause(String roomId) => chatRoomMusic(roomId);

  @Deprecated('Backend docs do not define resume; use chatRoomMusic POST play.')
  static String chatRoomSongResume(String roomId) => chatRoomMusic(roomId);

  static String chatRoomSongRemove(String roomId, String queueId) =>
      '/api/chat/rooms/$roomId/song/$queueId';

  static String chatRoomSongQueueClear(String roomId) =>
      '/api/chat/rooms/$roomId/queue';

  /// Oda arka planları — kılavuz §9.3 `getBackgrounds`.
  static const chatRoomBackgrounds = '/api/chat/rooms/backgrounds';

  static String chatRoomBackground(String roomId) =>
      '/api/chat/rooms/$roomId/background';

  /// Koltuk moderasyonu — kılavuz §9.3 `muteUser` / `banUser`.
  static String chatRoomModeration(String roomId) =>
      '/api/chat/rooms/$roomId/moderation';

  /// Oda ayarları — kılavuz §9.3 `updateSettings`.
  static String chatRoomSettings(String roomId) =>
      '/api/chat/rooms/$roomId/settings';

  /// Oda detayı — `GET/PATCH /api/chat/rooms/{roomId}`.
  static String chatRoomDetail(String roomId) => '/api/chat/rooms/$roomId';

  /// Müzik kuyruğu — kılavuz §9.3 `getMusicQueue` / `addToQueue`.
  static String chatRoomMusicQueue(String roomId) =>
      '/api/chat/rooms/$roomId/music-queue';

  static String chatRoomMusicQueueComplete(String roomId) =>
      '${chatRoomMusicQueue(roomId)}/complete';

  static String chatRoomMusicQueueAdvance(String roomId) =>
      '${chatRoomMusicQueue(roomId)}/advance';

  static String chatRoomMusicQueueItem(String roomId, String itemId) =>
      '${chatRoomMusicQueue(roomId)}/$itemId';

  static String chatRoomMusicQueueReorder(String roomId) =>
      '${chatRoomMusicQueue(roomId)}/reorder';

  /// Sahiplik devri — kılavuz §9.3 `transferOwnership`.
  static String chatRoomTransferOwnership(String roomId) =>
      '/api/chat/rooms/$roomId/transfer-ownership';

  /// Kılavuz dışı — üretimde mevcut (bkz. uyumluluk raporu §5.2).
  static String chatRoomSpeakRequest(String roomId) =>
      '/api/chat/rooms/$roomId/speak-request';

  static String chatRoomSpeakRequests(String roomId) =>
      '/api/chat/rooms/$roomId/speak-requests';

  static String chatRoomSpeakRequestApprove(
    String roomId,
    String targetUserId,
  ) =>
      '/api/chat/rooms/$roomId/speak-requests/$targetUserId/approve';

  static String chatRoomMusicSettings(String roomId) =>
      '/api/chat/rooms/$roomId/music-settings';

  static String chatRoomMusicRequestByQuery(String roomId) =>
      '/api/chat/rooms/$roomId/music-request-by-query';

  static String chatRoomKick(String roomId) => '/api/chat/rooms/$roomId/kick';

  static String chatRoomMute(String roomId) => '/api/chat/rooms/$roomId/mute';

  static String chatRoomRoles(String roomId) => '/api/chat/rooms/$roomId/roles';

  static String chatRoomBan(String roomId, String userId) =>
      '/api/chat/rooms/$roomId/bans/$userId';

  static String chatRoomDjUser(String roomId, String targetUserId) =>
      '/api/chat/rooms/$roomId/dj/$targetUserId';

  static String chatRoomBannedWords(String roomId) =>
      '/api/chat/rooms/$roomId/banned-words';

  static String chatRoomBannedWord(String roomId, String word) =>
      '${chatRoomBannedWords(roomId)}/${Uri.encodeComponent(word)}';

  static String chatRoomMentions(String roomId) =>
      '/api/chat/rooms/$roomId/mentions';

  /// Yetkili kullanıcı otomatik koltuk — üretim `join-seat`, yoksa `seats` fallback.
  static String chatRoomJoinSeat(String roomId) =>
      '/api/chat/rooms/$roomId/join-seat';

  /// SSE — mesaj / presence anlık akışı (Bearer gerekli).
  static String chatRoomStream(String roomId) =>
      '/api/chat/rooms/$roomId/stream';

  static String chatRoomDj(String roomId) => '/api/chat/rooms/$roomId/dj';

  static String chatRoomGifts(String roomId) => '/api/chat/rooms/$roomId/gifts';

  /// Seste olanlar — `GET/POST /api/chat/rooms/{roomId}/voice` (join/leave body).
  static String chatRoomVoice(String roomId) => '/api/chat/rooms/$roomId/voice';

  /// Yazıyor göstergesi — `GET/POST /api/chat/rooms/{roomId}/typing`.
  static String chatRoomTyping(String roomId) => '/api/chat/rooms/$roomId/typing';

  /// Oda şikayet — `POST /api/chat/rooms/{id}/report` (kılavuz §9.3).
  static String chatRoomReport(String roomId) =>
      '/api/chat/rooms/$roomId/report';

  /// Üretim PK — `GET/POST /api/chat/rooms/{roomId}/pk`
  /// POST body: `{ guestUserId, durationSec }` → pending davet.
  /// GET (public, poll): `{ roomId, activeBattle, pendingInvite }`.
  static String chatRoomPk(String roomId) => '/api/chat/rooms/$roomId/pk';

  /// PK skor güncelleme — `POST /api/chat/rooms/{roomId}/pk/score`.
  static String chatRoomPkScore(String roomId) =>
      '/api/chat/rooms/$roomId/pk/score';

  /// Davete yanıt — `POST /api/chat/rooms/{roomId}/pk/{inviteId}/respond`
  /// body: `{ action: "accept" | "reject" }`.
  static String chatRoomPkRespond(String roomId, String inviteId) =>
      '/api/chat/rooms/$roomId/pk/$inviteId/respond';

  /// Savaşı erken bitir — `POST /api/chat/rooms/{roomId}/pk/{battleId}/end`.
  static String chatRoomPkEnd(String roomId, String battleId) =>
      '/api/chat/rooms/$roomId/pk/$battleId/end';

  /// Geriye dönük alias (`pk-battle` üretimde 404).
  static String chatRoomPkBattle(String roomId) => chatRoomPk(roomId);

  static String videoStreamPkBattle(String streamId) =>
      '/api/video-streams/$streamId/pk-battle';

  /// Üretim PK — `GET/POST /api/video-streams/pk`
  static const videoStreamPk = '/api/video-streams/pk';

  static const videoStreamPkList = '/api/video-streams/pk/list';

  static const videoStreamPkScore = '/api/video-streams/pk/score';

  static const pkHistory = '/api/pk/history';

  /// Birleşik PK (Faz 1–3) — ana backend (`canlifal.com`).
  static const pkActive = '/api/pk/active';

  /// Canlı PK (prod `/api/live/pk/*`) — games backend; `/api/pk/active` yedeği.
  static const livePkActive = '/api/live/pk/active';

  /// Çoklu yayın misafir listesi (public) — `?streamId=` opsiyonel.
  static const liveGuestList = '/api/live/guest/list';

  static const pkRequest = '/api/pk/request';
  static const pkRoom = '/api/pk/room';
  static const pkMeHistory = '/api/pk/me/history';
  static const pkMeStats = '/api/pk/me/stats';
  static const pkMeInvites = '/api/pk/me/invites';
  static const pkMeMatches = '/api/pk/me/matches';
  static const pkLeaderboard = '/api/pk/leaderboard';

  static String pkMatch(String matchId) => '/api/pk/$matchId';
  static String pkMatchStream(String matchId) => '/api/pk/$matchId/stream';
  static String pkMatchRespond(String matchId) => '/api/pk/$matchId/respond';
  static String pkMatchCancel(String matchId) => '/api/pk/$matchId/cancel';
  static String pkMatchEnd(String matchId) => '/api/pk/$matchId/end';
  static String pkMatchStart(String matchId) => '/api/pk/$matchId/start';
  static String pkMatchSeatsJoin(String matchId) => '/api/pk/$matchId/seats/join';
  static String pkMatchSeatsLeave(String matchId) => '/api/pk/$matchId/seats/leave';
  static String pkMatchSeatsKick(String matchId) => '/api/pk/$matchId/seats/kick';
  static String pkMatchEvents(String matchId) => '/api/pk/$matchId/events';
  static String pkStatsUser(String userId) => '/api/pk/stats/$userId';
  static const pkAdminBan = '/api/pk/admin/ban';
  static String pkAdminUnban(String userId) => '/api/pk/admin/unban/$userId';
  static const pkAdminBans = '/api/pk/admin/bans';
  static String pkAdminForceEnd(String matchId) => '/api/pk/admin/$matchId/force-end';
  static String pkAdminForceKick(String matchId, String userId) =>
      '/api/pk/admin/$matchId/force-kick/$userId';

  /// Merkezi PK daveti — oda uçları 404 ise fallback.
  static const pkBattles = '/api/pk/battles';

  static String pkBattle(String battleId) => '/api/pk/battles/$battleId';

  static String pkBattleAccept(String battleId) =>
      '/api/pk/battles/$battleId/accept';

  static String pkBattleReject(String battleId) =>
      '/api/pk/battles/$battleId/reject';

  static String pkBattleEnd(String battleId) => '/api/pk/battles/$battleId/end';

  static const musicSearch = '/api/music/search';

  static const chatYoutubeStream = '/api/chat/youtube-stream';

  /// Oturumlu kullanıcı profili (takipçi, bio, görsel — NextAuth çerezi).
  static const userSiteProfile = '/api/user/profile';
  static const userTheme = '/api/user/theme';

  /// Platform popup bildirimleri (oturum gerekir).
  static const popups = '/api/popups';

  /// Aktif reklam yerleşimleri (public).
  static const adsActive = '/api/ads/active';

  /// Reklam ödülü talebi (oturum gerekir).
  static const adsReward = '/api/ads/reward';

  /// Canlı fal türü kataloğu (public).
  static const fortuneRequestTypes = '/api/fortune-request-types';
  static String userFollowStatus(String userId) =>
      '/api/user/$userId/follow-status';

  /// Jeton / kredi bakiyesi (NextAuth).
  static const userCredits = '/api/user/credits';

  /// Jeton paketleri / fiyat listesi (oturum gerekir).
  static const jetonCatalog = '/api/jeton';

  static const membershipPackages = '/api/memberships/packages';
  /// CanlifalTV API doc alias (§12).
  static const membershipsCatalog = '/api/memberships';
  static const membershipPurchase = '/api/memberships/purchase';
  static const membershipsPurchase = '/api/memberships/purchase';
  static const membershipBadges = '/api/membership-badges';
  static const profileFrames = '/api/profile-frames';

  static const paymentConfig = '/api/payments/config';
  static const paymentMethods = '/api/payments/methods';
  static const paymentRequests = '/api/payments/requests';
  static const paymentRequestsCancel = '/api/payments/requests';
  static const adminCfcPaymentRequests = '/api/admin/cfc-payment-requests';
  static const adminCfcPaymentPatch = '/api/admin/cfc-payment-requests';
  static const adminCfcSettings = '/api/admin/cfc-settings';

  /// Geriye dönük
  static const adminPaymentRequests = '/api/admin/payment-requests';
  static const adminDismissPendingPayments =
      '/api/admin/payment-requests/dismiss-pending';
  static const adminNotifications = '/api/admin/notifications';
  static const adminPaymentNotifications = '/api/admin/payment-notifications';
  static const adminPaymentsStream = '/api/admin/payments/stream';
  static const adminVoiceRoomSettings = '/api/admin/voice-room-settings';
  static const adminVoiceRoomFinanceAudit = '/api/admin/voice-room-finance-audit';
  static const platformVoiceRoomSettings = '/api/platform/voice-room-settings';

  /// Admin panel — kullanıcı, kredi, finans (canlifal.com web ile aynı).
  static const adminUsers = '/api/admin/users';
  static const adminUsersStats = '/api/admin/users/stats';
  static const adminUsersCredits = '/api/admin/users/credits';
  static const adminUsersGrantMembership = '/api/admin/users/grant-membership';
  static const adminCredits = '/api/admin/credits';
  static const adminFinance = '/api/admin/finance';
  static const adminActivityFeed = '/api/admin/activity-feed';
  static const adminWithdrawals = '/api/admin/withdrawals';
  static const activities = '/api/activities';

  static String adminUser(String userId) => '/api/admin/users/$userId';

  static String adminUsersSearch(String query) =>
      '/api/admin/users/search?q=${Uri.encodeComponent(query.trim())}';

  /// Arkadaş daveti — bağlantı veya kod (oturum gerekir).
  static const referral = '/api/referral';
  static const referralMe = '/api/referral/me';
  static const referralStats = '/api/referral/stats';
  static const referralUsers = '/api/referral/users';
  static const referralEarnings = '/api/referral/earnings';
  static const referralLedger = '/api/referral/ledger';
  static const referralInviteLink = '/api/referral/invite-link';
  static const referralSettings = '/api/referral/settings';
  static const referralValidate = '/api/referral/validate';

  /// Diğer ortamlar için genel canlı listesi.
  static const liveStreams = '/api/live';

  /// Tencent TRTC UserSig (POST: userId, roomId) — eski uç.
  static const trtcUserSig = '/api/trtc/usersig';

  /// Tencent TRTC token (POST: roomId, role?) — önerilen.
  static const trtcToken = '/api/trtc/token';

  /// Canlı oda yaşam döngüsü — compound katılım, heartbeat, ayrılma.
  static const liveCreateRoom = '/api/live/create-room';
  static const liveJoinRoom = '/api/live/join-room';
  static const liveLeaveRoom = '/api/live/leave-room';
  static const liveHeartbeat = '/api/live/heartbeat';
  static const liveRooms = '/api/live/rooms';
  static const liveSeats = '/api/live/seats';
  static const liveMessage = '/api/live/message';
  static const liveGiftTypes = '/api/live/gift-types';
  static const liveGiftSend = '/api/live/gift/send';
  static const livePk = '/api/live/pk';
  static const livePkScore = '/api/live/pk/score';
  static const liveOnlineUsers = '/api/live/online-users';

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

  /// SSE — izleyici, sohbet, hediye, yayın sonu.
  static String videoStreamSse(String streamId) =>
      '/api/video-streams/$streamId/stream';

  static String videoStreamViewers(String streamId) =>
      '/api/video-streams/$streamId/viewers';

  static String videoStreamComments(String streamId) =>
      '/api/video-streams/$streamId/comments';

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

  static String videoStreamModerators(String streamId) =>
      '/api/video-streams/$streamId/moderators';

  /// Canlı fal istekleri — üretim video-stream + legacy alias.
  static String videoStreamFortuneRequests(String streamId) =>
      '/api/video-streams/$streamId/fortune-requests';

  static String videoStreamFortuneRequest(String streamId, String requestId) =>
      '/api/video-streams/$streamId/fortune-requests/$requestId';

  static String videoStreamFortuneMyStatus(String streamId) =>
      '/api/video-streams/$streamId/fortune-requests/my-status';

  static const liveFalRequestCreate = '/api/live/fal-request/create';

  static String liveFalRequestUpdate(String requestId) =>
      '/api/live/fal-request/$requestId/update';

  static String liveFalRequestComplete(String requestId) =>
      '/api/live/fal-request/$requestId/complete';

  static const liveFalRequests = '/api/live/fal-requests';

  static String videoStreamImage(String streamId) =>
      '/api/video-streams/$streamId/image';

  static String videoStreamBackground(String streamId) =>
      '/api/video-streams/$streamId/background';

  static String videoStreamAutoClose(String streamId) =>
      '/api/video-streams/$streamId/auto-close';

  /// Public hediye JSON kataloğu. Production `/api/gifts` sayfa route'udur.
  static const giftsCatalog = giftsTypes;

  /// CMS katalog versiyonu (public, hafif).
  static const giftsVersion = '/api/gifts/version';

  /// CMS tam katalog + koleksiyonlar (dual-auth).
  static const giftsCatalogCms = '/api/gifts/catalog';

  static const giftsTypes = '/api/gifts/types';

  static const giftsSend = '/api/gifts/send';

  static const giftsLuckyConfig = '/api/gifts/lucky/config';

  static const giftsLuckySend = '/api/gifts/lucky/send';

  static const giftsLuckyHistory = '/api/gifts/lucky/history';

  static const giftsRecentBig = '/api/gifts/recent-big';
  static const giftsDisplaySettings = '/api/gifts/display-settings';

  /// Kılavuz §9.9 — karşılıklı hediye kontrolü (`?userId=`).
  static const giftsCheckReciprocal = '/api/gifts/check-reciprocal';

  static const homepageButtons = '/api/homepage-buttons';

  /// Ana sayfa kayan yazılar — `GET /api/homepage-ticker`
  static const homepageTicker = '/api/homepage-ticker';

  static const announcements = '/api/announcements';

  static const horoscopeDaily = '/api/horoscope/daily';

  static const creditPackages = '/api/credit-packages';

  static const usersOnline = '/api/users/online';

  static const gamesDailySpin = '/api/games/daily-spin';

  static const gamesQuests = '/api/games/quests';

  static String gamesQuestComplete(String questId) =>
      '/api/games/quests/$questId';

  static String userProfile(String userId) => '/api/users/$userId';

  /// Kullanıcı adı ile profil — Flutter API dokümanı.
  static String userLookup(String username) =>
      '/api/users/lookup/${Uri.encodeComponent(username.trim())}';

  /// İsim veya kullanıcı adı ile arama (min 2 karakter, Bearer).
  static String usersSearch(String query) =>
      '/api/users/search?q=${Uri.encodeComponent(query.trim())}';

  /// Genel arama — kılavuz §9.13.
  static String searchAll(String query) =>
      '/api/search?q=${Uri.encodeComponent(query.trim())}';

  /// Gelişmiş arama — kılavuz §9.13.
  static String searchAdvanced({
    required String query,
    String? type,
  }) {
    final q = Uri.encodeComponent(query.trim());
    final t = type?.trim();
    if (t != null && t.isNotEmpty) {
      return '/api/search/advanced?q=$q&type=${Uri.encodeComponent(t)}';
    }
    return '/api/search/advanced?q=$q';
  }

  /// Oturumlu kullanıcının fal geçmişi.
  static const userFortunes = '/api/user/fortunes';

  static String fortuneReading(String slug) => '/api/fortunes/$slug';

  /// AI fal erişim ayarları (admin panel — mobil salt okunur).
  static const fortuneAccessSettings = '/api/fortune-access/settings';

  /// Fal erişim kontrolü — kılavuz §9.5 `?fortuneType=`.
  static const fortuneAccessCheck = '/api/fortune-access/check';

  /// Jeton ile fal kilidi tüketimi (opsiyonel; yoksa fal POST'unda düşülür).
  static const fortuneAccessConsume = '/api/fortune-access/consume';

  static String userFortuneDetail(String fortuneId) =>
      '/api/user/fortunes/$fortuneId';

  static String userFortunePin(String fortuneId) =>
      '/api/user/fortunes/$fortuneId/pin';

  static String userFortuneRate(String fortuneId) =>
      '/api/user/fortunes/$fortuneId/rate';

  static const tellerGifts = '/api/teller/gifts';

  /// Seans sonrası değerlendirme (FEATURE_INVENTORY).
  static const tellerReviews = '/api/teller/reviews';

  static const dailyLogin = '/api/daily-login';
  static const dailyMissions = '/api/daily-missions';
  static const leaderboards = '/api/leaderboards';
  static const leaderboard = '/api/leaderboard';

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

  /// Engellenen kullanıcılar — kılavuz §9.2 UserRepository.
  static const userBlocked = '/api/user/blocked';

  /// Toggle engelleme — `POST/GET /api/user/block` (yeni mobil uç).
  static const userBlock = '/api/user/block';

  /// Kullanıcı şikayet — `POST /api/user/report`.
  static const userReport = '/api/user/report';

  static const conversations = messages;
  static String conversationMessages(String id) =>
      '/api/messages/conversations/$id/messages';

  /// DM SSE (üretim hazır olduğunda) — `GET .../stream`.
  static String conversationStream(String id) =>
      '/api/messages/conversations/$id/stream';

  static String conversationTyping(String id) =>
      '/api/messages/conversations/$id/typing';

  static const notifications = '/api/notifications';
  static const notificationsStream = '/api/notifications/stream';
  static const notificationsPaymentClear = '/api/notifications/payment';
  static String notificationRead(String id) => '/api/notifications/$id/read';

  /// FCM cihaz token kaydı (canlifal.com veya self-hosted API).
  static const registerFcmDevice = '/api/devices/fcm';
  static const registerUserDeviceToken = '/api/user/device-token';

  static const wallet = '/api/wallet';
  static const withdrawals = '/api/withdrawals';
  static const platformCommissionRate = '/api/platform/commission-rate';

  /// İçerik / kullanıcı şikayeti (canlifal moderasyon API).
  static const reports = '/api/reports';

  /// @deprecated — `musicSearch` kullanın.
  static const youtubeSearch = '/api/youtube/search';

  // --- Kısa videolar (TikTok tarzı, R2 CDN) ---
  static const shortVideos = '/api/short-videos';
  static const shortVideosExplore = '/api/short-videos/explore';
  static const shortVideosRecommend = '/api/short-videos/recommend';
  static const shortVideosExploreNearby = '/api/short-videos/explore/nearby';
  static const shortVideosViewedMe = '/api/short-videos/viewed/me';
  static const shortVideosUpload = '/api/short-videos/upload';
  static const shortVideosUploadUrl = '/api/short-videos/upload-url';
  static const shortVideosRegister = '/api/short-videos/register';
  static const shortVideosMusic = '/api/short-videos/music';
  static const shortVideosHashtagsTrending =
      '/api/short-videos/hashtags/trending';
  static const shortVideosHashtagsSearch = '/api/short-videos/hashtags/search';
  static const shortVideosMentionsSearch = '/api/short-videos/mentions/search';

  /// Görsel fal — presigned yükleme (kahve fincanı, el falı vb.).
  static const uploadPresigned = '/api/upload/presigned';

  /// R2/S3 depolama yolu için imzalı okuma URL'i.
  static const uploadGetUrl = '/api/upload/get-url';
  static String shortVideo(String id) => '/api/short-videos/$id';
  static String shortVideoLike(String id) => '/api/short-videos/$id/like';
  static String shortVideoSave(String id) => '/api/short-videos/$id/save';
  static String shortVideoShare(String id) => '/api/short-videos/$id/share';
  static String shortVideoComments(String id) =>
      '/api/short-videos/$id/comments';
  static String shortVideoComment(String videoId, String commentId) =>
      '/api/short-videos/$videoId/comments/$commentId';
  static String shortVideoCommentLike(String videoId, String commentId) =>
      '/api/short-videos/$videoId/comments/$commentId/like';
  static String shortVideoCommentPin(String videoId, String commentId) =>
      '/api/short-videos/$videoId/comments/$commentId/pin';
  static String shortVideoView(String id) => '/api/short-videos/$id/view';
  static String shortVideoStream(String id) => '/api/short-videos/$id/stream';
  static String shortVideoDelete(String id) => '/api/short-videos/$id';
  static String shortVideoDuets(String id) => '/api/short-videos/$id/duets';
  static String shortVideoAnalytics(String id) =>
      '/api/short-videos/$id/analytics';
  static const shortVideosLiveClip = '/api/short-videos/live-clip';
  static const shortVideosSuggestMetadata = '/api/short-videos/suggest-metadata';
  static const shortVideosMusicRecommend = '/api/short-videos/music/recommend';
  static String shortVideoSubtitlesGenerate(String id) =>
      '/api/short-videos/$id/subtitles/generate';
  static String shortVideoGifts(String id) => '/api/short-videos/$id/gifts';
  static String shortVideosByUser(String userId) =>
      '/api/short-videos/user/$userId';
  static String shortVideosProfile(String userId) =>
      '/api/short-videos/profile/$userId';
  static String shortVideosHashtag(String name) =>
      '/api/short-videos/hashtags/$name';
}
