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

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 80, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView.builder(
              reverse: true,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: tail.length,
              itemBuilder: (context, i) {
                final m = tail[tail.length - 1 - i];
                return _ChatLine(message: m);
              },
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                  style: const TextStyle(
                    color: Color(0xFFB832FF),
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
    );
  }
}
