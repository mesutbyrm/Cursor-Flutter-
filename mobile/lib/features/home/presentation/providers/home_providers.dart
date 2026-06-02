import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

final homeRemoteProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSource(ref.watch(dioProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    ref.watch(homeRemoteProvider),
    ref.watch(liveRepositoryProvider),
    ref.watch(socialRepositoryProvider),
  );
});

final homeBannersProvider = FutureProvider<List<HomeBannerEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchBanners();
});

final homeAdvisorsProvider =
    FutureProvider<List<OnlineAdvisorEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchOnlineAdvisors();
});

final homeLiveStreamsProvider =
    FutureProvider<List<LiveStreamEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchLiveStreams();
});

final homeVoiceRoomsProvider =
    FutureProvider<List<VoiceRoomEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchVoiceRooms();
});

final homeGamesProvider = FutureProvider<List<HomeGameEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchGames();
});

final homeDailyRewardsProvider =
    FutureProvider<List<DailyRewardEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchDailyRewards();
});

/// Ana sayfa sosyal akış — sayfalama.
class HomeFeedNotifier extends AsyncNotifier<List<PostEntity>> {
  var _page = 1;
  var _hasMore = true;
  var _loadingMore = false;

  @override
  Future<List<PostEntity>> build() async {
    _page = 1;
    _hasMore = true;
    final bundle =
        await ref.read(homeRepositoryProvider).fetchFeedPosts(page: 1);
    _hasMore = bundle.hasMore;
    return bundle.posts;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      _hasMore = true;
      final bundle =
          await ref.read(homeRepositoryProvider).fetchFeedPosts(page: 1);
      _hasMore = bundle.hasMore;
      return bundle.posts;
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !_hasMore || _loadingMore) return;
    _loadingMore = true;
    final next = _page + 1;
    try {
      final bundle =
          await ref.read(homeRepositoryProvider).fetchFeedPosts(page: next);
      if (bundle.posts.isEmpty) {
        _hasMore = false;
        return;
      }
      _page = next;
      _hasMore = bundle.hasMore;
      state = AsyncValue.data([...cur, ...bundle.posts]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get canLoadMore => _hasMore && !_loadingMore;
}

final homeFeedNotifierProvider =
    AsyncNotifierProvider<HomeFeedNotifier, List<PostEntity>>(
  HomeFeedNotifier.new,
);

/// Tüm ana sayfa verilerini yenile.
Future<void> refreshHomeData(WidgetRef ref) async {
  ref.invalidate(homeBannersProvider);
  ref.invalidate(homeAdvisorsProvider);
  ref.invalidate(homeLiveStreamsProvider);
  ref.invalidate(homeVoiceRoomsProvider);
  ref.invalidate(homeGamesProvider);
  ref.invalidate(homeDailyRewardsProvider);
  await Future.wait([
    ref.refresh(homeBannersProvider.future),
    ref.refresh(homeAdvisorsProvider.future),
    ref.refresh(homeLiveStreamsProvider.future),
    ref.refresh(homeVoiceRoomsProvider.future),
    ref.refresh(homeGamesProvider.future),
    ref.read(homeFeedNotifierProvider.notifier).refresh(),
  ]);
}
