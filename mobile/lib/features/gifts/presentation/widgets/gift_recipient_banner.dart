import 'package:flutter/material.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../live/domain/entities/live_gift_event.dart';

/// Hediye animasyonunun üstünde "X → Y'ye Gül gönderdi" bandı.
///
/// Alıcı bilinmiyorsa (oda geneli hediye) hiçbir şey çizilmez.
class GiftRecipientBanner extends StatelessWidget {
  const GiftRecipientBanner({super.key, required this.event});

  final LiveGiftEvent event;

  /// Bandın gösterilip gösterilmeyeceği (alıcı adı olan hediyeler).
  static bool shouldShow(LiveGiftEvent event) =>
      event.receiverName.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(event)) return const SizedBox.shrink();
    final sender = event.senderName.trim().isEmpty
        ? 'Biri'
        : event.senderName.trim();
    final receiver = event.receiverName.trim();
    final qty = event.quantity > 1 ? ' x${event.quantity}' : '';
    return Semantics(
      label: '$sender, $receiver kullanıcısına ${event.giftName} gönderdi',
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(url: event.senderAvatar, name: sender),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                sender,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFFFFD54F),
              ),
            ),
            _Avatar(url: event.receiverAvatar, name: receiver),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                receiver,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${event.giftName}$qty',
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(' 🎁', style: TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    final initial = name.characters.isEmpty
        ? '?'
        : name.characters.first.toUpperCase();
    final fallback = ColoredBox(
      color: Colors.white24,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    return ClipOval(
      child: SizedBox(
        width: 26,
        height: 26,
        child: u != null && u.isNotEmpty
            ? CanlifalNetworkImage(
                url: u,
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                thumbnailWidth: 64,
                fadeIn: false,
                errorWidget: fallback,
              )
            : fallback,
      ),
    );
  }
}
