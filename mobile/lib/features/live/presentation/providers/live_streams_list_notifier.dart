import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../domain/entities/live_stream_entity.dart';
import 'live_providers.dart';

class LiveStreamsListState {
  const LiveStreamsListState({
    required this.all,
    this.visibleCount = ListPerf.defaultPageSize,
  });

  final List<LiveStreamEntity> all;
  final int visibleCount;

  bool get hasMore => visibleCount < all.length;

  List<LiveStreamEntity> get visible =>
      all.take(visibleCount.clamp(0, all.length)).toList();

  LiveStreamsListState copyWith({
    List<LiveStreamEntity>? all,
    int? visibleCount,
  }) {
    return LiveStreamsListState(
      all: all ?? this.all,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }
}

class LiveStreamsListNotifier extends AsyncNotifier<LiveStreamsListState> {
  @override
  Future<LiveStreamsListState> build() async {
    final all = await ref.watch(liveStreamsProvider.future);
    final visible = ListPerf.defaultPageSize.clamp(0, all.length);
    return LiveStreamsListState(all: all, visibleCount: visible);
  }

  Future<void> refresh() async {
    state =
        const AsyncLoading<LiveStreamsListState>().copyWithPrevious(state);
    ref.invalidate(liveStreamsProvider);
    state = await AsyncValue.guard(() async {
      final all = await ref.read(liveStreamsProvider.future);
      final visible = ListPerf.defaultPageSize.clamp(0, all.length);
      return LiveStreamsListState(all: all, visibleCount: visible);
    });
  }

  void loadMore() {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore) return;
    state = AsyncValue.data(
      cur.copyWith(
        visibleCount: (cur.visibleCount + ListPerf.defaultPageSize)
            .clamp(0, cur.all.length),
      ),
    );
  }
}

final liveStreamsListNotifierProvider =
    AsyncNotifierProvider<LiveStreamsListNotifier, LiveStreamsListState>(
  LiveStreamsListNotifier.new,
);
