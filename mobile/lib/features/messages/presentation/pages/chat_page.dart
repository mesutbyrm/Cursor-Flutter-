import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
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
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      ref.invalidate(chatMessagesProvider(widget.conversationId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _typingHideTimer?.cancel();
    _typingEmitTimer?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
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
      ref.invalidate(chatMessagesProvider(widget.conversationId));
      ref.invalidate(conversationsProvider);
      _scrollToEnd();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(chatMessagesProvider(widget.conversationId));

    ref.listen(chatMessagesProvider(widget.conversationId), (_, next) {
      next.whenData((_) => _scrollToEnd());
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
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
            Expanded(
              child: msgs.when(
                loading: () => const DiscoverAccentLoader(),
                error: (e, _) => DiscoverEmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: e.toString(),
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const DiscoverEmptyState(
                      icon: Icons.waving_hand_rounded,
                      message: 'Mesaj yok — ilk mesajı gönder.',
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    itemCount: rows.length,
                    itemBuilder: (ctx, i) {
                      return ChatMessageBubble(message: rows[i]);
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
