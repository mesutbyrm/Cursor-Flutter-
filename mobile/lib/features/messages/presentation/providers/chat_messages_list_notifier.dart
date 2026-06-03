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
    final userId = ref.watch(authControllerProvider).valueOrNull?.id;
    final all = await ref.read(messagesRepositoryProvider).messages(
          conversationId,
          currentUserId: userId,
        );
    final visible = ListPerf.defaultPageSize.clamp(0, all.length);
    return ChatMessagesListState(all: all, visibleCount: visible);
  }

  Future<void> refresh() async {
    final id = arg;
    final prev = state.valueOrNull;
    state = const AsyncLoading<ChatMessagesListState>().copyWithPrevious(state);
    ref.invalidate(chatMessagesProvider(id));
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authControllerProvider).valueOrNull?.id;
      final all = await ref.read(messagesRepositoryProvider).messages(
            id,
            currentUserId: userId,
          );
      var visible = ListPerf.defaultPageSize.clamp(0, all.length);
      if (prev != null && all.length > prev.all.length) {
        visible = (prev.visibleCount + (all.length - prev.all.length))
            .clamp(visible, all.length);
      } else if (prev != null) {
        visible = prev.visibleCount.clamp(visible, all.length);
      }
      return ChatMessagesListState(all: all, visibleCount: visible);
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
