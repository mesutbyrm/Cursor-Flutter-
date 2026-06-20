import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../broadcast_room/live_room_chat_message.dart';
import '../live_vip_chat_badge.dart';

/// Canlı yorum akışı — cam baloncuklar, alttan yukarı.
class LivePremiumChatFeed extends StatelessWidget {
  const LivePremiumChatFeed({
    super.key,
    required this.messages,
    this.maxHeight = 200,
    this.onMessageLongPress,
    this.canModerate = false,
  });

  final List<LiveRoomChatMessage> messages;
  final double maxHeight;
  final void Function(LiveRoomChatMessage message)? onMessageLongPress;
  final bool canModerate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
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
          itemCount: messages.length,
          itemBuilder: (ctx, i) {
            final m = messages[messages.length - 1 - i];
            final bubble = _ChatBubble(message: m);
            final child = canModerate &&
                    onMessageLongPress != null &&
                    !m.isSystem &&
                    m.userId != null &&
                    m.userId!.isNotEmpty
                ? GestureDetector(
                    onLongPress: () => onMessageLongPress!(m),
                    child: bubble,
                  )
                : bubble;
            return child
                .animate(delay: (20 * (i % 4)).ms)
                .fadeIn(duration: 220.ms)
                .slideX(begin: -0.04, end: 0);
          },
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, height: 1.35),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isVip)
                          const LiveVipChatBadge(kind: LiveChatBadgeKind.vip),
                        if (message.isModerator)
                          const LiveVipChatBadge(kind: LiveChatBadgeKind.moderator),
                        if (message.isFortuneTeller)
                          const LiveVipChatBadge(kind: LiveChatBadgeKind.fortuneTeller),
                        if (message.level != null)
                          LiveVipChatBadge(
                            kind: LiveChatBadgeKind.level,
                            label: 'Lv${message.level}',
                          ),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: '${message.user} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppThemeColors.accentPink,
                    ),
                  ),
                  TextSpan(
                    text: message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
