import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../trtc/presentation/trtc_room_manager.dart';
import '../../broadcast_room/live_camera_control.dart';

/// Mockup alt bar — mesaj + Misafir / Eş Yayın / Oyunlar / Paylaş / Hediye kutusu / Daha fazla.
/// Hediyeler açık şeritte değil; yalnızca hediye kutusundan açılır.
class LivePremiumBottomBar extends StatelessWidget {
  const LivePremiumBottomBar({
    super.key,
    required this.chatController,
    required this.onSend,
    required this.isHost,
    this.trtc,
    this.onGift,
    this.onToggleCamera,
    this.onRtcStateChanged,
    this.onEnd,
    this.onJoinBroadcast,
    this.onGuest,
    this.onCoBroadcast,
    this.onGames,
    this.onShare,
    this.onMore,
    this.onToggleChat,
    this.chatVisible = true,
    this.commentsEnabled = true,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final VoidCallback? onGift;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onEnd;
  final VoidCallback? onJoinBroadcast;
  final VoidCallback? onGuest;
  final VoidCallback? onCoBroadcast;
  final VoidCallback? onGames;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final VoidCallback? onToggleChat;
  final bool chatVisible;
  final bool commentsEnabled;

  void _showEmojiPicker(BuildContext context) {
    const emojis = [
      '😀', '😂', '❤️', '🔥', '👏', '🎉', '💎', '🎤',
      '🙏', '✨', '💜', '😍', '🤣', '👋', '🌙', '⭐',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF14101F).withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: emojis
              .map(
                (e) => InkWell(
                  onTap: () {
                    chatController.text = '${chatController.text}$e';
                    Navigator.pop(ctx);
                  },
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasRtc = trtc != null;
    final rtcChanged = onRtcStateChanged ?? onToggleCamera;
    final guestAction = onGuest ?? onJoinBroadcast;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 8, 10, bottom + 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHost && hasRtc) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    LiveMicToggleButton(
                      trtc: trtc!,
                      size: 40,
                      onChanged: rtcChanged,
                    ),
                    LiveCameraToggleButton(
                      trtc: trtc!,
                      size: 40,
                      onChanged: rtcChanged,
                    ),
                    LiveCameraSwitchButton(trtc: trtc!),
                    if (onEnd != null)
                      _MiniControl(
                        icon: Icons.stop_circle_rounded,
                        label: 'Bitir',
                        color: AppThemeColors.liveRed,
                        onTap: onEnd,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (onToggleChat != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _ActionIcon(
                        icon: chatVisible
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        label: 'Sohbet',
                        onTap: onToggleChat,
                        active: chatVisible,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: chatController,
                              enabled: commentsEnabled,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: commentsEnabled
                                    ? 'Mesajını yaz...'
                                    : 'Yorumlar kapalı',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => onSend(),
                            ),
                          ),
                          IconButton(
                            onPressed: commentsEnabled
                                ? () => _showEmojiPicker(context)
                                : null,
                            icon: Icon(
                              Icons.emoji_emotions_outlined,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (guestAction != null)
                    _ActionIcon(
                      icon: Icons.people_alt_rounded,
                      label: 'Misafir',
                      onTap: guestAction,
                    ),
                  if (onCoBroadcast != null)
                    _ActionIcon(
                      icon: Icons.video_call_rounded,
                      label: 'Eş Yayın',
                      onTap: onCoBroadcast,
                    ),
                  if (onGames != null)
                    _ActionIcon(
                      icon: Icons.sports_esports_rounded,
                      label: 'Oyunlar',
                      onTap: onGames,
                    ),
                  if (onShare != null)
                    _ActionIcon(
                      icon: Icons.share_rounded,
                      label: 'Paylaş',
                      onTap: onShare,
                    ),
                  if (onGift != null) ...[
                    const SizedBox(width: 2),
                    _GiftBoxButton(onTap: onGift!),
                  ],
                  if (onMore != null)
                    _ActionIcon(
                      icon: Icons.more_horiz_rounded,
                      label: 'Daha fazla',
                      onTap: onMore,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Büyük mor hediye kutusu — panel yalnızca buradan açılır.
class _GiftBoxButton extends StatelessWidget {
  const _GiftBoxButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB388FF), Color(0xFF7C4DFF), Color(0xFF5E35B1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hediye',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppThemeColors.accentPurple.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              Icon(icon, color: color ?? Colors.white, size: 22),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
