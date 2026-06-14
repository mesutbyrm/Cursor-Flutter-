import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/shorts_remote_datasource.dart';
import '../../data/repositories/shorts_repository_impl.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';

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

class ShortsFeedNotifier extends AsyncNotifier<List<ShortVideoEntity>> {
  String? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  Future<List<ShortVideoEntity>> build() async {
    _cursor = null;
    _hasMore = true;
    final page = await ref.read(shortsRepositoryProvider).fetchFeed();
    _cursor = page.nextCursor;
    _hasMore = page.hasMore;
    return page.videos;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _cursor = null;
      _hasMore = true;
      final page = await ref.read(shortsRepositoryProvider).fetchFeed();
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
      final page = await ref
          .read(shortsRepositoryProvider)
          .fetchFeed(cursor: _cursor);
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
}

final shortsFeedProvider =
    AsyncNotifierProvider<ShortsFeedNotifier, List<ShortVideoEntity>>(
  ShortsFeedNotifier.new,
);

final userShortVideosProvider =
    FutureProvider.family<List<ShortVideoEntity>, String>((ref, userId) async {
  return ref.read(shortsRepositoryProvider).fetchByUser(userId);
});
