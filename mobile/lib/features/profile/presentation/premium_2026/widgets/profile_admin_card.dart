import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../admin/presentation/providers/admin_providers.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../providers/profile_providers.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';
import 'profile_action_tile.dart';

/// Admin paneli — yalnızca yetkili kullanıcılarda.
class ProfileAdminCard extends ConsumerWidget {
  const ProfileAdminCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments) return const SizedBox.shrink();

    final pending = ref.watch(adminPendingPaymentsCountProvider);

    ref.listen<StaffAccess>(staffAccessProvider, (prev, next) {
      if (next.canManagePayments && prev?.canManagePayments != true) {
        ref.invalidate(adminPaymentRequestsProvider);
        ref.invalidate(adminPaymentNotificationsProvider);
        ref.invalidate(adminSitePaymentSettingsProvider);
      }
    });

    final items = <({IconData icon, String label, VoidCallback onTap, int badge})>[
      (
        icon: Icons.dashboard_customize_rounded,
        label: 'Admin Paneli',
        badge: pending,
        onTap: () => context.push('/admin/panel'),
      ),
      (
        icon: Icons.payments_rounded,
        label: 'Ödeme İstekleri',
        badge: pending,
        onTap: () => context.push('/admin'),
      ),
      (
        icon: Icons.people_alt_rounded,
        label: 'Kullanıcı Yönetimi',
        badge: 0,
        onTap: () => context.push('/admin/users'),
      ),
      (
        icon: Icons.live_tv_rounded,
        label: 'Yayın Yönetimi',
        badge: 0,
        onTap: () => context.go('/live'),
      ),
      (
        icon: Icons.business_rounded,
        label: 'Ajans Yönetimi',
        badge: 0,
        onTap: () => context.push('/ajans/dashboard'),
      ),
      (
        icon: Icons.analytics_rounded,
        label: 'Raporlar',
        badge: 0,
        onTap: () => context.push('/admin/reports'),
      ),
      (
        icon: Icons.support_agent_rounded,
        label: 'Destek Talepleri',
        badge: 0,
        onTap: () => context.push('/profile/help'),
      ),
      (
        icon: Icons.gavel_rounded,
        label: 'Moderasyon',
        badge: 0,
        onTap: () => context.push('/admin/moderation'),
      ),
    ];

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            title: 'Yönetim Paneli — ${access.roleLabel}',
            trailing: pending > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppThemeColors.liveRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      pending > 99 ? '99+' : '$pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : null,
          ),
          ProfileGlass(
            padding: const EdgeInsets.all(14),
            borderRadius: ProfilePremiumTheme.radiusLg,
            borderColor: AppThemeColors.liveRed.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ProfileActionTile(
                      icon: item.icon,
                      label: item.label,
                      onTap: item.onTap,
                      gradient: [
                        AppThemeColors.liveRed.withValues(alpha: 0.35),
                        ProfilePremiumTheme.deepBg,
                      ],
                      badge: item.badge > 0 ? item.badge : null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                const _ProfileAdminPaymentQueue(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAdminPaymentQueue extends ConsumerWidget {
  const _ProfileAdminPaymentQueue();

  Future<void> _review(
    WidgetRef ref,
    BuildContext context,
    String requestId,
    String action,
  ) async {
    try {
      await ref.read(dioProvider).safePatch<dynamic>(
        ApiEndpoints.adminCfcPaymentPatch,
        data: {
          'requestId': requestId,
          'action': action,
          if (action == 'approve') 'reviewNote': 'Onaylandı',
          if (action == 'reject') 'reviewNote': 'Reddedildi',
        },
      );
      ref.invalidate(adminPaymentRequestsProvider);
      ref.invalidate(adminPaymentNotificationsProvider);
      ref.refreshWalletCache(force: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approve' ? 'Ödeme onaylandı' : 'Ödeme reddedildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(adminPaymentRequestsProvider);
    return pending.when(
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) {
          return Text(
            'Bekleyen ödeme talebi yok.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          );
        }
        final top = rows.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bekleyen ödeme talepleri (${rows.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            for (final r in top) ...[
              Text(
                paymentRequestDetailLine(r),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _review(
                        ref,
                        context,
                        r['id']?.toString() ?? '',
                        'reject',
                      ),
                      child: const Text('Reddet'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _review(
                        ref,
                        context,
                        r['id']?.toString() ?? '',
                        'approve',
                      ),
                      child: const Text('Onayla'),
                    ),
                  ),
                ],
              ),
              if (r != top.last) const SizedBox(height: 10),
            ],
            if (rows.length > 3)
              TextButton(
                onPressed: () => context.push('/admin'),
                child: const Text('Tüm ödeme talepleri'),
              ),
          ],
        );
      },
    );
  }
}
