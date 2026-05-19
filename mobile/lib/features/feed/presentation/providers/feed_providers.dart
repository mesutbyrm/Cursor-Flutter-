import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/repositories/feed_repository_impl.dart';

final feedRemoteProvider = Provider<FeedRemoteDataSource>((ref) {
  return FeedRemoteDataSource(ref.watch(dioProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(ref.watch(feedRemoteProvider));
});

class FeedNotifier extends AsyncNotifier<List<PostEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  @override
  Future<List<PostEntity>> build() async {
    _page = 1;
    _end = false;
    return ref.read(feedRepositoryProvider).fetchFeed(page: _page);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      return ref.read(feedRepositoryProvider).fetchFeed(page: 1);
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final more =
          await ref.read(feedRepositoryProvider).fetchFeed(page: nextPage);
      if (more.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      state = AsyncValue.data([...cur, ...more]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _loadingMore = false;
    }
  }
}

final feedNotifierProvider =
    AsyncNotifierProvider<FeedNotifier, List<PostEntity>>(FeedNotifier.new);
