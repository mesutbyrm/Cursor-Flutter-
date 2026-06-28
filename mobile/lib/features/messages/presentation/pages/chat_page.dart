import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/list_perf.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../providers/messages_providers.dart';
import '../widgets/chat_composer_bar.dart';
import '../widgets/chat_messages_list_pane.dart';
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
  var _peerTyping = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
          .refresh(silent: true, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _scroll.removeListener(_onScroll);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels <= ListPerf.preloadThresholdPx) {
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
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

  Future<void> _sendMessage(String text) async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    await ref.read(messagesRepositoryProvider).sendMessage(
          widget.conversationId,
          text,
          currentUserId: userId,
        );
    _text.clear();
    await ref
        .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
        .refresh(forceRefresh: true);
    ref.invalidate(conversationsProvider);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
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
              child: ChatMessagesListPane(
                conversationId: widget.conversationId,
                scrollController: _scroll,
                onScrollToEnd: _scrollToEnd,
              ),
            ),
            if (_peerTyping) const ChatTypingIndicator(),
            ChatComposerBar(
              controller: _text,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
