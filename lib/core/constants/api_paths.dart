/// Canlifal public REST yolları (base: `CANLIFAL_API_URL`).
abstract final class ApiPaths {
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/users/me';
  static const String trendVideos = '/trend-videos';
  static const String videoStreams = '/video-streams';
  static const String chatRooms = '/chat/rooms';
  static const String fortuneTellers = '/fortune-tellers';
  static const String announcements = '/announcements';
  static const String celebrityPosts = '/celebrities/posts/latest';
  static const String publicStats = '/public-stats';
  static const String forgotPassword = '/auth/forgot-password';

  static String userProfile(String userId) => '/users/$userId';
  static String followUser(String userId) => '/users/$userId/follow';
  static String chatMessages(String roomId) => '/chat/rooms/$roomId/messages';
  static String coinsBalance = '/coins/balance';
  static String coinsSpend = '/coins/spend';
}
