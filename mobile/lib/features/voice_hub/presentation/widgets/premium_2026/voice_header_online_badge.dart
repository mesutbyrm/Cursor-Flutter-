import 'package:flutter/material.dart';

import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../theme/voice_room_tokens.dart';

/// AppBar — jeton yanında canlı çevrimiçi sayısı (premium yuvarlak rozet).
class VoiceHeaderOnlineBadge extends StatelessWidget {
  const VoiceHeaderOnlineBadge({
    super.key,
    required this.count,
    this.onTap,
  });

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final live = count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: live
              ? LinearGradient(
                  colors: [
                    VoiceRoomTokens.neonPurple.withValues(alpha: 0.95),
                    AppThemeColors.diamondBlue.withValues(alpha: 0.85),
                  ],
                )
              : null,
          color: live ? null : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: live
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white24,
            width: 1.2,
          ),
          boxShadow: live
              ? VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple, blur: 10)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 14,
              color: live ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: live ? Colors.white : Colors.white70,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
