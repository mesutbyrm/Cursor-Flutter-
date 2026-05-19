/// Backend ile hizalanacak REST yolları. Sunucu farklıysa burayı güncelleyin.
abstract final class ApiEndpoints {
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';

  static const feed = '/feed';

  static String userProfile(String userId) => '/users/$userId';
  static String follow(String userId) => '/users/$userId/follow';
  static String followers(String userId) => '/users/$userId/followers';
  static String following(String userId) => '/users/$userId/following';

  static const liveStreams = '/live/streams';

  static const conversations = '/messages/conversations';
  static String conversationMessages(String id) =>
      '/messages/conversations/$id/messages';

  static const notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';

  static const wallet = '/wallet';
}
