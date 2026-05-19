import '../../domain/entities/entities.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._remote);

  final SocialRemoteDatasource _remote;

  @override
  Future<List<ContentPost>> getFeedPage(int page) => _remote.getFeedPage(page);

  @override
  Future<List<StoryItem>> getStories() async {
    final List<FortuneService> tellers = await getFortuneServices();
    return tellers
        .where((FortuneService service) => service.isLive)
        .map(
          (FortuneService service) => StoryItem(
            id: service.id,
            title: service.advisor.displayName,
            imageUrl: service.advisor.avatarUrl,
            owner: service.advisor,
            isLive: service.isLive,
          ),
        )
        .toList();
  }

  @override
  Future<List<LiveStream>> getLiveStreams() => _remote.getLiveStreams();

  @override
  Future<LiveStream?> getLiveStream(String id) => _remote.getLiveStream(id);

  @override
  Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String description,
  }) => _remote.createLiveRoom(title: title, description: description);

  @override
  Future<List<ChatRoom>> getChatRooms() => _remote.getChatRooms();

  @override
  Future<List<ChatMessage>> getMessages(String roomId) =>
      _remote.getMessages(roomId);

  @override
  Future<List<FortuneService>> getFortuneServices() =>
      _remote.getFortuneServices();

  @override
  Future<List<NotificationItem>> getNotifications() =>
      _remote.getNotifications();

  @override
  Future<List<AdminMetric>> getAdminMetrics() => _remote.getAdminMetrics();

  @override
  Future<List<ContentPost>> getExplorePosts() => _remote.getExplorePosts();

  @override
  Future<AppUser> getProfile(String userId) => _remote.getProfile(userId);

  @override
  Future<AppUser> followUser(String userId) => _remote.followUser(userId);

  @override
  Future<AppUser> unfollowUser(String userId) => _remote.unfollowUser(userId);

  @override
  Future<int> getCoinBalance() => _remote.getCoinBalance();

  @override
  Future<int> spendCoins(int amount, {String? reason}) =>
      _remote.spendCoins(amount, reason: reason);
}
