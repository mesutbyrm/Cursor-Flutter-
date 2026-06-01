import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/favorites_remote_datasource.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../domain/entities/user_fortune_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRemoteProvider = Provider<FavoritesRemoteDataSource>((ref) {
  return FavoritesRemoteDataSource(ref.watch(dioProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(favoritesRemoteProvider));
});

final fortuneHistoryProvider =
    AsyncNotifierProvider<FortuneHistoryNotifier, List<UserFortuneEntity>>(
  FortuneHistoryNotifier.new,
);

class FortuneHistoryNotifier extends AsyncNotifier<List<UserFortuneEntity>> {
  var _page = 1;
  var _hasMore = true;
  var _loadingMore = false;

  static const _limit = 20;

  @override
  Future<List<UserFortuneEntity>> build() async {
    _page = 1;
    _hasMore = true;
    final page = await ref
        .read(favoritesRepositoryProvider)
        .fortuneHistory(page: 1, limit: _limit);
    _hasMore = page.hasMore;
    return page.items;
  }

  bool get canLoadMore => _hasMore && !_loadingMore;

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    _loadingMore = true;
    final next = _page + 1;
    try {
      final page = await ref
          .read(favoritesRepositoryProvider)
          .fortuneHistory(page: next, limit: _limit);
      _page = next;
      _hasMore = page.hasMore;
      final current = state.valueOrNull ?? [];
      state = AsyncData([...current, ...page.items]);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
