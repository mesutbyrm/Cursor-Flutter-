import 'package:canlifal_social/core/performance/effects_perf.dart';
import 'package:canlifal_social/core/performance/scroll_perf.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/live_chat_gift_merge.dart';

import '../../broadcast_room/live_room_chat_message.dart';
import '../live_vip_chat_badge.dart';
import '../../../../../voice_hub/presentation/utils/voice_chat_message_filters.dart';

/// Canlı yorum akışı — opak baloncuklar (liste içinde blur yok).
///
/// [fadeAfter] verilirse, ilk görüldüğünden bu yana o süreyi aşan mesajlar
/// akıştan kaybolur (TikTok tarzı); mesajlar sunucu durumunda silinmez.
class LivePremiumChatFeed extends StatefulWidget {
  const LivePremiumChatFeed({
    super.key,
    required this.messages,
    this.maxHeight = 200,
    this.onMessageLongPress,
    this.canModerate = false,
    this.fadeAfter,
  });

  final List<LiveRoomChatMessage> messages;
  final double maxHeight;
  final void Function(LiveRoomChatMessage message)? onMessageLongPress;
  final bool canModerate;
  final Duration? fadeAfter;

  @override
  State<LivePremiumChatFeed> createState() => _LivePremiumChatFeedState();
}

class _LivePremiumChatFeedState extends State<LivePremiumChatFeed> {
  final _firstSeen = <LiveRoomChatMessage, DateTime>{};
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant LivePremiumChatFeed old) {
    super.didUpdateWidget(old);
    _syncTimer();
  }

  /// GirLive Bot'un giriş selamı 10 sn sonra akıştan kalkar.
  static const _botWelcomeFade = Duration(seconds: 10);

  static bool _isBotWelcome(LiveRoomChatMessage m) =>
      m.user.toLowerCase().contains('girlive') &&
      VoiceChatMessageFilters.looksLikeWelcome(m.text);

  void _syncTimer() {
    if (widget.fadeAfter == null && !widget.messages.any(_isBotWelcome)) {
      _tick?.cancel();
      _tick = null;
      return;
    }
    _tick ??= Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  List<LiveRoomChatMessage> _visible() {
    final merged = mergeGiftChatMessages(widget.messages);
    final fade = widget.fadeAfter;
    if (fade == null && !merged.any(_isBotWelcome)) return merged;
    final now = DateTime.now();
    final live = Set<LiveRoomChatMessage>.of(merged);
    _firstSeen.removeWhere((k, _) => !live.contains(k));
    return merged.where((m) {
      final seen = _firstSeen.putIfAbsent(m, () => now);
      final limit = _isBotWelcome(m) ? _botWelcomeFade : fade;
      return limit == null || now.difference(seen) < limit;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _visible();
    final onMessageLongPress = widget.onMessageLongPress;
    final canModerate = widget.canModerate;
    return EffectsPerf.repaint(
      SizedBox(
        height: widget.maxHeight,
        child: ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white, Colors.white],
            stops: const [0.0, 0.12, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            reverse: true,
            padding: EdgeInsets.zero,
            scrollCacheExtent:
                ScrollPerf.scrollCache(ScrollPerf.chatCacheExtent),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            physics: ScrollPerf.feedPhysics,
            itemCount: messages.length,
            itemBuilder: (ctx, i) {
              final m = messages[messages.length - 1 - i];
              final bubble = ScrollPerf.item(_ChatBubble(message: m));
              return canModerate &&
                      onMessageLongPress != null &&
                      !m.isSystem &&
                      m.userId != null &&
                      m.userId!.isNotEmpty
                  ? GestureDetector(
                      onLongPress: () => onMessageLongPress(m),
                      child: bubble,
                    )
                  : bubble;
            },
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final LiveRoomChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          message.text,
          style: TextStyle(
            color: AppThemeColors.coinGold.withValues(alpha: 0.95),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final initial =
        message.user.trim().isNotEmpty ? message.user.trim()[0].toUpperCase() : '?';
    // TikTok tarzı: küçük avatar + ad üstte, mesaj altta; kenarlıksız, soldan
    // sağa şeffaflaşan koyu gradyan zemin.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.38),
              Colors.black.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppThemeColors.accentPurple,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isVip)
                          const LiveVipChatBadge(kind: LiveChatBadgeKind.vip),
                        if (message.isModerator)
                          const LiveVipChatBadge(
                            kind: LiveChatBadgeKind.moderator,
                          ),
                        if (message.isFortuneTeller)
                          const LiveVipChatBadge(
                            kind: LiveChatBadgeKind.fortuneTeller,
                          ),
                        if (message.level != null)
                          LiveVipChatBadge(
                            kind: LiveChatBadgeKind.level,
                            label: 'Lv${message.level}',
                          ),
                        Flexible(
                          child: Text(
                            message.user,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.3,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
