import '../entities/entities.dart';

abstract class SocialRepository {
  Future<List<ContentPost>> getFeedPage(int page);

  Future<List<StoryItem>> getStories();

  Future<List<LiveStream>> getLiveStreams();

  Future<LiveStream?> getLiveStream(String id);

  Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String description,
  });

  Future<List<ChatRoom>> getChatRooms();

  Future<List<ChatMessage>> getMessages(String roomId);

  Future<List<FortuneService>> getFortuneServices();

  Future<List<NotificationItem>> getNotifications();

  Future<List<AdminMetric>> getAdminMetrics();

  Future<List<ContentPost>> getExplorePosts();

  Future<AppUser> getProfile(String userId);

  Future<AppUser> followUser(String userId);

  Future<AppUser> unfollowUser(String userId);

  Future<int> getCoinBalance();

  Future<int> spendCoins(int amount, {String? reason});
}
