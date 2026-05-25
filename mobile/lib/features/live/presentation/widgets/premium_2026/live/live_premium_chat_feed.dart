import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../broadcast_room/live_room_chat_message.dart';

/// Canlı yorum akışı — cam baloncuklar, alttan yukarı.
class LivePremiumChatFeed extends StatelessWidget {
  const LivePremiumChatFeed({
    super.key,
    required this.messages,
    this.maxHeight = 200,
  });

  final List<LiveRoomChatMessage> messages;
  final double maxHeight;

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
            return _ChatBubble(message: m)
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
            color: AppColors.coinGold.withValues(alpha: 0.95),
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
                  TextSpan(
                    text: '${message.user} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentPink,
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
