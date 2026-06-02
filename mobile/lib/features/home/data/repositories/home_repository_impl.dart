import '../../../feed/domain/entities/post_entity.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/repositories/live_repository.dart';
import '../../../social/domain/repositories/social_repository.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(
    this._remote,
    this._live,
    this._social,
  );

  final HomeRemoteDataSource _remote;
  final LiveRepository _live;
  final SocialRepository _social;

  @override
  Future<List<HomeBannerEntity>> fetchBanners() => _remote.fetchBanners();

  @override
  Future<List<OnlineAdvisorEntity>> fetchOnlineAdvisors() =>
      _remote.fetchOnlineAdvisors();

  @override
  Future<List<LiveStreamEntity>> fetchLiveStreams() =>
      _live.fetchStreams(page: 1);

  @override
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() => _live.fetchVoiceRooms();

  @override
  Future<HomeFeedBundle> fetchFeedPosts({required int page}) async {
    final bundle = await _social.fetchPage(page: page);
    return HomeFeedBundle(
      posts: bundle.posts,
      hasMore: bundle.hasMore,
      page: page,
    );
  }

  @override
  Future<List<HomeGameEntity>> fetchGames() => _remote.fetchGames();

  @override
  Future<List<DailyRewardEntity>> fetchDailyRewards() =>
      _remote.fetchDailyRewards();

  @override
  Future<List<HomeTrendVideoEntity>> fetchTrendVideos() =>
      _remote.fetchTrendVideos();
}
