import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../providers/message_sse_provider.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/services/dm_message_sound_service.dart';
import '../../domain/utils/last_seen_format.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_providers.dart';
import '../services/dm_voice_call_service.dart';
import '../widgets/conversation_tile.dart' show PresenceRingAvatar;
import '../widgets/dm_realtime_listener.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_composer_bar.dart';
import '../widgets/chat_message_actions.dart';
import '../widgets/chat_messages_list_pane.dart';
import '../widgets/chat_reply_preview_bar.dart';
import '../widgets/chat_typing_indicator.dart';
import '../services/dm_voice_note_service.dart';

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
  DateTime? _peerLastSeen;
  var _dmSseActive = false;
  var _recordingVoiceNote = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    _text.addListener(_onTextChanged);
    _typingPoll = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
      if (!mounted) return;
      final recentlyTyped =
          _lastTypedAt != null &&
          DateTime.now().difference(_lastTypedAt!) < const Duration(seconds: 4);
      final peer = await ref
          .read(messagesRepositoryProvider)
          .pingTyping(widget.conversationId, selfTyping: recentlyTyped);
      if (mounted && peer != _peerTyping) setState(() => _peerTyping = peer);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(openDmConversationIdProvider.notifier).state =
          widget.conversationId;
      ref
          .read(conversationsListNotifierProvider.notifier)
          .markConversationReadLocally(widget.conversationId);
      _loadPeerMeta();
      ref
          .read(
            chatMessagesListNotifierProvider(widget.conversationId).notifier,
          )
          .refresh(silent: true, forceRefresh: false);
      unawaited(
        ref
            .read(
              chatMessagesListNotifierProvider(widget.conversationId).notifier,
            )
            .refresh(silent: true, forceRefresh: true),
      );
      ref.invalidate(conversationsProvider);
      unawaited(
        ref
            .read(conversationsListNotifierProvider.notifier)
            .refresh(silent: true, forceRefresh: true),
      );
      unawaited(_connectDmSse());
      _startMessagePoll();
    });
  }

  void _startMessagePoll() {
    _poll?.cancel();
    final interval = _dmSseActive
        ? const Duration(seconds: 8)
        : const Duration(seconds: 4);
    _poll = Timer.periodic(interval, (_) {
      if (!mounted) return;
      ref
          .read(
            chatMessagesListNotifierProvider(widget.conversationId).notifier,
          )
          .refresh(silent: true, forceRefresh: !_dmSseActive);
    });
  }

  Future<void> _connectDmSse() async {
    try {
      final storage = ref.read(tokenStorageProvider);
      final connected = await ref
          .read(messageSseServiceProvider)
          .connectToConversation(
            conversationId: widget.conversationId,
            accessToken: storage.readAccess,
            refreshTokens: () =>
                tryRefreshAccessToken(ref.read(dioProvider), storage),
            onEvent: (event) {
              if (!mounted) return;
              final uid = ref.read(authControllerProvider).valueOrNull?.id;
              ref
                  .read(
                    chatMessagesListNotifierProvider(
                      widget.conversationId,
                    ).notifier,
                  )
                  .ingestFromSse(event, currentUserId: uid);
            },
          );
      if (!mounted) return;
      _dmSseActive = connected;
      _startMessagePoll();
    } catch (_) {
      // Üretimde SSE yoksa poll yedek kalır.
    }
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
        _peerLastSeen = peer.lastSeenAt;
      });
    }
  }

  @override
  void dispose() {
    ref.read(openDmConversationIdProvider.notifier).state = null;
    unawaited(ref.read(messageSseServiceProvider).disconnect());
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
          .read(
            chatMessagesListNotifierProvider(widget.conversationId).notifier,
          )
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
      ref
          .read(dmVoiceCallServiceProvider)
          .handleRawMessage(
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
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final reply = _replyTarget;
    final forward = _forwardTarget;
    // Yazı hemen temizlenir: gönderim sürerken yazılan yeni metin silinmesin.
    _text.clear();
    setState(() {
      _replyTarget = null;
      _forwardTarget = null;
    });
    try {
      await ref
          .read(
            chatMessagesListNotifierProvider(widget.conversationId).notifier,
          )
          .sendMessage(
            text: trimmed,
            currentUserId: userId,
            replyId: reply?.id,
            replyText: reply?.text,
            forward: forward != null,
            forwardFrom: forward != null
                ? (forward.isMine ? 'Siz' : (_peerName ?? 'Kullanıcı'))
                : null,
          );
    } catch (e) {
      if (mounted) {
        // Başarısız gönderimde yazı geri gelir (yeni yazı yoksa).
        if (_text.text.isEmpty) {
          _text.text = trimmed;
          _text.selection = TextSelection.collapsed(offset: trimmed.length);
        }
        setState(() {
          _replyTarget ??= reply;
          _forwardTarget ??= forward;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
      }
      return;
    }
    await DmMessageSoundService.instance.playOutgoing();
    ref.invalidate(conversationsProvider);
    ref
        .read(conversationsListNotifierProvider.notifier)
        .markConversationReadLocally(widget.conversationId);
    _scrollToEnd();
  }

  Future<void> _handleComposerAction(DmComposerAction action) async {
    switch (action) {
      case DmComposerAction.gift:
        await _sendMessage('🎁 Hediye göndermek istiyor.');
        if (mounted) context.push('/user/${widget.conversationId}');
        return;
      case DmComposerAction.jeton:
        await _sendMessage(economyJetonSendIntentMessage(ref));
        if (mounted) context.push('/jeton-store');
        return;
      case DmComposerAction.fortune:
        await _sendMessage('🔮 Fal isteği gönderdi.');
        if (mounted) context.push('/fortune');
        return;
      case DmComposerAction.voiceFortune:
        await _sendMessage('🎙️ Sesli fal isteği gönderdi.');
        if (mounted) context.push('/canli-falcilar');
        return;
      case DmComposerAction.videoFortune:
        await _sendMessage('📹 Görüntülü fal isteği gönderdi.');
        if (mounted) context.push('/canli-falcilar');
        return;
      case DmComposerAction.liveInvite:
        await _sendMessage('📡 Canlı yayına davet etti.');
        if (mounted) context.push('/live');
        return;
      case DmComposerAction.voiceRoomInvite:
        await _sendMessage('🎧 Sesli odaya davet etti.');
        if (mounted) context.push('/voice-rooms');
        return;
    }
  }

  Future<void> _toggleVoiceNote() async {
    if (_recordingVoiceNote) return;
    try {
      final service = ref.read(dmVoiceNoteServiceProvider);
      final url = await service.recordAndUpload(
        onRecordingChanged: (rec) {
          if (mounted) setState(() => _recordingVoiceNote = rec);
        },
      );
      if (url == null || url.isEmpty) return;
      await service.sendVoiceNote(
        peerUserId: widget.conversationId,
        audioUrl: url,
      );
      await ref
          .read(
            chatMessagesListNotifierProvider(widget.conversationId).notifier,
          )
          .refresh(silent: true, forceRefresh: true);
      _scrollToEnd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _recordingVoiceNote = false);
    }
  }

  Future<void> _showPeerActions() async {
    final name = _peerName ?? 'Kullanıcı';
    await showConversationPeerActions(
      context: context,
      peerName: name,
      onDeleteChat: () async {
        final uid = ref.read(authControllerProvider).valueOrNull?.id;
        await ref
            .read(messagesRepositoryProvider)
            .hideConversation(widget.conversationId, currentUserId: uid);
        ref.invalidate(conversationsProvider);
        if (mounted) Navigator.pop(context);
      },
      onBlock: () async {
        try {
          await ref
              .read(messagesRepositoryProvider)
              .blockUser(widget.conversationId);
          final uid = ref.read(authControllerProvider).valueOrNull?.id;
          await ref
              .read(messagesRepositoryProvider)
              .hideConversation(widget.conversationId, currentUserId: uid);
          ref.invalidate(conversationsProvider);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$name engellendi')));
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
              title: Text(
                'İletilecek sohbet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white70),
              title: const Text(
                'Kendime kaydet',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(
                ctx,
                ref.read(authControllerProvider).valueOrNull?.id,
              ),
            ),
            ...conversations.map(
              (c) => ListTile(
                leading: UserAvatar(url: c.avatarUrl, radius: 18),
                title: Text(
                  c.title,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(ctx, c.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (targetId == null || targetId.isEmpty) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    await ref
        .read(messagesRepositoryProvider)
        .sendMessage(
          targetId,
          message.text,
          currentUserId: userId,
          forward: true,
          forwardFrom: message.isMine ? 'Siz' : (_peerName ?? 'Kullanıcı'),
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mesaj iletildi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final peerLabel = _peerName ?? 'Sohbet';
    final statusLabel = _peerTyping
        ? 'Yazıyor...'
        // Yalnız sunucunun döndüğü gerçek veri; yoksa boş (uydurma ifade yok).
        : presenceLabel(isOnline: _peerOnline, lastSeenAt: _peerLastSeen);

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
                    GestureDetector(
                      onLongPress: _showPeerActions,
                      child: PresenceRingAvatar(url: _peerAvatar, radius: 18, isOnline: _peerOnline),
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
                              style: TextStyle(
                                color: context.colors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (statusLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _peerTyping
                                      ? AppThemeColors.accentPink
                                      : _peerOnline
                                          ? const Color(0xFF22C55E)
                                          : context.colors.onSurfaceMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
              onVoiceNote: _toggleVoiceNote,
              tightBottomInset: true,
            ),
          ],
        ),
      ),
    );
  }
}
