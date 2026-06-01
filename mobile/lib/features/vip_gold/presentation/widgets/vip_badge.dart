import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/vip_tier.dart';
import '../theme/vip_gold_tokens.dart';

/// VIP / Gold / SVIP rozeti.
class VipBadge extends StatelessWidget {
  const VipBadge({
    super.key,
    required this.tier,
    this.compact = false,
    this.animate = false,
  });

  final VipTier tier;
  final bool compact;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (tier == VipTier.basic || tier.badgeShort.isEmpty) {
      return const SizedBox.shrink();
    }

    final gradient = _gradientFor(tier);
    Widget chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        boxShadow: VipGoldTokens.goldGlow(blur: compact ? 6 : 10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(_iconFor(tier), size: 12, color: _textColor(tier)),
            const SizedBox(width: 4),
          ],
          Text(
            tier.badgeShort,
            style: TextStyle(
              fontSize: compact ? 7 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              color: _textColor(tier),
            ),
          ),
        ],
      ),
    );

    if (animate) {
      chip = chip
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1800.ms, color: Colors.white24);
    }
    return chip;
  }

  static LinearGradient _gradientFor(VipTier t) => switch (t) {
        VipTier.svip => const LinearGradient(
            colors: [VipGoldTokens.svipPurple, Color(0xFFFF2D7A)],
          ),
        VipTier.diamond => const LinearGradient(
            colors: [VipGoldTokens.diamondBlue, Color(0xFF00D2FF)],
          ),
        VipTier.gold => VipGoldTokens.goldLuxury,
        VipTier.premium => const LinearGradient(
            colors: [Color(0xFFB832FF), Color(0xFF6B2DFF)],
          ),
        _ => const LinearGradient(colors: [Colors.grey, Colors.grey]),
      };

  static Color _textColor(VipTier t) => switch (t) {
        VipTier.gold || VipTier.premium => Colors.black87,
        _ => Colors.white,
      };

  static IconData _iconFor(VipTier t) => switch (t) {
        VipTier.svip => Icons.diamond_rounded,
        VipTier.diamond => Icons.auto_awesome_rounded,
        VipTier.gold => Icons.workspace_premium_rounded,
        VipTier.premium => Icons.star_rounded,
        _ => Icons.person,
      };
}
