import 'package:flutter/material.dart';

import '../../domain/vip_privilege.dart';
import '../../domain/vip_tier.dart';
import '../theme/vip_gold_tokens.dart';
import 'vip_luxury_card.dart';

/// 3x2 ayrıcalık grid — SVIP tarzı.
class VipPrivilegeGrid extends StatelessWidget {
  const VipPrivilegeGrid({super.key, required this.tier});

  final VipTier tier;

  @override
  Widget build(BuildContext context) {
    final perks = VipPrivilegeCatalog.forTier(tier);
    final unlocked = perks.where((p) => p.unlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Ayrıcalıklar',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const Spacer(),
            Text(
              '$unlocked/${perks.length} açık',
              style: TextStyle(
                fontSize: 12,
                color: VipGoldTokens.goldMid.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: perks.length,
          itemBuilder: (ctx, i) {
            final p = perks[i];
            return VipLuxuryCard(
              padding: const EdgeInsets.all(10),
              highlighted: p.unlocked && tier.isVip,
              child: Opacity(
                opacity: p.unlocked ? 1 : 0.45,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      p.icon,
                      color: p.unlocked
                          ? VipGoldTokens.goldMid
                          : Colors.white38,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!p.unlocked)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.lock_rounded, size: 12, color: Colors.white38),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
