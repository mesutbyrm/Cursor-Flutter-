import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_floating_gifts_strip.dart';

/// Yüzen cam sohbet paneli + mesaj girişi.
class VoiceLiveChatDock extends StatelessWidget {
  const VoiceLiveChatDock({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onGift,
    this.sending = false,
    this.onUserTap,
    this.maxHeight = 160,
  });

  final List<ChatRoomMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onGift;
  final bool sending;
  final void Function(String userId, String name)? onUserTap;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final visible = messages.length > 40
        ? messages.sublist(messages.length - 40)
        : messages;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoiceFloatingGiftsStrip(messages: messages),
        if (messages.any((m) => m.kind == ChatMessageKind.gift))
          const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: VoiceRoomTokens.glassCard(),
              child: ListView.builder(
                reverse: true,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final msg = visible[visible.length - 1 - i];
                  return _Bubble(message: msg, onUserTap: onUserTap);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _InputBar(
          controller: controller,
          onSend: onSend,
          onGift: onGift,
          sending: sending,
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onGift,
    required this.sending,
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
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.only(left: 4, right: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white54, size: 22),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Yorum ekle…',
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
                  color: sending ? AppColors.textMuted : VoiceRoomTokens.neonBlue,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onUserTap});

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          message.content,
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
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VoiceRoomTokens.gold.withValues(alpha: 0.35),
                VoiceRoomTokens.neonPink.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VoiceRoomTokens.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Text('🚀', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: VoiceRoomTokens.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = message.user;
    final name = user?.displayWithPrefix ?? 'Kullanıcı';
    final vip = user?.isBroadcaster == true ||
        user?.membership?.toLowerCase().contains('vip') == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: GestureDetector(
        onTap: user != null ? () => onUserTap?.call(user.id, name) : null,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, height: 1.35, color: Colors.white),
            children: [
              TextSpan(
                text: '$name: ',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: vip ? VoiceRoomTokens.gold : VoiceRoomTokens.neonPink,
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
