import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat_room_message.dart';
import 'voice_glass.dart';

class VoicePremiumChat extends StatelessWidget {
  const VoicePremiumChat({
    super.key,
    required this.messages,
    this.onUserTap,
  });

  final List<ChatRoomMessage> messages;
  final void Function(String userId, String name)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final visible = messages.length > 50
        ? messages.sublist(messages.length - 50)
        : messages;

    return VoiceGlass(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: 18,
      child: ListView.builder(
        reverse: true,
        padding: EdgeInsets.zero,
        itemCount: visible.length,
        itemBuilder: (context, i) {
          final msg = visible[visible.length - 1 - i];
          return _MessageBubble(
            message: msg,
            onUserTap: onUserTap,
          );
        },
      ),
    );
  }
}

class VoicePremiumMessageBar extends StatelessWidget {
  const VoicePremiumMessageBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onGift,
    this.sending = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onGift;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white70, size: 22),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Mesaj yaz…',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.85),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              IconButton(
                onPressed: sending ? null : onSend,
                icon: Icon(
                  Icons.send_rounded,
                  color: sending ? AppColors.textMuted : AppColors.accentCyan,
                ),
              ),
              IconButton(
                onPressed: onGift,
                icon: const Icon(Icons.card_giftcard_rounded,
                    color: AppColors.coinGold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onUserTap});

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          message.content,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted.withValues(alpha: 0.9),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (message.kind == ChatMessageKind.gift) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentPink.withValues(alpha: 0.25),
                AppColors.accentPurple.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.coinGold,
            ),
          ),
        ),
      );
    }

    final user = message.user;
    final name = user?.displayName ?? 'Kullanıcı';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: user != null ? () => onUserTap?.call(user.id, name) : null,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.white),
            children: [
              TextSpan(
                text: '$name: ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: user?.isBroadcaster == true
                      ? AppColors.coinGold
                      : AppColors.accentPink,
                ),
              ),
              TextSpan(text: message.content),
            ],
          ),
        ),
      ),
    );
  }
}
