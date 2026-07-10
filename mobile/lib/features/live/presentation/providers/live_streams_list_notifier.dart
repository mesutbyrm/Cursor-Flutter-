import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_entity.dart';
import '../../domain/utils/live_discover_category.dart';
import '../../domain/utils/live_discover_ranker.dart';
import 'live_fortune_request_provider.dart';
import 'live_providers.dart';

class LiveStreamsListNotifier extends AsyncNotifier<List<LiveStreamEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  static const int _pageSize = 30;

  @override
  Future<List<LiveStreamEntity>> build() async {
    ref.listen(liveDiscoverCategoryProvider, (_, _) {
      unawaited(refresh());
    });
    _page = 1;
    _end = false;
    return _loadPage(1);
  }

  Future<List<LiveStreamEntity>> _loadPage(int page) async {
    final filter = ref.read(liveDiscoverCategoryProvider);
    final items = await ref.read(liveRepositoryProvider).fetchStreams(
          page: page,
          category: filter.apiCategory,
        );
    _end = items.length < _pageSize;
    return rankLiveStreamsForDiscover(
      streams: items,
      filter: filter,
      userAffinity: filter.isFortuneFamily ? filter : null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      return _loadPage(1);
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final next = await _loadPage(nextPage);
      if (next.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      // Canlı liste sayfa çekimleri arasında değiştiği için aynı yayın iki
      // sayfada gelebilir; id'ye göre yineleri ele ki liste tekrarlı kart
      // göstermesin.
      final seen = {for (final s in cur) s.id};
      final merged = [
        ...cur,
        for (final s in next)
          if (s.id.isEmpty || seen.add(s.id)) s,
      ];
      state = AsyncValue.data(merged);
    } finally {
      _loadingMore = false;
    }
  }

  bool get hasMore => !_end;
}

final liveStreamsListNotifierProvider =
    AsyncNotifierProvider<LiveStreamsListNotifier, List<LiveStreamEntity>>(
  LiveStreamsListNotifier.new,
);
