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
import '../../../platform/presentation/providers/platform_content_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../../domain/entities/home_football_match_entity.dart';
import '../../../voice_hub/domain/voice_official_join.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../../../voice_hub/presentation/providers/voice_rooms_presence_provider.dart';
import '../../../vip_gold/domain/voice_room_access.dart';

void _keepHomeCacheAlive(Ref ref) => ref.keepAlive();

/// Ana sayfa keepAlive provider'larını SSE / realtime olayında yenile.
void invalidateHomeKeepAliveProviders(dynamic ref) {
  ref.invalidate(homeBannersProvider);
  ref.invalidate(homeFortuneCardsProvider);
  ref.invalidate(homeTrendVideosProvider);
  ref.invalidate(homeAdvisorsProvider);
  ref.invalidate(homeGamesProvider);
  ref.invalidate(homeDailyRewardsProvider);
  ref.invalidate(homeTickerProvider);
  ref.invalidate(homeHomepageButtonsProvider);
  ref.invalidate(homeFanClubsProvider);
  ref.invalidate(homeCelebritiesProvider);
  ref.invalidate(homeTrendTopicsProvider);
  ref.invalidate(homeBlogRecentProvider);
  ref.invalidate(homeDisplayedPsychicsProvider);
  ref.invalidate(homeGiftLeaderboardProvider);
  ref.invalidate(homeFootballMatchesProvider);
  ref.invalidate(homePkLeaderboardProvider);
  ref.invalidate(platformStatsProvider);
  invalidateDiscoverLiveStreams(ref);
  invalidateDiscoverVoiceRooms(ref);
  ref.invalidate(homeLiveStreamsProvider);
  ref.invalidate(homeVoiceRoomsProvider);
}

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

/// `GET /api/homepage-ticker` — site geneli kayan yazılar.
final homeTickerProvider = FutureProvider<List<String>>((ref) async {
  _keepHomeCacheAlive(ref);
  final lines = await ref.watch(homeRemoteProvider).fetchHomepageTicker();
  final marquee = ref.read(staffEntranceMarqueeProvider.notifier);
  for (final line in lines) {
    marquee.enqueue(line);
  }
  return lines;
});

final homeFortuneCardsProvider =
    FutureProvider<List<HomeFortuneCardEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchHomepageFortuneCards();
});

final homeAdvisorsProvider =
    FutureProvider<List<OnlineAdvisorEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchOnlineAdvisors();
});

final homeLiveStreamsProvider =
    FutureProvider<List<LiveStreamEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  final cached = ref.watch(liveStreamsListNotifierProvider).valueOrNull;
  if (cached != null && cached.isNotEmpty) {
    return cached.where((s) => s.isLive).take(12).toList();
  }
  final all = await ref.read(liveStreamsListNotifierProvider.future);
  return all.where((s) => s.isLive).take(12).toList();
});

final homeVoiceRoomsProvider =
    FutureProvider<List<VoiceRoomEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  final cached = ref.watch(voiceRoomsListNotifierProvider).valueOrNull;
  if (cached != null) return cached;
  return ref.read(voiceRoomsListNotifierProvider.future);
});

/// Ana sayfa sesli odalar — yalnızca içinde kullanıcı olanlar, SSE ile güncel sayı.
final homeVoiceRoomPresenceSyncProvider = Provider<void>((ref) {
  ref.listen(homeVoiceRoomsProvider, (prev, next) {
    final rooms = next.valueOrNull;
    if (rooms != null) {
      ref.read(voiceRoomsPresenceProvider.notifier).mergeTrackRooms(rooms);
    }
  }, fireImmediately: true);
});

final homeLiveVoiceRoomsProvider = Provider<AsyncValue<List<VoiceRoomEntity>>>(
  (ref) {
    ref.watch(homeVoiceRoomPresenceSyncProvider);
    final roomsAsync = ref.watch(homeVoiceRoomsProvider);
    final presence = ref.watch(voiceRoomsPresenceProvider);
    return roomsAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (rooms) {
        final live = rooms.where((r) => !r.isVipGoldRoom).map((r) {
          final sseCount = presence.countFor(r);
          final apiCount = r.displayOnline;
          final count = sseCount > 0 ? sseCount : apiCount;
          if (count <= 0) return r;
          return r.copyWith(onlineCount: count, userCount: count);
        }).toList();
        final sorted = sortVoiceRoomsByPopularity(live).take(12).toList();
        return AsyncValue.data(sorted.isNotEmpty ? sorted : rooms.take(12).toList());
      },
    );
  },
);

