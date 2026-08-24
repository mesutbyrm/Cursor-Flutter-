import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../domain/gift_engine_models.dart';
import '../sync/gift_session_controller.dart';

/// Sağ tarafta küçük gift feed — backend süresi kadar görünür.
class GiftFeedPanel extends ConsumerWidget {
  const GiftFeedPanel({
    super.key,
    required this.sessionKey,
    this.maxWidth = 168,
  });

  final String sessionKey;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      giftSessionProvider(sessionKey).select((s) => s.feedItems),
    );
    if (items.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 8,
      top: MediaQuery.paddingOf(context).top + 120,
      width: maxWidth,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final item in items.take(4)) _FeedRow(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.item});

  final GiftFeedItem item;

  @override
  Widget build(BuildContext context) {
    final icon = item.giftIcon?.trim();
    final iconUrl = item.iconUrl;
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 220),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.senderName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (icon != null && icon.isNotEmpty)
                  Text(icon, style: const TextStyle(fontSize: 16))
                else if (iconUrl != null && iconUrl.isNotEmpty)
                  CanlifalNetworkImage(
                    url: iconUrl,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.giftName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${item.jetonAmount} Jeton${item.comboLabel}',
              style: TextStyle(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.95),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
