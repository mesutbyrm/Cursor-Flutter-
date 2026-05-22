import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/auth/staff_roles.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../admin/presentation/providers/admin_providers.dart';
import 'profile_glass.dart';

class ProfileAdminSection extends ConsumerWidget {
  const ProfileAdminSection({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!StaffRoles.isStaff(role)) return const SizedBox.shrink();

    final pending = ref.watch(adminPendingPaymentsCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: 'Admin — ${StaffRoles.labelTr(role)}',
        ),
        ProfileGlass(
          onTap: () => context.push('/admin'),
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.liveRed.withValues(alpha: 0.4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.liveRed.withValues(alpha: 0.5),
                      AppColors.accentPurple.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yönetim paneli',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ödeme talepleri, bildirimler, site ayarları',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
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
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
