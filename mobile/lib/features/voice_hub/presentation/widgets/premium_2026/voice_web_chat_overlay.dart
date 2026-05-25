import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../vip_gold/domain/vip_tier.dart';
import '../../../domain/entities/chat_room_message.dart';
import '../../theme/voice_room_tokens.dart';

/// Web tarzı şeffaf sohbet — arka plan üzerinde yüzen mesajlar.
class VoiceWebChatOverlay extends StatelessWidget {
  const VoiceWebChatOverlay({
    super.key,
    required this.messages,
    this.onUserTap,
    this.maxHeight = 220,
  });

  final List<ChatRoomMessage> messages;
  final void Function(String userId, String name)? onUserTap;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final visible = messages
        .where(
          (m) =>
              m.kind == ChatMessageKind.text ||
              m.kind == ChatMessageKind.gift ||
              m.kind == ChatMessageKind.systemJoin ||
              m.kind == ChatMessageKind.systemLeave,
        )
        .toList();
    final slice = visible.length > 40
        ? visible.sublist(visible.length - 40)
        : visible;

    if (slice.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'Sohbet odasına hoş geldiniz — mesajınızı yazın',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.55),
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 6),
            ],
          ),
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white, Colors.white],
        stops: [0.0, 0.08, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: maxHeight,
        child: ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          physics: const ClampingScrollPhysics(),
          itemCount: slice.length,
          itemBuilder: (context, i) {
            final msg = slice[slice.length - 1 - i];
            return _WebChatLine(message: msg, onUserTap: onUserTap);
          },
        ),
      ),
    );
  }
}

class _WebChatLine extends StatelessWidget {
  const _WebChatLine({required this.message, this.onUserTap});

  final ChatRoomMessage message;
  final void Function(String userId, String name)? onUserTap;

  @override
  Widget build(BuildContext context) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.95),
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
      );
    }

    if (message.kind == ChatMessageKind.gift) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          message.content,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: VoiceRoomTokens.gold,
            shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
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
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
            ),
            children: [
              TextSpan(
                text: '$name ',
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

/// Web giriş çubuğu — mikrofon, metin, gönder, hediye.
class VoiceWebChatInputBar extends StatelessWidget {
  const VoiceWebChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onMicToggle,
    required this.onGift,
    this.micOn = true,
    this.micEnabled = true,
    this.sending = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onMicToggle;
  final VoidCallback onGift;
  final bool micOn;
  final bool micEnabled;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            border: Border(
              top: BorderSide(
                color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: [
              _MicCircle(
                icon: Icons.mic_rounded,
                active: micOn && micEnabled,
                enabled: micEnabled,
                color: AppColors.accentPink,
                onTap: micEnabled ? onMicToggle : null,
              ),
              const SizedBox(width: 6),
              _MicCircle(
                icon: Icons.mic_off_rounded,
                active: !micOn && micEnabled,
                enabled: micEnabled,
                color: AppColors.textMuted,
                onTap: micEnabled ? onMicToggle : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: VoiceRoomTokens.neonPurple,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: sending ? null : onSend,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: AppColors.coinGold.withValues(alpha: 0.22),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onGift,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.coinGold,
                      size: 24,
                    ),
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

class _MicCircle extends StatelessWidget {
  const _MicCircle({
    required this.icon,
    required this.active,
    required this.enabled,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final bool active;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? color.withValues(alpha: 0.28)
          : Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: enabled
                ? (active ? color : Colors.white54)
                : Colors.white24,
          ),
        ),
      ),
    );
  }
}
