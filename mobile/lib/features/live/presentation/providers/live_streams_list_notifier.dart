import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_stream_entity.dart';
import 'live_providers.dart';

class LiveStreamsListNotifier extends AsyncNotifier<List<LiveStreamEntity>> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  static const int _pageSize = 30;

  @override
  Future<List<LiveStreamEntity>> build() async {
    _page = 1;
    _end = false;
    final items =
        await ref.read(liveRepositoryProvider).fetchStreams(page: 1);
    _end = items.length < _pageSize;
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidate(liveStreamsProvider);
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final items =
          await ref.read(liveRepositoryProvider).fetchStreams(page: 1);
      _end = items.length < _pageSize;
      return items;
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    final nextPage = _page + 1;
    try {
      final next =
          await ref.read(liveRepositoryProvider).fetchStreams(page: nextPage);
      if (next.isEmpty) {
        _end = true;
        return;
      }
      _page = nextPage;
      _end = next.length < _pageSize;
      state = AsyncValue.data([...cur, ...next]);
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
