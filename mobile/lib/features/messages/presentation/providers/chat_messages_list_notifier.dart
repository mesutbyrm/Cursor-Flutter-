import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../../domain/utils/dm_message_dedupe.dart';
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
    final remote = await ref.read(messagesRepositoryProvider).messages(
          conversationId,
          currentUserId: userId,
          forceRefresh: forceRefresh,
        );
    final optimistic = previous?.all
            .where((m) => m.id.startsWith('local-'))
            .toList() ??
        const <MessageEntity>[];
    final all = DmMessageDedupe.merge(
      remote: remote,
      localOptimistic: optimistic,
    );
    var visible = all.length;
    if (previous != null && all.length > previous.all.length) {
      visible = all.length;
    }
    return ChatMessagesListState(all: all, visibleCount: visible);
  }

  Future<void> refresh({
    bool silent = false,
    bool forceRefresh = true,
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

  Future<void> deleteMessage(String messageId) async {
    if (messageId.isEmpty) return;
    final cur = state.valueOrNull;
    if (cur != null) {
      state = AsyncValue.data(
        cur.copyWith(
          all: cur.all.where((m) => m.id != messageId).toList(),
        ),
      );
    }
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    try {
      await ref.read(messagesRepositoryProvider).deleteMessage(
            arg,
            messageId,
            currentUserId: userId,
          );
    } catch (_) {}
  }

  Future<void> sendMessage({
    required String text,
    String? currentUserId,
    String? replyId,
    String? replyText,
    bool forward = false,
    String? forwardFrom,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final optimisticId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final cur = state.valueOrNull;
    final optimistic = MessageEntity(
      id: optimisticId,
      text: trimmed,
      isMine: true,
      createdAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
      replyTo: replyId != null && replyText != null
          ? DmReplyMeta(id: replyId, text: replyText)
          : null,
      forwardedFrom: forward ? (forwardFrom ?? 'İletilen mesaj') : null,
    );
    if (cur != null) {
      state = AsyncValue.data(
        cur.copyWith(
          all: [...cur.all, optimistic],
          visibleCount: cur.visibleCount + 1,
        ),
      );
    }
    try {
      await ref.read(messagesRepositoryProvider).sendMessage(
            arg,
            trimmed,
            currentUserId: currentUserId,
            replyId: replyId,
            replyText: replyText,
            forward: forward,
            forwardFrom: forwardFrom,
          );
      await refresh(silent: true, forceRefresh: true);
    } catch (e, st) {
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncValue.data(
          latest.copyWith(
            all: latest.all.where((m) => m.id != optimisticId).toList(),
          ),
        );
      }
      Error.throwWithStackTrace(e, st);
    }
  }
}

final chatMessagesListNotifierProvider = AsyncNotifierProvider.family<
    ChatMessagesListNotifier, ChatMessagesListState, String>(
  ChatMessagesListNotifier.new,
);
