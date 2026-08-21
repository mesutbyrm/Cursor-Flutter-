import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/dm_message_sound_service.dart';
import '../../domain/utils/dm_message_codec.dart';
import '../providers/chat_messages_list_notifier.dart';
import '../providers/conversations_list_notifier.dart';
import '../providers/messages_unread_providers.dart';
import '../providers/messages_providers.dart';
import '../services/dm_voice_call_service.dart';

/// Açık DM sohbeti — global poll yeni mesajda yeniler.
final openDmConversationIdProvider = StateProvider<String?>((ref) => null);

/// Uygulama genelinde DM güncellemesi — push dışında da liste ve rozet yenilenir.
class DmRealtimeListener extends ConsumerStatefulWidget {
  const DmRealtimeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DmRealtimeListener> createState() => _DmRealtimeListenerState();
}

class _DmRealtimeListenerState extends ConsumerState<DmRealtimeListener> {
  Timer? _poll;
  int _lastUnread = 0;
  final _knownCallSignals = <String>{};

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 12), (_) => _tick());
    unawaited(_tick());
  }

  void _stopPoll() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _tick() async {
    if (!mounted) return;
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId == null) return;

    await ref.read(conversationsListNotifierProvider.notifier).refresh(
          silent: true,
          forceRefresh: true,
        );
    ref.invalidate(conversationsProvider);

    final unread = ref.read(conversationsUnreadTotalProvider);
    if (unread > _lastUnread) {
      unawaited(DmMessageSoundService.instance.playIncoming());
      refreshOpenDmChat(ref, ref.read(openDmConversationIdProvider));
    }
    _lastUnread = unread;

    await _scanCallSignals(userId);
  }

  Future<void> _scanCallSignals(String userId) async {
    final openId = ref.read(openDmConversationIdProvider);
    final conversations =
        ref.read(conversationsListNotifierProvider).valueOrNull?.all ??
            const [];
    final repo = ref.read(messagesRepositoryProvider);
    final service = ref.read(dmVoiceCallServiceProvider);

    final Iterable targets;
    if (openId != null && openId.isNotEmpty) {
      targets = conversations.where((c) => c.id == openId).take(1);
    } else {
      targets = conversations.where((c) => c.unreadCount > 0).take(4);
    }

    for (final c in targets) {
      if (c.id.isEmpty || c.id == userId) continue;
      try {
        final messages = await repo.messages(
          c.id,
          currentUserId: userId,
        );
        for (final m in messages.reversed.take(6)) {
          final raw = m.rawText ?? m.text;
          if (!DmMessageCodec.isSystemPayload(raw)) continue;
          final key = '${m.id}:$raw';
          if (_knownCallSignals.contains(key)) continue;
          _knownCallSignals.add(key);
          if (_knownCallSignals.length > 400) {
            _knownCallSignals.remove(_knownCallSignals.first);
          }
          service.handleRawMessage(
            peerUserId: c.id,
            peerName: c.title,
            peerAvatarUrl: c.avatarUrl,
            rawContent: raw,
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      if (next.valueOrNull != null && prev?.valueOrNull == null) {
        _startPoll();
      } else if (next.valueOrNull == null) {
        _stopPoll();
        _lastUnread = 0;
        _knownCallSignals.clear();
      }
    });

    final authed = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull),
    );
    if (authed != null && _poll == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _poll == null) _startPoll();
      });
    }

    return widget.child;
  }
}

/// Push veya global poll sonrası açık sohbeti de yenile.
void refreshOpenDmChat(WidgetRef ref, String? conversationId) {
  if (conversationId == null || conversationId.isEmpty) return;
  ref
      .read(chatMessagesListNotifierProvider(conversationId).notifier)
      .refresh(silent: true, forceRefresh: true);
}
