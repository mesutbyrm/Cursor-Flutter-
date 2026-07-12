import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../admin/presentation/providers/admin_providers.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import 'profile_glass.dart';

/// Admin / yönetici — site ödeme istekleri ve yönetim paneli.
class ProfileAdminSection extends ConsumerWidget {
  const ProfileAdminSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.showAdminPanel) return const SizedBox.shrink();

    final pending = ref.watch(adminPendingPaymentsCountProvider);

    ref.listen<StaffAccess>(staffAccessProvider, (prev, next) {
      if (next.showAdminPanel && prev?.showAdminPanel != true) {
        ref.invalidate(adminPaymentRequestsProvider);
        ref.invalidate(adminPaymentNotificationsProvider);
        ref.invalidate(adminSitePaymentSettingsProvider);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: 'Yönetim paneli — ${access.roleLabel}',
        ),
        ProfileGlass(
          onTap: () => context.push('/admin/panel'),
          padding: const EdgeInsets.all(16),
          borderColor: AppThemeColors.liveRed.withValues(alpha: 0.4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppThemeColors.liveRed.withValues(alpha: 0.5),
                      AppThemeColors.accentPurple.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Paneli',
                      style: ProfileTypography.cardTitle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ödeme, jeton/CFC, üyelik, kullanıcı yönetimi',
                      style: ProfileTypography.cardSubtitle(context),
                    ),
                  ],
                ),
              ),
              if (pending > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemeColors.liveRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pending > 99 ? '99+' : '$pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        if (access.canManageGifts) ...[
          ProfileGlass(
            onTap: () => context.push('/admin/gifts'),
            padding: const EdgeInsets.all(16),
            borderColor: AppThemeColors.accentPurple.withValues(alpha: 0.4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        AppThemeColors.accentPurple.withValues(alpha: 0.5),
                        AppThemeColors.accentPink.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hediye Yönetimi',
                        style: ProfileTypography.cardTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Katalog, istatistik ve gelir kuralları',
                        style: ProfileTypography.cardSubtitle(context),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          SizedBox(height: 12),
          ProfileGlass(
            onTap: () => context.push('/pk/moderation'),
            padding: const EdgeInsets.all(16),
            borderColor: AppThemeColors.liveRed.withValues(alpha: 0.4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        AppThemeColors.liveRed.withValues(alpha: 0.5),
                        AppThemeColors.accentPurple.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PK Moderasyon',
                        style: ProfileTypography.cardTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yasaklar, zorla bitir / koltuktan çıkar',
                        style: ProfileTypography.cardSubtitle(context),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ],
    );
  }
}
