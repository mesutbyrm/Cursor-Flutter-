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
  static const socialPostsAutoFortune = '/api/social/posts/auto-fortune';
  static String socialPostDelete(String id) => '/api/social/posts/$id';
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

  static String chatRoomDj(String roomId) => '/api/chat/rooms/$roomId/dj';

  static String chatRoomGifts(String roomId) => '/api/chat/rooms/$roomId/gifts';
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

  static String videoStreamEnd(String streamId) => '/api/video-streams/$streamId/end';

  static String videoStreamGifts(String streamId) =>
      '/api/video-streams/$streamId/gifts';

  static String videoStreamGiftLeaderboard(String streamId) =>
      '/api/video-streams/$streamId/gifts/leaderboard';

  static const giftsCatalog = '/api/gifts';

  static String userProfile(String userId) => '/api/users/$userId';

  /// Kullanıcı adı ile profil — Flutter API dokümanı.
  static String userLookup(String username) =>
      '/api/users/lookup/${Uri.encodeComponent(username.trim())}';

  /// Yayın geçmişi (site dokümanı: `/api/user/broadcast-history`).
  static const userBroadcastHistory = '/api/user/broadcast-history';

  /// Aktivite / bildirimler (site dokümanı: `/api/user/activity`).
  static const userActivity = '/api/user/activity';
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
}
