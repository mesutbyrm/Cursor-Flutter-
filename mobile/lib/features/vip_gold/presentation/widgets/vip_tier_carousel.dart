import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/vip_tier.dart';
import '../theme/vip_gold_tokens.dart';

/// SVIP seviye seçici — yatay chip.
class VipTierCarousel extends StatelessWidget {
  const VipTierCarousel({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final VipTier selected;
  final ValueChanged<VipTier> onSelected;

  static const _tiers = [
    VipTier.gold,
    VipTier.diamond,
    VipTier.svip,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tiers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final t = _tiers[i];
          final active = t == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(t),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: 220.ms,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: active ? VipGoldTokens.goldLuxury : null,
                  color: active ? null : Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: active
                        ? VipGoldTokens.goldLight
                        : Colors.white24,
                  ),
                  boxShadow: active ? VipGoldTokens.goldGlow(blur: 12) : null,
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: active ? Colors.black87 : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
