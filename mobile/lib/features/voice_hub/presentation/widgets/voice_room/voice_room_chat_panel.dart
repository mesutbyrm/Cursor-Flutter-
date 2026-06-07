import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../domain/entities/chat_room_message.dart';

class VoiceRoomChatPanel extends StatelessWidget {
  const VoiceRoomChatPanel({
    super.key,
    required this.messages,
    this.maxHeight = 200,
  });

  final List<ChatRoomMessage> messages;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final visible = messages.length > 40
        ? messages.sublist(messages.length - 40)
        : messages;

    return SizedBox(
      height: maxHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: visible.length,
        itemBuilder: (context, i) => _ChatRow(message: visible[i]),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.message});

  final ChatRoomMessage message;

  @override
  Widget build(BuildContext context) {
    switch (message.kind) {
      case ChatMessageKind.systemLeave:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurfaceMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      case ChatMessageKind.systemJoin:
        return const SizedBox.shrink();
      case ChatMessageKind.gift:
        return _GiftRow(message: message);
      case ChatMessageKind.text:
      case ChatMessageKind.unknown:
        return _TextRow(message: message);
    }
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow({required this.message});

  final ChatRoomMessage message;

  Color _nameColor(ChatRoomUserRef? u) {
    if (u?.isBroadcaster == true) return AppThemeColors.coinGold;
    final role = u?.chatRole;
    if (role == 'vip') return AppThemeColors.accentCyan;
    return AppThemeColors.accentPink;
  }

  @override
  Widget build(BuildContext context) {
    final u = message.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(url: u?.image),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, height: 1.35),
                children: [
                  TextSpan(
                    text: u?.displayName ?? 'Kullanıcı',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _nameColor(u),
                    ),
                  ),
                  if (u?.isBroadcaster == true)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppThemeColors.accentPurple.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Yayıncı',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: message.content,
                    style: TextStyle(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRow extends StatelessWidget {
  const _GiftRow({required this.message});

  final ChatRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final count = message.giftCount ?? 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _Avatar(url: message.user?.image),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppThemeColors.accentPink,
              ),
            ),
          ),
          Text(
            '${message.giftEmoji ?? '🎁'} x$count',
            style: TextStyle(fontSize: 28),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppThemeColors.accentPurple.withValues(alpha: 0.5)),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : ColoredBox(
                color: AppThemeColors.dark.surfaceContainer,
                child: const Icon(Icons.person, size: 16, color: Colors.white54),
              ),
      ),
    );
  }
}
