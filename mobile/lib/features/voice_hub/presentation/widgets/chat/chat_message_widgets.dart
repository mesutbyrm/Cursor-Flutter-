import 'package:flutter/material.dart';

import 'package:canlifal_social/core/auth/voice_staff_rank.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

import '../../../domain/entities/chat_room_message.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_staff_chat_style.dart';
import 'voice_staff_chat_avatar.dart';

/// Sohbet satırı — RepaintBoundary ile izole çizim.
class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onUserTap,
    this.onUserDoubleTap,
    this.showAvatar = false,
    this.avatarUrl,
  });

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;
  final void Function(String userId, String name)? onUserDoubleTap;
  final bool showAvatar;
  /// Presence'tan çözülen profil resmi — mesajda görsel yoksa kullanılır.
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _ChatMessageBody(
          message: message,
          onUserTap: onUserTap,
          onUserDoubleTap: onUserDoubleTap,
          showAvatar: showAvatar,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }
}

class _ChatMessageBody extends StatelessWidget {
  const _ChatMessageBody({
    required this.message,
    this.onUserTap,
    this.onUserDoubleTap,
    this.showAvatar = false,
    this.avatarUrl,
  });

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;
  final void Function(String userId, String name)? onUserDoubleTap;
  final bool showAvatar;
  final String? avatarUrl;

  String? get _effectiveImage {
    final a = avatarUrl?.trim();
    if (a != null && a.isNotEmpty) return a;
    final u = message.user?.image?.trim();
    return (u != null && u.isNotEmpty) ? u : null;
  }

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
    final name = user?.displayName ?? 'Kullanıcı';
    final tier = VipTier.fromMembership(user?.membership);
    final vip = user?.isBroadcaster == true || tier.index >= VipTier.gold.index;
    final rank = VoiceStaffChatStyle.rankOf(user);
    final isStaff = VoiceStaffChatStyle.isStaffUser(user);
    final showIstek = _isIstekLine(message.content);

    if (isStaff) {
      return _StaffChatLine(
        name: name,
        content: message.content,
        user: user,
        rank: rank,
        showIstek: showIstek,
        onTap: user != null ? () => onUserTap?.call(user.id, name) : null,
        onDoubleTap:
            user != null ? () => onUserDoubleTap?.call(user.id, name) : null,
        imageUrl: _effectiveImage,
      );
    }

    final nameColor = _usernameColor(user, vip, rank);

    return GestureDetector(
      onTap: user != null ? () => onUserTap?.call(user.id, name) : null,
      onDoubleTap:
          user != null ? () => onUserDoubleTap?.call(user.id, name) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar && user != null) ...[
              UserAvatarWidget(url: _effectiveImage, radius: 14),
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
                      ),
                    ),
                    TextSpan(text: message.content),
                  ],
                ),
              ),
            ),
            if (showIstek) _IstekBadge(),
          ],
        ),
      ),
    );
  }
}

class _StaffChatLine extends StatelessWidget {
  const _StaffChatLine({
    required this.name,
    required this.content,
    required this.user,
    required this.rank,
    required this.showIstek,
    this.onTap,
    this.onDoubleTap,
    this.imageUrl,
  });

  final String? imageUrl;

  final String name;
  final String content;
  final ChatRoomUserRef? user;
  final VoiceStaffRank rank;
  final bool showIstek;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  Color get _accent => VoiceStaffChatStyle.accentForUser(user);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VoiceStaffChatAvatar(
            rank: rank,
            imageUrl: (imageUrl?.trim().isNotEmpty == true)
                ? imageUrl
                : user?.image,
            accent: _accent,
            size: 36,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    color: _accent,
                    shadows: VoiceStaffChatStyle.nameGlow(_accent),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.94),
                    shadows: VoiceStaffChatStyle.bodyGlow(_accent),
                  ),
                ),
              ],
            ),
          ),
          if (showIstek) _IstekBadge(),
        ],
      ),
    );
  }
}

class _IstekBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    return const SizedBox.shrink();
  }
}

bool _isIstekLine(String content) {
  final c = content.trim().toLowerCase();
  return c.startsWith('!istek') || c.contains('şarkı isteği');
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
