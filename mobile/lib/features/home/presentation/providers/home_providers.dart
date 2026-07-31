import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/network_perf.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../live/presentation/providers/discover_live_streams.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_banner_entity.dart';
import '../../domain/entities/home_fortune_card_entity.dart';
import '../../domain/entities/home_game_entity.dart';
import '../../domain/entities/home_trend_video_entity.dart';
import '../../domain/entities/online_advisor_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_room_sort.dart';
import '../../../voice_hub/domain/voice_official_join.dart';
import '../../../voice_hub/presentation/providers/staff_entrance_marquee_provider.dart';
import '../../../voice_hub/presentation/providers/voice_rooms_presence_provider.dart';
import '../../../vip_gold/domain/voice_room_access.dart';

void _keepHomeCacheAlive(Ref ref) => ref.keepAlive();

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
  return ref.watch(homeRepositoryProvider).fetchLiveStreams();
});

final homeVoiceRoomsProvider =
    FutureProvider<List<VoiceRoomEntity>>((ref) async {
  _keepHomeCacheAlive(ref);
  return ref.watch(homeRepositoryProvider).fetchVoiceRooms();
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

/// Tüm ana sayfa verilerini yenile (yalnızca ekranda görünen bölümler).
Future<void> refreshHomeData(WidgetRef ref) async {
  await NetworkPerf.waitSilent([
    ref.refresh(homeBannersProvider.future),
    ref.refresh(homeTrendVideosProvider.future),
    ref.refresh(homeLiveStreamsProvider.future),
    ref.refresh(homeVoiceRoomsProvider.future),
    ref.refresh(homeFortuneCardsProvider.future),
    ref.refresh(socialStoryRingsProvider.future),
  ]).timeout(
    const Duration(seconds: 12),
    onTimeout: () {},
  );
}
