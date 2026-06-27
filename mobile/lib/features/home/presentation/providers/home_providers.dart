import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_fortune_card_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../../live/domain/entities/live_stream_entity.dart';

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

final homeFortuneCardsProvider =
    FutureProvider<List<HomeFortuneCardEntity>>((ref) async {
  return ref.watch(homeRemoteProvider).fetchHomepageFortuneCards();
});

final homeAdvisorsProvider =
    FutureProvider<List<OnlineAdvisorEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchOnlineAdvisors();
});

final homeLiveStreamsProvider =
    FutureProvider<List<LiveStreamEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchLiveStreams();
});

final homeGamesProvider = FutureProvider<List<HomeGameEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchGames();
});

final homeDailyRewardsProvider =
    FutureProvider<List<DailyRewardEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchDailyRewards();
});

final homeTrendVideosProvider =
    FutureProvider<List<HomeTrendVideoEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchTrendVideos();
});

/// Tüm ana sayfa verilerini yenile.
Future<void> refreshHomeData(WidgetRef ref) async {
  ref.invalidate(homeBannersProvider);
  ref.invalidate(psychicsListControllerProvider);
  ref.invalidate(homeAdvisorsProvider);
  ref.invalidate(homeLiveStreamsProvider);
  ref.invalidate(homeGamesProvider);
  ref.invalidate(homeDailyRewardsProvider);
  ref.invalidate(homeFortuneCardsProvider);
  ref.invalidate(homeTrendVideosProvider);
  ref.invalidate(socialStoryRingsProvider);
  ref.invalidate(shortsFeedProvider);

  await Future.wait([
    ref.refresh(homeBannersProvider.future),
    ref.refresh(psychicsListControllerProvider.future),
    ref.refresh(homeAdvisorsProvider.future),
    ref.refresh(homeLiveStreamsProvider.future),
    ref.refresh(homeGamesProvider.future),
    ref.refresh(homeDailyRewardsProvider.future),
    ref.refresh(homeFortuneCardsProvider.future),
    ref.refresh(homeTrendVideosProvider.future),
    ref.refresh(socialStoryRingsProvider.future),
  ]);
}
