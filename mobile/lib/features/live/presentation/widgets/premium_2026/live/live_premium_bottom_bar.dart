import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../../agora/presentation/agora_room_manager.dart';
import '../../../../../trtc/presentation/trtc_room_manager.dart';
import '../../broadcast_room/live_camera_control.dart';

/// Alt cam giriş çubuğu + yayıncı kontrolleri.
class LivePremiumBottomBar extends StatelessWidget {
  const LivePremiumBottomBar({
    super.key,
    required this.chatController,
    required this.onSend,
    required this.isHost,
    this.agora,
    this.trtc,
    this.onGift,
    this.onToggleCamera,
    this.onRtcStateChanged,
    this.onEnd,
    this.onJoinBroadcast,
    this.commentsEnabled = true,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final bool isHost;
  final AgoraRoomManager? agora;
  final TrtcRoomManager? trtc;
  final VoidCallback? onGift;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onRtcStateChanged;
  final VoidCallback? onEnd;
  final VoidCallback? onJoinBroadcast;
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

    final hasRtc = agora != null || trtc != null;
    final rtcChanged = onRtcStateChanged ?? onToggleCamera;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, bottom + 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: AppThemeColors.accentPink.withValues(alpha: 0.25)),
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
                      agora: agora,
                      trtc: trtc,
                      size: 44,
                      onChanged: rtcChanged,
                    ),
                    LiveCameraToggleButton(
                      agora: agora,
                      trtc: trtc,
                      size: 44,
                      onChanged: rtcChanged,
                    ),
                    LiveCameraSwitchButton(
                      agora: agora,
                      trtc: trtc,
                      size: 44,
                    ),
                    if (onEnd != null)
                      _MiniControl(
                        icon: Icons.stop_circle_rounded,
                        label: 'Bitir',
                        color: AppThemeColors.liveRed,
                        onTap: onEnd,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  if (!isHost && onJoinBroadcast != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        onPressed: onJoinBroadcast,
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('Katıl'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              AppThemeColors.accentPink.withValues(alpha: 0.35),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => _showEmojiPicker(context),
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.white70),
                  ),
                  Expanded(
                    child: TextField(
                      controller: chatController,
                      enabled: commentsEnabled,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: commentsEnabled
                            ? 'Yorum yaz…'
                            : 'Yorumlar kapalı',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onGift != null)
                    IconButton(
                      onPressed: onGift,
                      icon: const Icon(Icons.card_giftcard_rounded,
                          color: AppThemeColors.coinGold),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSend,
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: context.colors.brandGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
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
