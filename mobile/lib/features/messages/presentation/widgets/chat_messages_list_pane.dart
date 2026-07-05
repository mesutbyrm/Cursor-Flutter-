import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/scroll_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/entities/message_entities.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../widgets/chat_message_bubble.dart';

/// Sohbet mesaj listesi — cache-first; yalnızca mesaj state'ini izler.
class ChatMessagesListPane extends ConsumerStatefulWidget {
  const ChatMessagesListPane({
    super.key,
    required this.conversationId,
    required this.scrollController,
    required this.onScrollToEnd,
    this.onReply,
    this.onForward,
    this.onQuickReply,
    this.onIncomingMessage,
  });

  final String conversationId;
  final ScrollController scrollController;
  final VoidCallback onScrollToEnd;
  final ValueChanged<MessageEntity>? onReply;
  final ValueChanged<MessageEntity>? onForward;
  final ValueChanged<String>? onQuickReply;
  final ValueChanged<MessageEntity>? onIncomingMessage;

  @override
  ConsumerState<ChatMessagesListPane> createState() =>
      _ChatMessagesListPaneState();
}

class _ChatMessagesListPaneState extends ConsumerState<ChatMessagesListPane> {
  ProviderSubscription<AsyncValue<ChatMessagesListState>>? _msgSub;
  final Set<String> _notifiedIds = {};

  @override
  void initState() {
    super.initState();
    _msgSub = ref.listenManual(
      chatMessagesListNotifierProvider(widget.conversationId),
      (previous, next) {
        next.whenData((state) {
          widget.onScrollToEnd();
          _notifyIncoming(previous?.valueOrNull, state);
        });
      },
    );
  }

  void _notifyIncoming(ChatMessagesListState? prev, ChatMessagesListState next) {
    final handler = widget.onIncomingMessage;
    if (handler == null) return;
    final prevIds = prev?.all.map((m) => m.id).toSet() ?? {};
    for (final m in next.all) {
      if (!m.isMine && !_notifiedIds.contains(m.id) && !prevIds.contains(m.id)) {
        _notifiedIds.add(m.id);
        handler(m);
      }
    }
  }

  @override
  void dispose() {
    _msgSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(
      chatMessagesListNotifierProvider(widget.conversationId).select(
        (async) => async.when(
          data: (state) => (
            rows: state.visible,
            hasMore: state.hasMore,
            olderHidden: state.olderHiddenCount,
            isEmpty: state.all.isEmpty,
          ),
          loading: () => null,
          error: (_, _) => null,
        ),
      ),
    );

    final loading = ref.watch(
      chatMessagesListNotifierProvider(widget.conversationId).select(
        (async) => async.isLoading && async.valueOrNull == null,
      ),
    );
    final error = ref.watch(
      chatMessagesListNotifierProvider(widget.conversationId).select(
        (async) => async.hasError ? async.error : null,
      ),
    );

    if (loading && msgs == null) {
      return const DiscoverAccentLoader();
    }
    if (error != null && msgs == null) {
      return DiscoverEmptyState(
        icon: Icons.chat_bubble_outline,
        message: error.toString(),
      );
    }
    if (msgs == null) {
      return const DiscoverAccentLoader();
    }
    if (msgs.isEmpty) {
      return const DiscoverEmptyState(
        icon: Icons.waving_hand_rounded,
        message: 'Mesaj yok — ilk mesajı gönder.',
      );
    }

    final lastIncomingIndex = msgs.rows.lastIndexWhere((m) => !m.isMine);

    return ListView.builder(
      cacheExtent: ScrollPerf.chatCacheExtent,
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      physics: ScrollPerf.feedPhysics,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemCount: msgs.rows.length + (msgs.hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (msgs.hasMore && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () => ref
                    .read(
                      chatMessagesListNotifierProvider(widget.conversationId)
                          .notifier,
                    )
                    .loadOlder(),
                icon: const Icon(Icons.expand_less_rounded),
                label: Text(
                  msgs.olderHidden > 0
                      ? '${msgs.olderHidden} eski mesaj'
                      : 'Daha fazla yükle',
                ),
              ),
            ),
          );
        }
        final idx = msgs.hasMore ? i - 1 : i;
        final row = msgs.rows[idx];
        return ScrollPerf.item(
          ChatMessageBubble(
            message: row,
            onDelete: row.isMine
                ? () => ref
                    .read(
                      chatMessagesListNotifierProvider(widget.conversationId)
                          .notifier,
                    )
                    .deleteMessage(row.id)
                : null,
            onReply: widget.onReply == null
                ? null
                : () => widget.onReply!(row),
            onForward: widget.onForward == null
                ? null
                : () => widget.onForward!(row),
            showQuickReplies:
                !row.isMine && idx == lastIncomingIndex && widget.onQuickReply != null,
            onQuickReply: widget.onQuickReply,
          ),
        );
      },
    );
  }
}
