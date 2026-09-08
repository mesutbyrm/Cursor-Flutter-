import 'package:flutter/material.dart';

import '../../domain/site_animation_tier.dart';
import '../../../../features/voice_hub/presentation/theme/voice_room_tokens.dart';

/// Lottie yoksa GPU-dostu gradient halka fallback.
class SiteAnimationProfileFrameFallback extends StatelessWidget {
  const SiteAnimationProfileFrameFallback({
    super.key,
    required this.tier,
    required this.size,
  });

  final SiteAnimationTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      SiteAnimationTier.gold => VoiceRoomTokens.gold,
      SiteAnimationTier.diamond => const Color(0xFF00D9D9),
      SiteAnimationTier.vip || SiteAnimationTier.svip => VoiceRoomTokens.neonPurple,
      SiteAnimationTier.admin || SiteAnimationTier.host => const Color(0xFFFFD45A),
      _ => VoiceRoomTokens.neonPurple.withValues(alpha: 0.65),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.85), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
