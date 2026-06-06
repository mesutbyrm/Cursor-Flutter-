import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../domain/entities/message_entities.dart';
import 'messages_providers.dart';

class ConversationsListState {
  const ConversationsListState({
    required this.all,
    this.visibleCount = ListPerf.defaultPageSize,
    this.loadingMore = false,
  });

  final List<ConversationEntity> all;
  final int visibleCount;
  final bool loadingMore;

  bool get hasMore => visibleCount < all.length;

  List<ConversationEntity> get visible =>
      all.take(visibleCount.clamp(0, all.length)).toList();

  ConversationsListState copyWith({
    List<ConversationEntity>? all,
    int? visibleCount,
    bool? loadingMore,
  }) {
    return ConversationsListState(
      all: all ?? this.all,
      visibleCount: visibleCount ?? this.visibleCount,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class ConversationsListNotifier extends AsyncNotifier<ConversationsListState> {
  @override
  Future<ConversationsListState> build() async {
    final all = await ref.read(messagesRepositoryProvider).conversations();
    final visible = ListPerf.defaultPageSize.clamp(0, all.length);
    return ConversationsListState(all: all, visibleCount: visible);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<ConversationsListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final all = await ref.read(messagesRepositoryProvider).conversations();
      final visible = ListPerf.defaultPageSize.clamp(0, all.length);
      return ConversationsListState(all: all, visibleCount: visible);
    });
  }

  void loadMore() {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.loadingMore) return;
    state = AsyncValue.data(
      cur.copyWith(
        visibleCount: (cur.visibleCount + ListPerf.defaultPageSize)
            .clamp(0, cur.all.length),
      ),
    );
  }
}

final conversationsListNotifierProvider =
    AsyncNotifierProvider<ConversationsListNotifier, ConversationsListState>(
  ConversationsListNotifier.new,
);

/// Okunmamış toplam — tam liste üzerinden (lazy görünümden bağımsız).
final conversationsUnreadTotalProvider = Provider<int>((ref) {
  return ref.watch(conversationsListNotifierProvider).maybeWhen(
        data: (s) => s.all.fold<int>(0, (sum, c) => sum + c.unreadCount),
        orElse: () => ref.watch(messagesUnreadCountProvider),
      );
});
