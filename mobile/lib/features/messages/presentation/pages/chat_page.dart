import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  var _sending = false;
  var _peerTyping = false;
  Timer? _typingHideTimer;
  Timer? _typingEmitTimer;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId)
              .notifier)
          .refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.removeListener(_onScroll);
    _typingHideTimer?.cancel();
    _typingEmitTimer?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels <= ListPerf.preloadThresholdPx) {
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId)
              .notifier)
          .loadOlder();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      await _scroll.animateTo(
        max,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onComposerChanged(String value) {
    _typingEmitTimer?.cancel();
    if (value.trim().isEmpty) return;
    _typingEmitTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _peerTyping = true);
      _typingHideTimer?.cancel();
      _typingHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _peerTyping = false);
      });
    });
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(messagesRepositoryProvider)
          .sendMessage(widget.conversationId, t);
      _text.clear();
      await ref
          .read(chatMessagesListNotifierProvider(widget.conversationId)
              .notifier)
          .refresh();
      ref.invalidate(conversationsProvider);
      _scrollToEnd();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs =
        ref.watch(chatMessagesListNotifierProvider(widget.conversationId));

    ref.listen(chatMessagesListNotifierProvider(widget.conversationId),
        (_, next) {
      next.whenData((_) => _scrollToEnd());
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            ProGlassTopBar(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 12),
                child: Row(
                  children: [
                    DiscoverIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: DiscoverTabHeader(
                        title: 'Sohbet',
                        subtitle: 'Çevrimiçi',
                        actions: [
                          DiscoverIconButton(
                            icon: Icons.flag_outlined,
                            tooltip: 'Sohbeti bildir',
                            onPressed: () => openReportFlow(
                              context,
                              ReportTarget(
                                type: ReportTargetType.conversation,
                                targetId: widget.conversationId,
                                displayTitle: 'Sohbet',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: msgs.when(
                loading: () => const DiscoverAccentLoader(),
                error: (e, _) => DiscoverEmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: e.toString(),
                ),
                data: (state) {
                  if (state.all.isEmpty) {
                    return const DiscoverEmptyState(
                      icon: Icons.waving_hand_rounded,
                      message: 'Mesaj yok — ilk mesajı gönder.',
                    );
                  }
                  final rows = state.visible;
                  final showOlder = state.hasMore;
                  return ListView.builder(
                    controller: _scroll,
                    cacheExtent: 400,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    physics: ListPerf.listPhysics,
                    cacheExtent: ListPerf.cacheExtent,
                    itemCount: rows.length + (showOlder ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (showOlder && i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => ref
                                  .read(
                                    chatMessagesListNotifierProvider(
                                      widget.conversationId,
                                    ).notifier,
                                  )
                                  .loadOlder(),
                              icon: const Icon(Icons.expand_less_rounded),
                              label: Text(
                                state.olderHiddenCount > 0
                                    ? '${state.olderHiddenCount} eski mesaj'
                                    : 'Daha fazla yükle',
                              ),
                            ),
                          ),
                        );
                      }
                      final idx = showOlder ? i - 1 : i;
                      return ListPerf.repaint(
                        ChatMessageBubble(message: rows[idx]),
                      );
                    },
                  );
                },
              ),
            ),
            if (_peerTyping) const ChatTypingIndicator(),
            ChatComposer(
              controller: _text,
              sending: _sending,
              onSend: _send,
              onChanged: _onComposerChanged,
            ),
          ],
        ),
      ),
    );
  }
}
