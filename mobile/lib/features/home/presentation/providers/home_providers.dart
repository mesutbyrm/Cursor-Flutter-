import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/network_perf.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../shorts/domain/repositories/shorts_repository.dart';
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

final homeTrendVideosProvider =
    FutureProvider<List<HomeTrendVideoEntity>>((ref) async {
  return ref.watch(homeRepositoryProvider).fetchTrendVideos();
});

/// Tüm ana sayfa verilerini yenile.
///
/// `waitSilent`: tek bir isteğin hatası diğerlerini ve göstergeyi kilitlemez.
/// Genel zaman aşımı: yavaş/askıda kalan bir uç nokta yenileme döngüsünü
/// sonsuza kadar döndürmesin (kullanıcı "sürekli dönüyor" sorunu).
Future<void> refreshHomeData(WidgetRef ref) async {
  // `ref.refresh(...future)` zaten invalidate edip yeniden getirir;
  // ayrıca invalidate çağırmak çift fetch'e yol açtığı için kaldırıldı.
  await NetworkPerf.waitSilent([
    ref.refresh(homeBannersProvider.future),
    ref.refresh(psychicsListControllerProvider.future),
    ref.refresh(homeAdvisorsProvider.future),
    ref.refresh(homeLiveStreamsProvider.future),
    ref.refresh(homeVoiceRoomsProvider.future),
    ref.refresh(homeGamesProvider.future),
    ref.refresh(homeDailyRewardsProvider.future),
    ref.refresh(homeFortuneCardsProvider.future),
    ref.refresh(homeTrendVideosProvider.future),
    ref.refresh(socialStoryRingsProvider.future),
    ref.refresh(shortsFeedProvider(ShortsFeedTab.forYou).future),
    ref.refresh(shortsExploreProvider.future),
  ]).timeout(
    const Duration(seconds: 12),
    onTimeout: () {},
  );
}
