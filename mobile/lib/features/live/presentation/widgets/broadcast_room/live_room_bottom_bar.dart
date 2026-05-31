import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/ui/premium/premium_glass_surface.dart';
import '../../../../trtc/presentation/trtc_room_manager.dart';

class LiveRoomBottomBar extends StatelessWidget {
  const LiveRoomBottomBar({
    super.key,
    required this.chatController,
    required this.onSend,
    required this.onEnd,
    required this.isHost,
    this.trtc,
    this.onGift,
    this.onToggleCamera,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final VoidCallback onEnd;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final VoidCallback? onGift;
  final VoidCallback? onToggleCamera;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassSurface(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
      blur: 14,
      opacity: 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHost && trtc != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                LiveRoomMiniControl(
                  icon: trtc!.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  label: 'Mik',
                  onTap: () => trtc!.setMicEnabled(!trtc!.micOn),
                ),
                LiveRoomMiniControl(
                  icon: trtc!.cameraOn
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  label: 'Kam',
                  onTap: onToggleCamera,
                ),
                LiveRoomMiniControl(
                  icon: Icons.cameraswitch_rounded,
                  label: 'Çevir',
                  onTap: trtc!.switchCamera,
                ),
                const LiveRoomMiniControl(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Efekt',
                ),
              ],
            ),
          if (isHost) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Mesaj yaz...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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
              IconButton.filled(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                ),
              ),
              if (!isHost && onGift != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onGift,
                  child: const LiveRoomActionPill(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Hediye',
                    color: AppColors.accentPurple,
                  ),
                ),
              ],
              if (isHost) ...[
                const SizedBox(width: 6),
                const LiveRoomActionPill(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Hediye',
                  color: AppColors.accentPurple,
                ),
                const SizedBox(width: 6),
                LiveRoomActionPill(
                  icon: Icons.person_add_rounded,
                  label: 'Davet',
                  color: AppColors.accentCyan,
                ),
                const SizedBox(width: 6),
                Material(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onEnd,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        'Bitir',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class LiveRoomMiniControl extends StatelessWidget {
  const LiveRoomMiniControl({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

class LiveRoomActionPill extends StatelessWidget {
  const LiveRoomActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
