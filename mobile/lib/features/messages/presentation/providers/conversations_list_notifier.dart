import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
    final userId = ref.watch(authControllerProvider).valueOrNull?.id;
    return _load(userId: userId);
  }

  Future<ConversationsListState> _load({
    required String? userId,
    bool forceRefresh = false,
    ConversationsListState? previous,
  }) async {
    final all = await ref.read(messagesRepositoryProvider).conversations(
          forceRefresh: forceRefresh,
          cacheUserId: userId,
        );
    final defaultVisible = ListPerf.defaultPageSize.clamp(0, all.length);
    final visible = previous?.visibleCount.clamp(defaultVisible, all.length) ??
        defaultVisible;
    return ConversationsListState(all: all, visibleCount: visible);
  }

  Future<void> refresh({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      state = const AsyncLoading<ConversationsListState>().copyWithPrevious(state);
    }
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final previous = state.valueOrNull;
    state = await AsyncValue.guard(() async {
      return _load(
        userId: userId,
        forceRefresh: forceRefresh,
        previous: previous,
      );
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
