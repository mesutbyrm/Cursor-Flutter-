import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../membership/presentation/controllers/membership_controller.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../domain/wallet_balances.dart';
import '../providers/wallet_extended_providers.dart';

class WalletEarningsSection extends ConsumerWidget {
  const WalletEarningsSection({super.key, required this.balances});

  final WalletBalances balances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipInfo = resolveProfileMembership(
      rawMembership: balances.membership,
      daysRemaining: balances.membershipDaysRemaining,
    );
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(membershipInfo, ui.tiers);
    final membershipTeaser = buildMembershipWalletEarningsTeaser(
      info: membershipInfo,
      catalogTier: catalogTier,
      daysRemaining: balances.membershipDaysRemaining,
      expiresAt: balances.membershipExpiresAt,
    );
    final rates = ref.watch(platformCommissionRatesProvider).valueOrNull;
    final minWithdraw = rates?.minWithdrawalTl ??
        (balances.withdrawalLimit > 0 ? balances.withdrawalLimit.toDouble() : null);
    final rate = rates?.jetonTlRate ?? balances.jetonTlRate;
    final earnedTl = balances.jetonToTl(balances.totalEarnedJeton ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kazanç Özeti',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (membershipTeaser.isNotEmpty) ...[
          _MembershipEarningsTeaser(
            text: membershipTeaser,
            highlight: membershipInfo.hasActiveSubscription,
            onTap: () => context.push('/premium-membership'),
          ),
          const SizedBox(height: 10),
        ],
        _StatGrid(
          items: [
            _StatItem(
              label: 'Toplam Kazanılan',
              value: '${balances.totalEarnedJeton ?? 0} Jeton',
              hint: earnedTl != null ? balances.formatTl(earnedTl) : null,
            ),
            _StatItem(
              label: 'Bekleyen Kazanç',
              value: balances.formatTl(balances.pendingEarningsTl),
            ),
            _StatItem(
              label: 'Onaylanan Kazanç',
              value: balances.formatTl(balances.approvedEarningsTl),
            ),
            _StatItem(
              label: 'Çekilebilir Bakiye',
              value: balances.formatTl(balances.withdrawableTl),
            ),
            _StatItem(
              label: 'Bugünkü Kazanç',
              value: balances.formatTl(balances.todayEarningsTl),
            ),
            _StatItem(
              label: 'Bu Ay Kazanılan',
              value: balances.formatTl(balances.monthEarningsTl),
            ),
            _StatItem(
              label: 'Toplam Gönderilen',
              value: '${balances.totalSentJeton ?? 0} Jeton',
            ),
            _StatItem(
              label: 'Toplam Alınan',
              value: '${balances.totalReceivedJeton ?? 0} Jeton',
            ),
          ],
        ),
        if (rate != null) ...[
          const SizedBox(height: 8),
          Text(
            '1 Jeton ≈ ${rate.toStringAsFixed(2)} TL (sunucu oranı)',
            style: TextStyle(
              fontSize: 11,
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
        if (minWithdraw != null) ...[
          const SizedBox(height: 4),
          Text(
            'Minimum çekim: ${minWithdraw.toStringAsFixed(0)} TL',
            style: TextStyle(
              fontSize: 11,
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _MembershipEarningsTeaser extends StatelessWidget {
  const _MembershipEarningsTeaser({
    required this.text,
    required this.onTap,
    this.highlight = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: highlight ? 0.08 : 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                highlight
                    ? Icons.workspace_premium_rounded
                    : Icons.card_membership_outlined,
                size: 20,
                color: highlight
                    ? const Color(0xFFFFD54F)
                    : context.colors.onSurfaceMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface.withValues(
                      alpha: highlight ? 0.92 : 0.78,
                    ),
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.colors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (e) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 56) / 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    if (e.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        e.hint!,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    this.hint,
  });

  final String label;
  final String value;
  final String? hint;
}
