import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/live_room_providers.dart';
import 'live_room_chat_message.dart';

/// Referans — şeffaf sohbet akışı (video üzerinde).
class LivePkReferenceChatOverlay extends ConsumerWidget {
  const LivePkReferenceChatOverlay({
    super.key,
    required this.streamId,
    this.maxHeight = 148,
    this.visible = true,
  });

  final String streamId;
  final double maxHeight;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible || streamId.isEmpty) return const SizedBox.shrink();
    final room = ref.watch(liveRoomProvider(streamId));
    final messages = room.messages;
    if (messages.isEmpty) return const SizedBox.shrink();

    final tail = messages.length > 12
        ? messages.sublist(messages.length - 12)
        : messages;

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 4, 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView.builder(
            reverse: true,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: tail.length,
            itemBuilder: (context, i) {
              final m = tail[tail.length - 1 - i];
              return _ChatLine(message: m);
            },
          ),
        ),
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.message});

  final LiveRoomChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isGift = message.text.contains('hediye') ||
        message.text.contains('🌹') ||
        message.text.contains('Gönderdi');
    final initial =
        message.user.isNotEmpty ? message.user[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.65),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: isGift ? 0.55 : 0.38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${message.user} ',
                        style: TextStyle(
                          color: message.isVip
                              ? const Color(0xFFFFD54F)
                              : const Color(0xFFB832FF),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
