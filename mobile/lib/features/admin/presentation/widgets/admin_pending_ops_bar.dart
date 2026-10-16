import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../domain/admin_pending_counts.dart';
import '../providers/admin_pending_counts_provider.dart';
import '../navigation/admin_nav.dart';

/// PR #40 — yatay bekleyen iş şeridi (`GET /api/admin/pending-counts`).
class AdminPendingOpsBar extends ConsumerWidget {
  const AdminPendingOpsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPendingCountsProvider);
    return async.when(
      data: (counts) {
        final chips = _chips(context, counts);
        if (chips.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bekleyen işler',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: chips,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<Widget> _chips(BuildContext context, AdminPendingCounts counts) {
    final items = <({String label, int n, String route, Color color})>[
      if (counts.pendingPayments > 0)
        (
          label: 'Jeton Talepleri',
          n: counts.pendingPayments,
          route: '/admin',
          color: AppThemeColors.liveRed,
        ),
      if (counts.cfcPaymentRequests > 0)
        (
          label: 'CFC Talepleri',
          n: counts.cfcPaymentRequests,
          route: '/admin',
          color: AppThemeColors.diamondBlue,
        ),
      if (counts.pendingWithdrawals > 0)
        (
          label: 'Para Çekme',
          n: counts.pendingWithdrawals,
          route: adminWebRoute('/admin/withdrawals', 'Çekim & Ödüller'),
          color: AppThemeColors.accentCyan,
        ),
      if (counts.pendingReports > 0)
        (
          label: 'Şikayetler',
          n: counts.pendingReports,
          route: '/admin/complaints',
          color: AppThemeColors.accentPink,
        ),
      if (counts.pendingVerifications > 0)
        (
          label: 'Doğrulama',
          n: counts.pendingVerifications,
          route: adminWebRoute('/admin/verification', 'Doğrulama Talepleri'),
          color: AppThemeColors.accentPurple,
        ),
      if (counts.pendingTellerApplications > 0)
        (
          label: 'Falcı Başvuru',
          n: counts.pendingTellerApplications,
          route: adminWebRoute('/admin/live-tellers', 'Canlı Falcı Yönetimi'),
          color: AppThemeColors.coinGold,
        ),
      if (counts.pendingAgencyApplications > 0)
        (
          label: 'Ajans Başvuru',
          n: counts.pendingAgencyApplications,
          route: adminWebRoute('/admin/ajanslar', 'Ajans Listesi'),
          color: const Color(0xFF10B981),
        ),
    ];
    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        _PendingChip(item: items[i], onTap: () => context.push(items[i].route)),
      ],
    ];
  }
}

class _PendingChip extends StatelessWidget {
  const _PendingChip({required this.item, required this.onTap});

  final ({String label, int n, String route, Color color}) item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.14),
          border: Border.all(color: item.color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.n}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
