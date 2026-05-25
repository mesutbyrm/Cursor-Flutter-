import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';

/// Sağ dikey aksiyon şeridi — beğeni, hediye, paylaş.
class LivePremiumSideRail extends StatelessWidget {
  const LivePremiumSideRail({
    super.key,
    required this.likeLabel,
    required this.giftLabel,
    required this.shareLabel,
    required this.onLike,
    required this.onGift,
    this.onShare,
    this.onReport,
  });

  final String likeLabel;
  final String giftLabel;
  final String shareLabel;
  final VoidCallback onLike;
  final VoidCallback onGift;
  final VoidCallback? onShare;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailButton(
          icon: Icons.favorite_rounded,
          label: likeLabel,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2D7A), Color(0xFFB832FF)],
          ),
          glow: AppColors.accentPink,
          onTap: onLike,
        ),
        const SizedBox(height: 14),
        _RailButton(
          icon: Icons.card_giftcard_rounded,
          label: giftLabel,
          gradient: AppColors.coinCapsuleGradient,
          glow: AppColors.coinGold,
          onTap: onGift,
        ),
        const SizedBox(height: 14),
        _RailButton(
          icon: Icons.share_rounded,
          label: shareLabel,
          iconColor: Colors.white,
          onTap: onShare,
        ),
        if (onReport != null) ...[
          const SizedBox(height: 14),
          _RailButton(
            icon: Icons.flag_outlined,
            label: 'Bildir',
            iconColor: Colors.white70,
            onTap: onReport,
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 120.ms).slideX(begin: 0.12, end: 0);
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    this.gradient,
    this.glow,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient? gradient;
  final Color? glow;
  final Color? iconColor;
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
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                color: gradient == null ? Colors.black.withValues(alpha: 0.45) : null,
                border: Border.all(
                  color: (glow ?? Colors.white).withValues(alpha: 0.4),
                ),
                boxShadow: glow != null
                    ? AppColors.glowShadow(glow!, blur: 16)
                    : null,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
