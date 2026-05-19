/// canlifal.com ile uyumlu uçlar. Özel backend için `API_BASE_URL` ve bu dosyayı güncelleyin.
abstract final class ApiEndpoints {
  // --- NextAuth (canlifal.com) ---
  static const authCsrf = '/api/auth/csrf';
  static const authCredentials = '/api/auth/callback/credentials';
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
  static const liveStreams = '/api/live';

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
}
