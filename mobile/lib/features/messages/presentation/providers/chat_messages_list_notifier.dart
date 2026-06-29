import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import 'messages_providers.dart';

/// Sohbet: en yeni mesajlar önce gösterilir; yukarı kaydırınca eski mesajlar yüklenir.
class ChatMessagesListState {
  const ChatMessagesListState({
    required this.all,
    this.visibleCount = ListPerf.defaultPageSize,
  });

  final List<MessageEntity> all;
  final int visibleCount;

  bool get hasMore => visibleCount < all.length;

  List<MessageEntity> get visible {
    if (all.isEmpty) return const [];
    final start = (all.length - visibleCount).clamp(0, all.length);
    return all.sublist(start);
  }

  int get olderHiddenCount => all.length - visible.length;

  ChatMessagesListState copyWith({
    List<MessageEntity>? all,
    int? visibleCount,
  }) {
    return ChatMessagesListState(
      all: all ?? this.all,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }
}

class ChatMessagesListNotifier
    extends FamilyAsyncNotifier<ChatMessagesListState, String> {
  @override
  Future<ChatMessagesListState> build(String conversationId) async {
    return _load(conversationId);
  }

  Future<ChatMessagesListState> _load(
    String conversationId, {
    bool forceRefresh = false,
    ChatMessagesListState? previous,
  }) async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final all = await ref.read(messagesRepositoryProvider).messages(
          conversationId,
          currentUserId: userId,
          forceRefresh: forceRefresh,
        );
    var visible = ListPerf.defaultPageSize.clamp(0, all.length);
    if (previous != null && all.length > previous.all.length) {
      visible = (previous.visibleCount + (all.length - previous.all.length))
          .clamp(visible, all.length);
    } else if (previous != null) {
      visible = previous.visibleCount.clamp(visible, all.length);
    }
    return ChatMessagesListState(all: all, visibleCount: visible);
  }

  Future<void> refresh({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final id = arg;
    if (!silent) {
      state = const AsyncLoading<ChatMessagesListState>().copyWithPrevious(state);
    }
    final previous = state.valueOrNull;
    ref.invalidate(chatMessagesProvider(id));
    state = await AsyncValue.guard(() async {
      return _load(id, forceRefresh: forceRefresh, previous: previous);
    });
  }

  void loadOlder() {
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

final chatMessagesListNotifierProvider = AsyncNotifierProvider.family<
    ChatMessagesListNotifier, ChatMessagesListState, String>(
  ChatMessagesListNotifier.new,
);
