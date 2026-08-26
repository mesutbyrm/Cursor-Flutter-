import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/network_perf.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/presentation/providers/discover_live_streams.dart';
import '../../../live/presentation/providers/discover_voice_rooms.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/datasources/mobile_compound_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_fortune_card_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_blog_post_entity.dart';
import '../../domain/entities/home_page_button_entity.dart';
import '../../domain/entities/home_trend_topic_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../../domain/home_site_catalog.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_room_sort.dart';
import '../../../live_psychics/domain/entities/psychic_entity.dart';
import '../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../../live/domain/pk/pk_leaderboard_models.dart';
import '../../../live/presentation/providers/pk_room_providers.dart';
import '../../../gifts/data/leaderboard_remote_datasource.dart';
import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../agency/domain/entities/agency_leaderboard_entry.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import '../../../platform/presentation/providers/platform_content_providers.dart';
import '../../domain/entities/home_football_match_entity.dart';
import '../../domain/entities/home_broadcast_image_entity.dart';
import '../../domain/entities/home_user_liker_entity.dart';
import '../../domain/entities/home_online_fal_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../platform/data/models/platform_ad.dart';
import '../../../platform/data/models/platform_popup.dart';
import '../../../platform/data/models/fortune_request_type.dart';
import '../../../voice_hub/domain/voice_official_join.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../../../gifts/domain/homepage_gift_ticker.dart';
import '../../../gifts/presentation/global/global_gift_notification.dart';
import '../../../gifts/presentation/global/global_gift_overlay_notifier.dart';
import '../../../vip_gold/domain/voice_room_access.dart';

void _keepHomeCacheAlive(Ref ref) => ref.keepAlive();

/// Homepage ticker hediye satırları — oturumda bir kez seed edilir.
final homepageGiftTickerGateProvider = Provider<HomepageGiftTickerGate>((ref) {
  return HomepageGiftTickerGate();
});

/// Ana sayfa keepAlive provider'larını SSE / realtime olayında yenile.
void invalidateHomeKeepAliveProviders(dynamic ref) {
  ref.invalidate(homeBannersProvider);
  ref.invalidate(homeFortuneCardsProvider);
  ref.invalidate(homeTrendVideosProvider);
  ref.invalidate(homeGamesProvider);
  ref.invalidate(homeDailyRewardsProvider);
  ref.invalidate(homeHomepageButtonsProvider);
  ref.invalidate(homeDisplayedPsychicsProvider);
  ref.invalidate(homeOnlineFalProvider);
  ref.invalidate(homeFortuneRequestTypesProvider);
  ref.invalidate(homePopupsProvider);
  invalidateDiscoverLiveStreams(ref);
  invalidateDiscoverVoiceRooms(ref);
  ref.invalidate(homeLiveStreamsProvider);
  ref.invalidate(homeVoiceRoomsProvider);
}

final homeRemoteProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(mobileCompoundRemoteProvider),
  );
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    ref.watch(homeRemoteProvider),
    ref.watch(liveRepositoryProvider),
    ref.watch(socialRepositoryProvider),
  );
});

final homeBannersProvider = FutureProvider<List<HomeBannerEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  final items = await ref.watch(homeRepositoryProvider).fetchBanners();
  final banners = <HomeBannerEntity>[];
  final marquee = ref.read(staffEntranceMarqueeProvider.notifier);
  for (final b in items) {
    if (VoiceOfficialJoin.isHomeBannerMarqueeOnly(
      b.title,
      subtitle: b.subtitle,
    )) {
      // Sabit büyük kart yerine kayan şerit (yetkili/Gold giriş + hediye).
      marquee.enqueue(b.title, roomName: b.subtitle);
      continue;
    }
    banners.add(b);
  }
  return banners;
});

/// `GET /api/homepage-ticker` — hediye satırları ana şeritte yok.
final homeTickerProvider = FutureProvider<List<String>>((ref) async {
  _keepHomeCacheAlive(ref);
  final lines = await ref.watch(homeRemoteProvider).fetchHomepageTicker();
  final news = HomepageGiftTicker.newsLines(lines);
  final marquee = ref.read(staffEntranceMarqueeProvider.notifier);
  for (final line in news) {
    marquee.enqueue(line);
  }
  final gifts = ref
      .read(homepageGiftTickerGateProvider)
      .takeNewGiftAnnouncements(lines);
  final overlay = ref.read(globalGiftOverlayProvider.notifier);
  for (final gift in gifts) {
    overlay.enqueue(GlobalGiftNotification.fromTicker(gift));
  }
  return news;
});

