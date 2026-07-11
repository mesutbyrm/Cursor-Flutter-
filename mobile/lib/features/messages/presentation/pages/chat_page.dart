import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../data/services/dm_message_sound_service.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import '../services/dm_voice_call_service.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_composer_bar.dart';
import '../widgets/chat_message_actions.dart';
import '../widgets/chat_messages_list_pane.dart';
import '../widgets/chat_reply_preview_bar.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  var _peerTyping = false;
  Timer? _poll;
  Timer? _typingPoll;
  DateTime? _lastTypedAt;
  MessageEntity? _replyTarget;
  MessageEntity? _forwardTarget;
  String? _peerName;
  String? _peerAvatar;
  var _peerOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _text.addListener(_onTextChanged);
    _typingPoll = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      if (!mounted) return;
      final recentlyTyped = _lastTypedAt != null &&
          DateTime.now().difference(_lastTypedAt!) < const Duration(seconds: 4);
      final peer = await ref
          .read(messagesRepositoryProvider)
          .pingTyping(widget.conversationId, selfTyping: recentlyTyped);
      if (mounted && peer != _peerTyping) setState(() => _peerTyping = peer);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPeerMeta();
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
          .refresh(silent: true, forceRefresh: false);
      unawaited(
        ref
            .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
            .refresh(silent: true, forceRefresh: true),
      );
      ref.invalidate(conversationsProvider);
      unawaited(
        ref.read(conversationsListNotifierProvider.notifier).refresh(
              silent: true,
              forceRefresh: true,
            ),
      );
    });
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
          .refresh(silent: true, forceRefresh: true);
    });
  }

  void _loadPeerMeta() {
    final list = ref.read(conversationsListNotifierProvider).valueOrNull;
    final peer = list?.all
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    if (peer != null) {
      setState(() {
        _peerName = peer.title;
        _peerAvatar = peer.avatarUrl;
        _peerOnline = peer.isOnline;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _typingPoll?.cancel();
    _scroll.removeListener(_onScroll);
    _text.removeListener(_onTextChanged);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_text.text.trim().isNotEmpty) _lastTypedAt = DateTime.now();
  }

  @override
  void didChangeMetrics() => _scrollToEnd();

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels <= 80) {
      ref
          .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
          .loadOlder();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    });
  }

  void _onIncomingMessage(MessageEntity message) {
    final raw = message.rawText ?? message.text;
    if (DmMessageCodec.isSystemPayload(raw)) {
      ref.read(dmVoiceCallServiceProvider).handleRawMessage(
            peerUserId: widget.conversationId,
            peerName: _peerName ?? 'Kullanıcı',
            peerAvatarUrl: _peerAvatar,
            rawContent: raw,
          );
      return;
    }
    unawaited(DmMessageSoundService.instance.playIncoming());
  }

  Future<void> _sendMessage(String text) async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final reply = _replyTarget;
    final forward = _forwardTarget;
    await ref
        .read(chatMessagesListNotifierProvider(widget.conversationId).notifier)
        .sendMessage(
          text: text,
          currentUserId: userId,
          replyId: reply?.id,
          replyText: reply?.text,
          forward: forward != null,
          forwardFrom: forward != null
              ? (forward.isMine ? 'Siz' : (_peerName ?? 'Kullanıcı'))
              : null,
        );
    _text.clear();
    setState(() {
      _replyTarget = null;
      _forwardTarget = null;
    });
    await DmMessageSoundService.instance.playOutgoing();
    ref.invalidate(conversationsProvider);
    _scrollToEnd();
  }

  Future<void> _startVoiceCall() async {
    final tier = ref.read(vipTierProvider);
    if (tier.index < VipTier.gold.index) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesli arama Gold üyelere özeldir.'),
        ),
      );
      context.push('/vip-gold');
      return;
    }
    await ref.read(dmVoiceCallServiceProvider).startOutgoingCall(
          peerUserId: widget.conversationId,
          peerName: _peerName ?? 'Kullanıcı',
          peerAvatarUrl: _peerAvatar,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesli arama isteği gönderildi')),
    );
  }

  Future<void> _handleComposerAction(DmComposerAction action) async {
    switch (action) {
      case DmComposerAction.gift:
        return _sendMessage('🎁 Hediye göndermek istiyor.');
      case DmComposerAction.jeton:
        return _sendMessage('🪙 Jeton göndermek istiyor.');
      case DmComposerAction.fortune:
        return _sendMessage('🔮 Fal isteği gönderdi.');
      case DmComposerAction.voiceFortune:
        return _sendMessage('🎙️ Sesli fal isteği gönderdi.');
      case DmComposerAction.videoFortune:
        return _sendMessage('📹 Görüntülü fal isteği gönderdi.');
      case DmComposerAction.liveInvite:
        return _sendMessage('📡 Canlı yayına davet etti.');
      case DmComposerAction.voiceRoomInvite:
        return _sendMessage('🎧 Sesli odaya davet etti.');
      case DmComposerAction.photo:
        return _sendMessage('📷 Fotoğraf göndermek istiyor.');
      case DmComposerAction.video:
        return _sendMessage('🎬 Video göndermek istiyor.');
      case DmComposerAction.file:
        return _sendMessage('📎 Dosya göndermek istiyor.');
      case DmComposerAction.location:
        return _sendMessage('📍 Konum paylaşmak istiyor.');
      case DmComposerAction.gif:
        return _sendMessage('🖼️ GIF gönderdi.');
      case DmComposerAction.sticker:
        return _sendMessage('✨ Sticker gönderdi.');
    }
  }

  Future<void> _showPeerActions() async {
    final name = _peerName ?? 'Kullanıcı';
    await showConversationPeerActions(
      context: context,
      peerName: name,
      onDeleteChat: () async {
        final uid = ref.read(authControllerProvider).valueOrNull?.id;
        await ref.read(messagesRepositoryProvider).hideConversation(
              widget.conversationId,
              currentUserId: uid,
            );
        ref.invalidate(conversationsProvider);
        if (mounted) Navigator.pop(context);
      },
      onBlock: () async {
        try {
          await ref
              .read(messagesRepositoryProvider)
              .blockUser(widget.conversationId);
          final uid = ref.read(authControllerProvider).valueOrNull?.id;
          await ref.read(messagesRepositoryProvider).hideConversation(
                widget.conversationId,
                currentUserId: uid,
              );
          ref.invalidate(conversationsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name engellendi')),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
        }
      },
    );
  }

  Future<void> _pickForwardTarget(MessageEntity message) async {
    final conversations =
        ref.read(conversationsListNotifierProvider).valueOrNull?.all ??
            const [];
    if (!mounted) return;
    final targetId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('İletilecek sohbet',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white70),
              title: const Text('Kendime kaydet',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx, ref.read(authControllerProvider).valueOrNull?.id),
            ),
            ...conversations.map(
              (c) => ListTile(
                leading: UserAvatar(url: c.avatarUrl, radius: 18),
                title: Text(c.title, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, c.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (targetId == null || targetId.isEmpty) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    await ref.read(messagesRepositoryProvider).sendMessage(
          targetId,
          message.text,
          currentUserId: userId,
          forward: true,
          forwardFrom: message.isMine ? 'Siz' : (_peerName ?? 'Kullanıcı'),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj iletildi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final peerLabel = _peerName ?? 'Sohbet';
    final statusLabel = _peerTyping
        ? 'Yazıyor...'
        : (_peerOnline ? 'Çevrimiçi' : 'Son görülme yakın zamanda');
    final isGold = ref.watch(vipTierProvider).index >= VipTier.gold.index;

    ref.listen(conversationsListNotifierProvider, (_, __) => _loadPeerMeta());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            ProGlassTopBar(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Row(
                  children: [
                    DiscoverIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onLongPress: _showPeerActions,
                          child: UserAvatar(url: _peerAvatar, radius: 20),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _peerOnline
                                  ? const Color(0xFF22C55E)
                                  : Colors.grey.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF09090B),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onLongPress: _showPeerActions,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              peerLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _peerTyping
                                    ? AppThemeColors.accentPink
                                    : Colors.white.withValues(alpha: 0.62),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isGold)
                      DiscoverIconButton(
                        icon: Icons.call_rounded,
                        tooltip: 'Sesli ara',
                        onPressed: _startVoiceCall,
                      ),
                    DiscoverIconButton(
                      icon: Icons.videocam_rounded,
                      tooltip: 'Görüntülü arama',
                      onPressed: () =>
                          _handleComposerAction(DmComposerAction.videoFortune),
                    ),
                    DiscoverIconButton(
                      icon: Icons.more_horiz_rounded,
                      tooltip: 'Sohbet işlemleri',
                      onPressed: _showPeerActions,
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
                onReply: (m) => setState(() {
                  _replyTarget = m;
                  _forwardTarget = null;
                }),
                onForward: _pickForwardTarget,
                onQuickReply: (t) => _sendMessage(t),
                onIncomingMessage: _onIncomingMessage,
              ),
            ),
            if (_peerTyping) ChatTypingIndicator(label: peerLabel),
            if (_replyTarget != null)
              ChatReplyPreviewBar(
                message: _replyTarget!,
                onClear: () => setState(() => _replyTarget = null),
              ),
            ChatComposerBar(
              controller: _text,
              onSend: _sendMessage,
              onAction: _handleComposerAction,
            ),
          ],
        ),
      ),
    );
  }
}
