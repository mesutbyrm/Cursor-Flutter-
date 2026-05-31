import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/chat_room_message.dart';
import '../../../theme/voice_room_tokens.dart';

/// PK — cam efektli canlı hediye akışı (referans görsel).
class PkGiftFeedPanel extends StatelessWidget {
  const PkGiftFeedPanel({
    super.key,
    required this.messages,
    this.maxItems = 6,
  });

  final List<ChatRoomMessage> messages;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final gifts = messages
        .where((m) => m.kind == ChatMessageKind.gift)
        .toList()
        .reversed
        .take(maxItems)
        .toList();

    if (gifts.isEmpty) {
      return Center(
        child: Text(
          'Hediye gönder — skor kazan',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: gifts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _GiftFeedRow(message: gifts[i]),
    );
  }
}

class _GiftFeedRow extends StatelessWidget {
  const _GiftFeedRow({required this.message});

  final ChatRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.user;
    final name = user?.displayWithPrefix ?? 'Kullanıcı';
    final emoji = message.giftEmoji ?? '🎁';
    final count = message.giftCount ?? 1;
    final text = message.content.trim();
    final giftLabel = text.isNotEmpty ? text : 'hediye gönderdi';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white12,
                backgroundImage: user?.image != null && user!.image!.isNotEmpty
                    ? CachedNetworkImageProvider(user.image!)
                    : null,
                child: user?.image == null || user!.image!.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, height: 1.25),
                    children: [
                      TextSpan(
                        text: '$name ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: '$emoji '),
                      TextSpan(
                        text: giftLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: VoiceRoomTokens.gold.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'x$count',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: VoiceRoomTokens.gold.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