final homeFortuneCardsProvider = FutureProvider<List<HomeFortuneCardEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchHomepageFortuneCards();
});

final homeAdvisorsProvider = FutureProvider<List<OnlineAdvisorEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchOnlineAdvisors();
});

final homeLiveStreamsProvider = FutureProvider<List<LiveStreamEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  final cached = ref.watch(liveStreamsListNotifierProvider).valueOrNull;
  if (cached != null && cached.isNotEmpty) {
    return cached.where((s) => s.isLive).take(12).toList();
  }
  final all = await ref.read(liveStreamsListNotifierProvider.future);
  return all.where((s) => s.isLive).take(12).toList();
});

final homeVoiceRoomsProvider = FutureProvider<List<VoiceRoomEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  // Notifier her güncellendiğinde future'ı yeniden tetikleme — ana sayfa donmasını önler.
  return ref.read(voiceRoomsListNotifierProvider.future);
});

/// Ana sayfa sesli odalar — API listesi (dolu önce). SSE sayımı widget'ta tek sefer senkronize edilir.
final homeLiveVoiceRoomsProvider = Provider<AsyncValue<List<VoiceRoomEntity>>>((
  ref,
) {
  final roomsAsync = ref.watch(homeVoiceRoomsProvider);

  return roomsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (rooms) {
      final live = rooms.where((r) => !r.isVipGoldRoom).toList();
      final sorted = sortVoiceRoomsByPopularity(live).take(12).toList();
      return AsyncValue.data(sorted);
    },
  );
});

final homeGamesProvider = FutureProvider<List<HomeGameEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchGames();
});

final homeDailyRewardsProvider = FutureProvider<List<DailyRewardEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchDailyRewards();
});

final homeTrendVideosProvider = FutureProvider<List<HomeTrendVideoEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchTrendVideos();
});

/// `GET /api/homepage-buttons` — banner altı hızlı erişim.
final homeHomepageButtonsProvider = FutureProvider<List<HomePageButtonEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchHomepageButtons();
});

/// `GET /api/fan-clubs` — ana sayfa fan kulüpleri.
final homeFanClubsProvider = FutureProvider<List<HomeFanClubItem>>((ref) async {
  _keepHomeCacheAlive(ref);
  final remote = await ref.watch(homeRemoteProvider).fetchFanClubs();
  if (remote.isNotEmpty) return remote;
  return HomeSiteCatalog.fanClubs;
});

/// `GET /api/celebrities` — ana sayfa ünlüler şeridi.
final homeCelebritiesProvider = FutureProvider<List<HomeFanClubItem>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchCelebrities();
});

/// `GET /api/trends` — trend konu etiketleri.
final homeTrendTopicsProvider = FutureProvider<List<HomeTrendTopicEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchTrendingTopics();
});

/// `GET /api/blog/recent` — blog önizleme kartları.
final homeBlogRecentProvider = FutureProvider<List<HomeBlogPostEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchBlogRecent();
});

/// Haftalık hediye liderleri — `GET /api/leaderboards`.
final homeGiftLeaderboardProvider = FutureProvider<List<GiftLeaderboardEntry>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  final ds = LeaderboardRemoteDataSource(ref.watch(dioProvider));
  return ds.fetchGlobalGiftLeaderboard(period: GiftLeaderboardPeriod.weekly);
});

/// Canlı futbol maçları — `GET /api/football`.
final homeFootballMatchesProvider =
    FutureProvider<List<HomeFootballMatchEntity>>((ref) async {
      _keepHomeCacheAlive(ref);
      final raw = await ref
          .watch(platformContentRemoteDataSourceProvider)
          .fetchFootball();
      return raw
          .map(HomeFootballMatchEntity.fromJson)
          .where((m) => m.hasTeams)
          .take(8)
          .toList();
    });

/// Futbol merkezi — kılavuz `GET /api/football` (ana sayfa şeridinden daha uzun liste).
final footballHubMatchesProvider =
    FutureProvider.autoDispose<List<HomeFootballMatchEntity>>((ref) async {
      final raw = await ref
          .watch(platformContentRemoteDataSourceProvider)
          .fetchFootball();
      return raw
          .map(HomeFootballMatchEntity.fromJson)
          .where((m) => m.hasTeams)
          .toList();
    });

