import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../widgets/chat_message_bubble.dart';

/// Sohbet mesaj listesi — yalnızca mesaj state'ini izler.
class ChatMessagesListPane extends ConsumerStatefulWidget {
  const ChatMessagesListPane({
    super.key,
    required this.conversationId,
    required this.scrollController,
    required this.onScrollToEnd,
  });

  final String conversationId;
  final ScrollController scrollController;
  final VoidCallback onScrollToEnd;

  @override
  ConsumerState<ChatMessagesListPane> createState() =>
      _ChatMessagesListPaneState();
}

class _ChatMessagesListPaneState extends ConsumerState<ChatMessagesListPane> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(LazyLoadPerf.chatMessages, () {
      if (mounted) setState(() => _ready = true);
    });
    ref.listenManual(
      chatMessagesListNotifierProvider(widget.conversationId),
      (previous, next) {
        next.whenData((_) => widget.onScrollToEnd());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const DiscoverAccentLoader();
    }

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
        (async) => async.isLoading,
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

    return ListView.builder(
      cacheExtent: ListPerf.cacheExtent,
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      physics: ListPerf.listPhysics,
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
        return ListPerf.repaint(
          ChatMessageBubble(message: msgs.rows[idx]),
        );
      },
    );
  }
}
