import 'package:flutter/material.dart';

import '../../domain/vip_privilege.dart';
import '../../domain/vip_tier.dart';
import '../theme/vip_gold_tokens.dart';

/// Ayrıcalık kartına tıklanınca — mevcut ve önceki kademe ayrıcalıkları.
void showVipPrivilegeDetailSheet(
  BuildContext context, {
  required VipPrivilege privilege,
  required VipTier currentTier,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFF12101A),
    builder: (ctx) {
      final unlocked = currentTier.index >= privilege.minTier.index;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    privilege.icon,
                    color: unlocked ? VipGoldTokens.goldMid : Colors.white38,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      privilege.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                privilege.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                unlocked ? 'Aktif ayrıcalık' : 'Kilitli — ${privilege.minTier.label} gerekir',
                style: TextStyle(
                  color: unlocked
                      ? const Color(0xFF4ADE80)
                      : Colors.orange.shade200,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kademe karşılaştırması',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...VipTier.values.map((tier) {
                final tierPerks = VipPrivilegeCatalog.forTier(tier);
                final match = tierPerks.firstWhere(
                  (p) => p.title == privilege.title,
                  orElse: () => privilege,
                );
                final tierHas = tier.index >= privilege.minTier.index;
                final isCurrent = tier == currentTier;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        tierHas ? Icons.check_circle_rounded : Icons.lock_rounded,
                        size: 16,
                        color: tierHas
                            ? VipGoldTokens.goldMid
                            : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tier.label}${isCurrent ? ' (sizin)' : ''}',
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w800 : FontWeight.w500,
                            color: isCurrent
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
