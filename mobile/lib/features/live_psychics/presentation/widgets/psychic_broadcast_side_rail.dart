import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

/// Canlı yayın sağ şerit — izleyici, hediye, fal iste, rumuz, ses, çık.
class PsychicBroadcastSideRail extends StatelessWidget {
  const PsychicBroadcastSideRail({
    super.key,
    required this.viewerCount,
    required this.onGift,
    required this.onFortuneRequest,
    this.showFortuneRequest = true,
    this.onViewersTap,
    this.onNickname,
    this.onToggleAudio,
    this.onExit,
    this.audioOn = true,
  });

  final int viewerCount;
  final VoidCallback onGift;
  final VoidCallback onFortuneRequest;
  final bool showFortuneRequest;
  final VoidCallback? onViewersTap;
  final VoidCallback? onNickname;
  final VoidCallback? onToggleAudio;
  final VoidCallback? onExit;
  final bool audioOn;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailBtn(
          icon: Icons.people_alt_rounded,
          label: '$viewerCount',
          gradient: const [Color(0xFF7C4DFF), Color(0xFF536DFE)],
          onTap: onViewersTap,
        ),
        const SizedBox(height: 12),
        _RailBtn(
          icon: Icons.card_giftcard_rounded,
          label: 'Hediye',
          gradient: const [Color(0xFFFF9800), Color(0xFFFFB300)],
          onTap: onGift,
        ),
        if (showFortuneRequest) ...[
          const SizedBox(height: 12),
          _RailBtn(
            icon: Icons.coffee_rounded,
            label: 'Fal İste',
            gradient: const [Color(0xFF8D6E63), Color(0xFFA1887F)],
            onTap: onFortuneRequest,
          ),
        ],
        const SizedBox(height: 12),
        _RailBtn(
          icon: Icons.person_outline_rounded,
          label: 'Rumuz',
          gradient: const [Color(0xFF2196F3), Color(0xFF42A5F5)],
          onTap: onNickname,
        ),
        const SizedBox(height: 12),
        _RailBtn(
          icon: audioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: 'Ses',
          gradient: const [Color(0xFF00C853), Color(0xFF00E676)],
          onTap: onToggleAudio,
        ),
        const SizedBox(height: 12),
        _RailBtn(
          icon: Icons.logout_rounded,
          label: 'Çık',
          iconColor: Colors.white70,
          onTap: onExit,
        ),
      ],
    );
  }
}

class _RailBtn extends StatelessWidget {
  const _RailBtn({
    required this.icon,
    required this.label,
    this.gradient,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color>? gradient;
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient != null
                    ? LinearGradient(colors: gradient!)
                    : null,
                color: gradient == null
                    ? Colors.black.withValues(alpha: 0.45)
                    : null,
                border: Border.all(
                  color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
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
