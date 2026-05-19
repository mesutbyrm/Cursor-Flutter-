import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/messages_providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
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
      backgroundColor: AppDesign.bgBase,
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
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Sohbet',
                      subtitle: 'Mesajlaşma',
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
                      final m = rows[i];
                      return Align(
                        alignment: m.isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: m.isMine
                                ? AppDesign.heroGradient
                                : null,
                            color: m.isMine
                                ? null
                                : const Color(0xFF16162A)
                                    .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(m.isMine ? 16 : 4),
                              bottomRight: Radius.circular(m.isMine ? 4 : 16),
                            ),
                            border: m.isMine
                                ? null
                                : Border.all(
                                    color: AppDesign.accentPurple
                                        .withValues(alpha: 0.25),
                                  ),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: m.isMine
                                  ? Colors.white
                                  : AppDesign.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(color: AppDesign.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Mesaj yaz...',
                          hintStyle: TextStyle(
                            color: AppDesign.textMuted.withValues(alpha: 0.8),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppDesign.accentPurple
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: AppDesign.accentPurple
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppDesign.accentPink,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sending ? null : _send,
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: AppDesign.heroGradient,
                          ),
                          child: Center(
                            child: _sending
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
