import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/ui/premium/premium_glass_surface.dart';
import 'live_room_chat_message.dart';

class LiveRoomChatPanel extends StatelessWidget {
  const LiveRoomChatPanel({
    super.key,
    required this.messages,
    this.maxHeight = 160,
  });

  final List<LiveRoomChatMessage> messages;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (ctx, i) {
          final m = messages[messages.length - 1 - i];
          return LiveRoomChatBubble(message: m);
        },
      ),
    );
  }
}

class LiveRoomChatBubble extends StatelessWidget {
  const LiveRoomChatBubble({super.key, required this.message});

  final LiveRoomChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          message.text,
          style: TextStyle(
            color: AppColors.accentCyan.withValues(alpha: 0.95),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PremiumGlassSurface(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: BorderRadius.circular(14),
        blur: 6,
        opacity: 0.45,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, height: 1.35),
            children: [
              TextSpan(
                text: '${message.user}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentCyan,
                ),
              ),
              TextSpan(
                text: message.text,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