/// Yayın arka plan görselleri — `GET /api/broadcast-images`.
final homeBroadcastImagesProvider =
    FutureProvider<List<HomeBroadcastImageEntity>>((ref) async {
      _keepHomeCacheAlive(ref);
      final raw = await ref
          .watch(platformContentRemoteDataSourceProvider)
          .fetchBroadcastImages();
      return raw
          .map(HomeBroadcastImageEntity.fromJson)
          .where((e) => e.isValid)
          .take(10)
          .toList();
    });

/// Profil beğenenler — `GET /api/user/likers` (giriş gerekli).
final homeUserLikersProvider = FutureProvider<List<HomeUserLikerEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  if (ref.read(authControllerProvider).valueOrNull == null) {
    return const [];
  }
  final raw = await ref
      .watch(platformContentRemoteDataSourceProvider)
      .fetchUserLikers();
  return raw
      .map(HomeUserLikerEntity.fromJson)
      .where((e) => e.isValid)
      .take(10)
      .toList();
});

/// Aktif reklamlar — `GET /api/ads/active` (giriş gerekli).
final homeActiveAdsProvider = FutureProvider<List<PlatformAd>>((ref) async {
  _keepHomeCacheAlive(ref);
  if (ref.read(authControllerProvider).valueOrNull == null) {
    return const [];
  }
  return ref.watch(platformContentRemoteDataSourceProvider).fetchActiveAds();
});

/// Site popup duyuruları — `GET /api/popups`.
final homePopupsProvider = FutureProvider<List<PlatformPopup>>((ref) async {
  _keepHomeCacheAlive(ref);
  final popups = await ref
      .watch(platformContentRemoteDataSourceProvider)
      .fetchPopups();
  return popups
      .where((p) => p.id.isNotEmpty && p.title.trim().isNotEmpty)
      .take(3)
      .toList();
});

/// Fal istek türleri — `GET /api/fortune-request-types`.
final homeFortuneRequestTypesProvider =
    FutureProvider<List<FortuneRequestType>>((ref) async {
      _keepHomeCacheAlive(ref);
      return ref
          .watch(platformContentRemoteDataSourceProvider)
          .fetchFortuneRequestTypes();
    });

/// Online fal bölümleri — `GET /api/online-fal`.
final homeOnlineFalProvider = FutureProvider<List<HomeOnlineFalEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  final raw = await ref
      .watch(platformContentRemoteDataSourceProvider)
      .fetchOnlineFal();
  return raw
      .map(HomeOnlineFalEntity.fromJson)
      .where((s) => s.isValid)
      .take(8)
      .toList();
});

/// Ajans liderlik tablosu — `GET /api/agency/leaderboard`.
final homeAgencyLeaderboardProvider =
    FutureProvider<List<AgencyLeaderboardEntry>>((ref) async {
      _keepHomeCacheAlive(ref);
      return ref.read(agencyRemoteProvider).fetchLeaderboard(limit: 10);
    });

/// Haftalık PK liderleri — `GET /api/pk/leaderboard`.
final homePkLeaderboardProvider = FutureProvider<List<PkLeaderboardEntry>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref
      .read(pkRoomRemoteProvider)
      .leaderboard(period: 'weekly', metric: 'score', limit: 10);
});

/// Canlı falcılar — yalnızca `GET /api/fortune-tellers` (online öncelikli).
final homeDisplayedPsychicsProvider = FutureProvider<List<PsychicEntity>>((
  ref,
) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeOnlinePsychicsProvider.future);
});

/// Tüm ana sayfa verilerini yenile (yalnızca ekranda görünen bölümler).
Future<void> refreshHomeData(WidgetRef ref) async {
  ref.read(homeRemoteProvider).invalidateMobileHomeCache();
  await NetworkPerf.waitSilent([
    ref.refresh(homeBannersProvider.future),
    ref.refresh(homeHomepageButtonsProvider.future),
    ref.refresh(homeTrendVideosProvider.future),
    ref.refresh(homeLiveStreamsProvider.future),
    ref.refresh(homeVoiceRoomsProvider.future),
    ref.refresh(homeFortuneCardsProvider.future),
    ref.refresh(homeGamesProvider.future),
    ref.refresh(homeDailyRewardsProvider.future),
    ref.refresh(homeDisplayedPsychicsProvider.future),
    ref.refresh(homeOnlineFalProvider.future),
    ref.refresh(homeFortuneRequestTypesProvider.future),
    ref.refresh(homePopupsProvider.future),
    ref.refresh(socialStoryRingsProvider.future),
  ]).timeout(const Duration(seconds: 12), onTimeout: () {});
}
