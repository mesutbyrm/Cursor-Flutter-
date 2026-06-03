import '../../../feed/domain/entities/post_entity.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../entities/home_banner_entity.dart';
import '../entities/home_game_entity.dart';
import '../entities/home_trend_video_entity.dart';
import '../entities/online_advisor_entity.dart';

class HomeFeedBundle {
  const HomeFeedBundle({
    required this.posts,
    required this.hasMore,
    required this.page,
  });

  final List<PostEntity> posts;
  final bool hasMore;
  final int page;
}

abstract interface class HomeRepository {
  Future<List<HomeBannerEntity>> fetchBanners();
  Future<List<OnlineAdvisorEntity>> fetchOnlineAdvisors();
  Future<List<LiveStreamEntity>> fetchLiveStreams();
  Future<List<VoiceRoomEntity>> fetchVoiceRooms();
  Future<HomeFeedBundle> fetchFeedPosts({required int page});
  Future<List<HomeGameEntity>> fetchGames();
  Future<List<DailyRewardEntity>> fetchDailyRewards();
  Future<List<HomeTrendVideoEntity>> fetchTrendVideos();
}
