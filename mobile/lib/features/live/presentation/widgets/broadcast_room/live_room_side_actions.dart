import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../gifts/widgets/live_gift_panel.dart';

class LiveRoomSideActions extends StatelessWidget {
  const LiveRoomSideActions({
    super.key,
    required this.likes,
    required this.gifts,
    required this.shares,
    this.onGift,
  });

  final String likes;
  final String gifts;
  final String shares;
  final VoidCallback? onGift;

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
      ],
    );
  }
}

class LiveRoomSideButton extends StatelessWidget {
  const LiveRoomSideButton({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(
              color: AppColors.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
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
