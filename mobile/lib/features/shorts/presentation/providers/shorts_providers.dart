import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/shorts_remote_datasource.dart';
import '../../data/repositories/shorts_repository_impl.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';

export 'shorts_explore_providers.dart';

final shortsRemoteProvider = Provider<ShortsRemoteDataSource>((ref) {
  return ShortsRemoteDataSource(ref.watch(dioProvider));
});

final shortsRepositoryProvider = Provider<ShortsRepository>((ref) {
  return ShortsRepositoryImpl(ref.watch(shortsRemoteProvider));
});

final shortVideoCacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager(
    Config(
      'short_videos_v1',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 40,
    ),
  );
});

class ShortsFeedNotifier
    extends FamilyAsyncNotifier<List<ShortVideoEntity>, ShortsFeedTab> {
  String? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<ShortVideoEntity>> build(ShortsFeedTab tab) async {
    _cursor = null;
    _hasMore = true;
    final page = await ref
        .read(shortsRepositoryProvider)
        .fetchFeed(tab: tab);
    _cursor = page.nextCursor;
    _hasMore = page.hasMore;
    return page.videos;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _cursor = null;
      _hasMore = true;
      final page = await ref
          .read(shortsRepositoryProvider)
          .fetchFeed(tab: arg);
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
      return page.videos;
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !_hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await ref.read(shortsRepositoryProvider).fetchFeed(
            cursor: _cursor,
            tab: arg,
          );
      if (page.videos.isEmpty) {
        _hasMore = false;
        return;
      }
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
      state = AsyncValue.data([...cur, ...page.videos]);
    } finally {
      _loadingMore = false;
    }
  }

  void patchVideo(String id, ShortVideoEntity updated) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data([
      for (final v in cur) v.id == id ? updated : v,
    ]);
  }

  Future<void> ensureVideo(String videoId) async {
    final cur = state.valueOrNull ?? const <ShortVideoEntity>[];
    if (cur.any((v) => v.id == videoId)) return;
    try {
      final video = await ref.read(shortsRepositoryProvider).fetchVideo(videoId);
      state = AsyncValue.data([video, ...cur]);
    } catch (_) {}
  }
}

final shortsFeedProvider = AsyncNotifierProvider.family<
    ShortsFeedNotifier, List<ShortVideoEntity>, ShortsFeedTab>(
  ShortsFeedNotifier.new,
);

final shortsFeedTabProvider =
    StateProvider<ShortsFeedTab>((ref) => ShortsFeedTab.forYou);

final userShortVideosProvider = FutureProvider.family<
    List<ShortVideoEntity>, ({String userId, ShortUserVideosTab tab})>(
  (ref, params) async {
    return ref.read(shortsRepositoryProvider).fetchByUser(
          params.userId,
          tab: params.tab,
        );
  },
);

final shortVideoProfileStatsProvider =
    FutureProvider.family<ShortProfileStats, String>((ref, userId) async {
  return ref.read(shortsRepositoryProvider).fetchProfileStats(userId);
});

final viewedShortsProvider =
    FutureProvider.autoDispose<List<ShortVideoEntity>>((ref) async {
  return ref.read(shortsRepositoryProvider).fetchViewedByMe();
});

final shortVideoDuetsProvider =
    FutureProvider.family<List<ShortVideoEntity>, String>((ref, videoId) async {
  return ref.read(shortsRepositoryProvider).fetchDuets(videoId);
});

final trendingHashtagsProvider =
    FutureProvider.autoDispose<List<ShortHashtagEntity>>((ref) async {
  return ref.read(shortsRepositoryProvider).fetchTrendingHashtags();
});

final shortMusicSearchProvider =
    FutureProvider.family<List<ShortMusicEntity>, String>((ref, query) async {
  return ref.read(shortsRepositoryProvider).searchMusic(query);
});

final shortHashtagVideosProvider =
    FutureProvider.family<List<ShortVideoEntity>, String>((ref, name) async {
  return ref.read(shortsRepositoryProvider).fetchHashtagVideos(name);
});
