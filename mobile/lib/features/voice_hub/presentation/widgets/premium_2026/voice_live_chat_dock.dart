import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_floating_gifts_strip.dart';

/// Yalnızca mesaj akışı — sahne üzerinde yüzen feed.
class VoiceLiveChatFeed extends StatelessWidget {
  const VoiceLiveChatFeed({
    super.key,
    required this.messages,
    this.onUserTap,
    this.maxHeight = 200,
  });

  final List<ChatRoomMessage> messages;
  final void Function(String userId, String name)? onUserTap;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final textOnly = messages
        .where(
          (m) =>
              m.kind == ChatMessageKind.text ||
              m.kind == ChatMessageKind.gift ||
              m.kind == ChatMessageKind.systemJoin ||
              m.kind == ChatMessageKind.systemLeave,
        )
        .toList();
    final visible = textOnly.length > 50
        ? textOnly.sublist(textOnly.length - 50)
        : textOnly;

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoiceFloatingGiftsStrip(messages: messages, maxItems: 1),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ListView.builder(
                reverse: true,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final msg = visible[visible.length - 1 - i];
                  return _Bubble(message: msg, onUserTap: onUserTap);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Klavye üstü sabit mesaj girişi.
class VoiceLiveMessageInput extends StatelessWidget {
  const VoiceLiveMessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.sending = false,
    this.hintText = 'Mesaj yaz…',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool sending;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.4),
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
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.85),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: sending ? null : onSend,
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color: VoiceRoomTokens.neonBlue,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Geriye dönük uyumluluk — feed + input birlikte (PK ekranı vb.).
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
    this.focusNode,
  });

  final List<ChatRoomMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onGift;
  final bool sending;
  final void Function(String userId, String name)? onUserTap;
  final double maxHeight;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final node = focusNode ?? FocusNode();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoiceLiveChatFeed(
          messages: messages,
          onUserTap: onUserTap,
          maxHeight: maxHeight,
        ),
        VoiceLiveMessageInput(
          controller: controller,
          focusNode: node,
          onSend: onSend,
          sending: sending,
        ),
      ],
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
        child: Text(
          message.content,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: VoiceRoomTokens.gold,
          ),
        ),
      );
    }

    final user = message.user;
    final name = user?.displayWithPrefix ?? 'Kullanıcı';
    final tier = VipTier.fromMembership(user?.membership);
    final vip = user?.isBroadcaster == true || tier.index >= VipTier.gold.index;

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
