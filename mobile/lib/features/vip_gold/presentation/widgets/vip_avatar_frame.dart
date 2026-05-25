import 'package:flutter/material.dart';

import '../../domain/vip_tier.dart';
import '../theme/vip_gold_tokens.dart';
import 'vip_badge.dart';

/// Premium avatar çerçevesi — altın / elmas halka.
class VipAvatarFrame extends StatelessWidget {
  const VipAvatarFrame({
    super.key,
    required this.child,
    required this.tier,
    this.size = 72,
    this.showBadge = true,
  });

  final Widget child;
  final VipTier tier;
  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    if (!tier.hasPremiumFrame) return child;

    final gradient = switch (tier) {
      VipTier.svip => const SweepGradient(
          colors: [
            VipGoldTokens.svipPurple,
            VipGoldTokens.goldMid,
            VipGoldTokens.diamondBlue,
            VipGoldTokens.svipPurple,
          ],
        ),
      VipTier.diamond => const LinearGradient(
          colors: [VipGoldTokens.diamondBlue, Color(0xFF00D2FF)],
        ),
      VipTier.gold => VipGoldTokens.goldLuxury,
      _ => const LinearGradient(
          colors: [Color(0xFFB832FF), Color(0xFF6B2DFF)],
        ),
    };

    return SizedBox(
      width: size,
      height: size + (showBadge && tier.isVip ? 10 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: VipGoldTokens.goldGlow(blur: tier.isVip ? 18 : 10),
            ),
            child: ClipOval(child: child),
          ),
          if (showBadge && tier.badgeShort.isNotEmpty)
            Positioned(
              bottom: 0,
              child: VipBadge(tier: tier, compact: true, animate: tier.isVip),
            ),
        ],
      ),
    );
  }
}
