import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/topup_bonus_tier.dart';
import '../providers/economy_providers.dart';

/// Yükleme bonus kademeleri — bilgilendirme amaçlı (backend hesaplar).
class TopupBonusInfoBanner extends ConsumerWidget {
  const TopupBonusInfoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(topupBonusTiersProvider);
    if (tiers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF5B21B6).withValues(alpha: 0.18),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: Color(0xFFC4B5FD)),
              SizedBox(width: 8),
              Text(
                'Yükleme bonusu kademeleri',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bonus tutarı sunucuda otomatik hesaplanır. Aşağıdaki kademeler bilgilendirme içindir.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...tiers.map((tier) => _TierRow(tier: tier)),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier});

  final TopupBonusTier tier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tier.displayLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ),
          Text(
            '%${tier.bonusPercent.toStringAsFixed(0)} bonus',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Color(0xFFC4B5FD),
            ),
          ),
        ],
      ),
    );
  }
}
