import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../gifts/widgets/live_gift_panel.dart';

class LiveRoomSideActions extends StatelessWidget {
  const LiveRoomSideActions({
    super.key,
    required this.likes,
    required this.gifts,
    required this.shares,
    this.onGift,
    this.onReport,
  });

  final String likes;
  final String gifts;
  final String shares;
  final VoidCallback? onGift;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LiveRoomSideButton(icon: Icons.favorite_rounded, label: likes),
        const SizedBox(height: 12),
        if (onGift != null)
          LiveGiftSideButton(onTap: onGift!)
        else
          LiveRoomSideButton(icon: Icons.card_giftcard_rounded, label: gifts),
        const SizedBox(height: 12),
        LiveRoomSideButton(icon: Icons.share_rounded, label: shares),
        const SizedBox(height: 12),
        const LiveRoomSideButton(icon: Icons.person_rounded, label: 'Profil'),
        if (onReport != null) ...[
          const SizedBox(height: 12),
          LiveRoomSideButton(
            icon: Icons.flag_outlined,
            label: 'Bildir',
            onTap: onReport,
          ),
        ],
      ],
    );
  }
}

class LiveRoomSideButton extends StatelessWidget {
  const LiveRoomSideButton({
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
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
