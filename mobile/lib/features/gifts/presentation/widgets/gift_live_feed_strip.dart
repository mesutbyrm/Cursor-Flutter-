import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_feed_item.dart';
import '../providers/gift_insights_providers.dart';

/// Bir bağlamdaki canlı hediye akışı — son gönderimleri kayan şerit olarak
/// gösterir (gizli hediyeler backend'de dışlanır). Boşsa gizlenir.
class GiftLiveFeedStrip extends ConsumerWidget {
  const GiftLiveFeedStrip({
    super.key,
    required this.context,
    required this.contextId,
  });

  final String context;
  final String contextId;

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final GiftFeedKey key = (context: context, contextId: contextId);
    final async = ref.watch(giftFeedProvider(key));
    final items = async.asData?.value ?? const <GiftFeedItem>[];
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => _FeedChip(item: items[i]),
      ),
    );
  }
}

class _FeedChip extends StatelessWidget {
  const _FeedChip({required this.item});
  final GiftFeedItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x33B388FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: Color(0xFFFFD54F), size: 13),
          const SizedBox(width: 5),
          Text(
            '${item.senderName} → ${item.receiverName}'
            '${item.amount > 1 ? '  ×${item.amount}' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
