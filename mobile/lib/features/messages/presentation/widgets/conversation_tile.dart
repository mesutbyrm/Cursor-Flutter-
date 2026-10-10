import 'package:flutter/material.dart';

import '../../../../core/navigation/unread_badge_format.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/message_entities.dart';
import '../../domain/utils/last_seen_format.dart';

const _waGreen = Color(0xFF25D366);
const _onlineGreen = Color(0xFF22C55E);

/// Canlı renkli halkalı avatar; yalnız sunucu çevrimiçi dediğinde yeşil nokta.
class PresenceRingAvatar extends StatelessWidget {
  const PresenceRingAvatar({super.key, this.url, this.radius = 28, this.isOnline = false});

  final String? url;
  final double radius;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final ring = isOnline
        ? const [Color(0xFF22C55E), Color(0xFF06B6D4)]
        : const [Color(0xFF7C3AED), Color(0xFFFF2D8D), Color(0xFFF59E0B)];
    final dot = (radius * 0.42).clamp(10.0, 16.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [...ring, ring.first])),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, color: context.scaffoldBg),
            child: UserAvatar(url: url, radius: radius),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              key: const Key('presence-online-dot'),
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: _onlineGreen,
                shape: BoxShape.circle,
                border: Border.all(color: context.scaffoldBg, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// WhatsApp tarzı sohbet satırı: büyük avatar, belirgin isim, altında son mesaj,
/// sağ üstte saat, altında yuvarlak okunmamış rozeti.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation, required this.onTap, this.onLongPress});

  final ConversationEntity conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final unread = c.unreadCount > 0;
    final colors = context.colors;
    final presence = presenceLabel(isOnline: c.isOnline, lastSeenAt: c.lastSeenAt);
    final preview = (c.subtitle ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(
            children: [
              PresenceRingAvatar(url: c.avatarUrl, radius: 27, isOnline: c.isOnline),
              const SizedBox(width: 13),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 9, top: 2),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.onSurfaceMuted.withValues(alpha: 0.14))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: colors.onSurface),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatConversationTime(c.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: unread ? _waGreen : colors.onSurfaceMuted,
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview.isNotEmpty ? preview : presence,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread ? colors.onSurface : colors.onSurfaceMuted,
                                fontSize: 14,
                                fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: _waGreen, borderRadius: BorderRadius.circular(11)),
                              child: Text(
                                UnreadBadgeFormat.label(c.unreadCount),
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (preview.isNotEmpty && presence.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          presence,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.isOnline ? _onlineGreen : colors.onSurfaceMuted.withValues(alpha: 0.85),
                            fontWeight: c.isOnline ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
