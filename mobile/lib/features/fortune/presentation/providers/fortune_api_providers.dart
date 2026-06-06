import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/fortune_remote_datasource.dart';
import '../../data/repositories/fortune_repository_impl.dart';
import '../../domain/entities/user_fortune_entity.dart';
import '../../domain/repositories/fortune_repository.dart';

final fortuneRemoteProvider = Provider<FortuneRemoteDataSource>((ref) {
  return FortuneRemoteDataSource(ref.watch(dioProvider));
});

final fortuneRepositoryProvider = Provider<FortuneRepository>((ref) {
  return FortuneRepositoryImpl(ref.watch(fortuneRemoteProvider));
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
    final page =
        await ref.read(fortuneRepositoryProvider).history(page: 1, limit: _limit);
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
          .read(fortuneRepositoryProvider)
          .history(page: next, limit: _limit);
      _page = next;
      _hasMore = page.hasMore;
      state = AsyncData([...state.valueOrNull ?? [], ...page.items]);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final fortuneDetailProvider =
    FutureProvider.family<UserFortuneEntity, String>((ref, id) async {
  return ref.read(fortuneRepositoryProvider).detail(id);
});
