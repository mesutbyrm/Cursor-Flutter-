import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';

/// Alt cam giriş çubuğu + yayıncı kontrolleri.
class LivePremiumBottomBar extends StatelessWidget {
  const LivePremiumBottomBar({
    super.key,
    required this.chatController,
    required this.onSend,
    required this.isHost,
    this.trtc,
    this.onGift,
    this.onToggleCamera,
    this.onEnd,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final VoidCallback? onGift;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, bottom + 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.25)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHost && trtc != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniControl(
                      icon: trtc!.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      label: 'Mik',
                      onTap: () => trtc!.setMicEnabled(!trtc!.micOn),
                    ),
                    _MiniControl(
                      icon: trtc!.cameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: 'Kam',
                      onTap: onToggleCamera,
                    ),
                    _MiniControl(
                      icon: Icons.cameraswitch_rounded,
                      label: 'Çevir',
                      onTap: trtc!.switchCamera,
                    ),
                    if (onEnd != null)
                      _MiniControl(
                        icon: Icons.stop_circle_rounded,
                        label: 'Bitir',
                        color: AppColors.liveRed,
                        onTap: onEnd,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.white70),
                  ),
                  Expanded(
                    child: TextField(
                      controller: chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz…',
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
                          color: AppColors.coinGold),
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
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.glowShadow(AppColors.accentPink),
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
