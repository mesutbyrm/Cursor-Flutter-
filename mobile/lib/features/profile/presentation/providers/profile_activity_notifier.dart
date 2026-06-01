import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile_stats_entity.dart';
import 'profile_providers.dart';

class ProfileActivityNotifier extends AsyncNotifier<List<ProfileActivityItemEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  @override
  Future<List<ProfileActivityItemEntity>> build() async {
    _page = 1;
    _end = false;
    final bundle =
        await ref.read(profileRepositoryProvider).myActivityPage(page: 1);
    _end = !bundle.hasMore;
    return bundle.items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final bundle =
          await ref.read(profileRepositoryProvider).myActivityPage(page: 1);
      _end = !bundle.hasMore;
      return bundle.items;
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final bundle = await ref
          .read(profileRepositoryProvider)
          .myActivityPage(page: nextPage);
      if (bundle.items.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      _end = !bundle.hasMore;
      state = AsyncValue.data([...cur, ...bundle.items]);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => !_end;
}

final profileActivityNotifierProvider =
    AsyncNotifierProvider<ProfileActivityNotifier, List<ProfileActivityItemEntity>>(
  ProfileActivityNotifier.new,
);
