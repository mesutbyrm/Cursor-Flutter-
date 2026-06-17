import 'package:flutter/material.dart';

import 'package:canlifal_social/core/auth/voice_staff_rank.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../theme/voice_room_tokens.dart';

/// Sohbet satırı — RepaintBoundary ile izole çizim.
class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onUserTap,
    this.showAvatar = false,
  });

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _ChatMessageBody(
          message: message,
          onUserTap: onUserTap,
          showAvatar: showAvatar,
        ),
      ),
    );
  }
}

class _ChatMessageBody extends StatelessWidget {
  const _ChatMessageBody({
    required this.message,
    this.onUserTap,
    this.showAvatar = false,
  });

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      return _SystemJoinLine(content: message.content);
    }
    if (message.kind == ChatMessageKind.gift) {
      return GiftWidget(content: message.content);
    }

    final user = message.user;
    final name = user?.displayWithPrefix ?? 'Kullanıcı';
    final tier = VipTier.fromMembership(user?.membership);
    final vip = user?.isBroadcaster == true || tier.index >= VipTier.gold.index;
    final rank = VoiceStaffRankParser.resolve(
      username: user?.nickname ?? user?.name,
      chatRole: user?.chatRole,
    );
    final styled = _isStyledName(user, vip, rank);
    final nameColor = _usernameColor(user, vip, rank);
    final showIstek = _isIstekLine(message.content);

    return GestureDetector(
      onTap: user != null ? () => onUserTap?.call(user.id, name) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: styled
                ? nameColor.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar && user != null) ...[
              UserAvatarWidget(url: user.image, radius: 14),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: '$name ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: nameColor,
                        shadows: styled
                            ? const [Shadow(color: Colors.black87, blurRadius: 6)]
                            : null,
                      ),
                    ),
                    TextSpan(text: message.content),
                  ],
                ),
              ),
            ),
            if (showIstek)
              Container(
                margin: const EdgeInsets.only(left: 6, top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'İSTEK',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hediye / sistem altın satırı.
class GiftWidget extends StatelessWidget {
  const GiftWidget({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: VoiceRoomTokens.gold,
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

/// Avatar — CachedNetworkImage, max 128×128 önbellek.
class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({
    super.key,
    this.url,
    this.radius = 18,
  });

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: UserAvatar(url: url, radius: radius),
    );
  }
}

class MusicSystemChatLine extends StatelessWidget {
  const MusicSystemChatLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB388FF),
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class _SystemJoinLine extends StatelessWidget {
  const _SystemJoinLine({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final icon = _joinIcon(content);
    final color = _joinColor(content);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

bool _isIstekLine(String content) {
  final c = content.trim().toLowerCase();
  return c.startsWith('!istek') || c.contains('şarkı isteği');
}

bool _isStyledName(
  ChatRoomUserRef? user,
  bool vip,
  VoiceStaffRank rank,
) {
  if (vip) return true;
  if (user?.chatRole == 'owner' || user?.chatRole == 'founder') return true;
  return VoiceStaffRankParser.powerLevel(rank) >=
      VoiceStaffRankParser.powerLevel(VoiceStaffRank.op);
}

Color _usernameColor(ChatRoomUserRef? user, bool vip, VoiceStaffRank rank) {
  if (user?.chatRole == 'owner' || user?.chatRole == 'founder') {
    return VoiceRoomTokens.gold;
  }
  if (VoiceStaffRankParser.powerLevel(rank) >=
      VoiceStaffRankParser.powerLevel(VoiceStaffRank.admin)) {
    return VoiceRoomTokens.gold;
  }
  if (VoiceStaffRankParser.canModerate(rank)) return VoiceRoomTokens.neonPurple;
  if (user?.chatRole == 'dj') return VoiceRoomTokens.neonPink;
  if (user?.isBroadcaster == true) return VoiceRoomTokens.neonBlue;
  if (vip) return VoiceRoomTokens.gold;
  return const Color(0xFF4ADE80);
}

IconData _joinIcon(String content) {
  final u = content.toUpperCase();
  if (u.contains('ADMIN') || u.contains('KURUCU') || u.contains('FOUNDER')) {
    return Icons.workspace_premium_rounded;
  }
  if (u.contains('DJ')) return Icons.auto_awesome_rounded;
  if (u.contains('GOLD') || u.contains('VIP')) {
    return Icons.hexagon_rounded;
  }
  return Icons.person_add_alt_1_rounded;
}

Color _joinColor(String content) {
  final u = content.toUpperCase();
  if (u.contains('ADMIN') || u.contains('GOLD') || u.contains('VIP')) {
    return VoiceRoomTokens.gold;
  }
  if (u.contains('DJ')) return VoiceRoomTokens.neonPink;
  return VoiceRoomTokens.neonBlue;
}