final homeGamesProvider = FutureProvider<List<HomeGameEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchGames();
});

final homeDailyRewardsProvider =
    FutureProvider<List<DailyRewardEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchDailyRewards();
});

final homeTrendVideosProvider =
    FutureProvider<List<HomeTrendVideoEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchTrendVideos();
});

/// `GET /api/homepage-buttons` — banner altı hızlı erişim.
final homeHomepageButtonsProvider =
    FutureProvider<List<HomePageButtonEntity>>((ref) async {
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
final homeCelebritiesProvider = FutureProvider<List<HomeFanClubItem>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchCelebrities();
});

/// `GET /api/trends` — trend konu etiketleri.
final homeTrendTopicsProvider =
    FutureProvider<List<HomeTrendTopicEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchTrendingTopics();
});

/// `GET /api/blog/recent` — blog önizleme kartları.
final homeBlogRecentProvider =
    FutureProvider<List<HomeBlogPostEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRemoteProvider).fetchBlogRecent();
});

/// Haftalık hediye liderleri — `GET /api/leaderboards`.
final homeGiftLeaderboardProvider =
    FutureProvider<List<GiftLeaderboardEntry>>((ref) async {
  _keepHomeCacheAlive(ref);
  final ds = LeaderboardRemoteDataSource(ref.watch(dioProvider));
  return ds.fetchGlobalGiftLeaderboard(
    period: GiftLeaderboardPeriod.weekly,
  );
});

/// Canlı futbol maçları — `GET /api/football`.
final homeFootballMatchesProvider =
    FutureProvider<List<HomeFootballMatchEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  final raw =
      await ref.watch(platformContentRemoteDataSourceProvider).fetchFootball();
  return raw
      .map(HomeFootballMatchEntity.fromJson)
      .where((m) => m.hasTeams)
      .take(8)
      .toList();
});

/// Haftalık PK liderleri — `GET /api/pk/leaderboard`.
final homePkLeaderboardProvider =
    FutureProvider<List<PkLeaderboardEntry>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.read(pkRoomRemoteProvider).leaderboard(
        period: 'weekly',
        metric: 'score',
        limit: 10,
      );
});

/// Canlı falcılar — boşsa compound/API danışman listesine düşer.
final homeDisplayedPsychicsProvider =
    FutureProvider<List<PsychicEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  final psychics = await ref.watch(homeOnlinePsychicsProvider.future);
  if (psychics.isNotEmpty) return psychics;
  final advisors = await ref.watch(homeAdvisorsProvider.future);
  return advisors
      .map(
        (a) => PsychicEntity(
          id: a.id,
          name: a.name,
          avatarUrl: a.avatarUrl,
          isOnline: a.isOnline,
          rating: a.rating,
          specialties: a.specialties,
          category: a.category,
        ),
      )
      .where((p) => p.id.isNotEmpty)
      .toList();
});

/// Tüm ana sayfa verilerini yenile (yalnızca ekranda görünen bölümler).
Future<void> refreshHomeData(WidgetRef ref) async {
  ref.read(homeRemoteProvider).invalidateMobileHomeCache();
  await NetworkPerf.waitSilent([
    ref.refresh(homeBannersProvider.future),
    ref.refresh(homeTickerProvider.future),
    ref.refresh(homeHomepageButtonsProvider.future),
    ref.refresh(homeTrendVideosProvider.future),
    ref.refresh(homeTrendTopicsProvider.future),
    ref.refresh(homeBlogRecentProvider.future),
    ref.refresh(homeLiveStreamsProvider.future),
    ref.refresh(homeVoiceRoomsProvider.future),
    ref.refresh(homeFortuneCardsProvider.future),
    ref.refresh(homeGamesProvider.future),
    ref.refresh(homeDailyRewardsProvider.future),
    ref.refresh(homeFanClubsProvider.future),
    ref.refresh(homeCelebritiesProvider.future),
    ref.refresh(homeDisplayedPsychicsProvider.future),
    ref.refresh(homeGiftLeaderboardProvider.future),
    ref.refresh(homeFootballMatchesProvider.future),
    ref.refresh(homePkLeaderboardProvider.future),
    ref.refresh(platformStatsProvider.future),
    ref.refresh(referralInfoProvider.future),
    ref.refresh(userDailyTasksProvider.future),
    ref.refresh(socialStoryRingsProvider.future),
  ]).timeout(
    const Duration(seconds: 12),
    onTimeout: () {},
  );
}
