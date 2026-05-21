/// canlifal.com ile uyumlu uçlar. Özel backend için `API_BASE_URL` ve bu dosyayı güncelleyin.
abstract final class ApiEndpoints {
  // --- NextAuth (canlifal.com) ---
  static const authCsrf = '/api/auth/csrf';
  static const authCredentials = '/api/auth/callback/credentials';
  /// NextAuth Google OAuth başlangıcı (canlifal.com `/api/auth/providers`).
  static const authSignInGoogle = '/api/auth/signin/google';
  static const authSession = '/api/auth/session';
  static const authSignOut = '/api/auth/signout';

  // --- Klasik JWT REST (diğer ortamlar) ---
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  // --- Uygulama API (çerez veya Bearer) ---
  static const feed = '/api/stories';
  /// canlifal.com sosyal akış (web `/sosyal` ile aynı veri).
  static const socialPosts = '/api/social/posts';
  /// canlifal.com ana sayfa canlı yayın listesi (JSON dizi).
  static const videoStreams = '/api/video-streams';
  /// Sesli / metin sohbet odaları (web `/sohbet/{slug}`).
  static const chatRooms = '/api/chat/rooms';

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

  /// Arkadaş daveti — bağlantı veya kod (oturum gerekir).
  static const referral = '/api/referral';
  /// Diğer ortamlar için genel canlı listesi.
  static const liveStreams = '/api/live';

  /// Tencent TRTC UserSig (POST: userId, roomId).
  static const trtcUserSig = '/api/trtc/usersig';

  /// Canlı yayın hediye kataloğu (Tencent / site ile aynı liste).
  static const videoStreamGiftsCatalog = '/api/video-streams/gifts';

  static String videoStreamEnd(String streamId) => '/api/video-streams/$streamId/end';

  static String videoStreamGifts(String streamId) =>
      '/api/video-streams/$streamId/gifts';

  static String userProfile(String userId) => '/api/users/$userId';
  static String follow(String userId) => '/api/users/$userId/follow';
  static String followers(String userId) => '/api/users/$userId/followers';
  static String following(String userId) => '/api/users/$userId/following';

  static const conversations = '/api/messages/conversations';
  static String conversationMessages(String id) =>
      '/api/messages/conversations/$id/messages';

  static const notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id/read';

  static const wallet = '/api/wallet';

  /// İçerik / kullanıcı şikayeti (canlifal moderasyon API).
  static const reports = '/api/reports';
}
