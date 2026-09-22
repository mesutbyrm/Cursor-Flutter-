import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/staff_access_provider.dart';

/// Admin kendi profilini görüntüleyen profil sayfasında üstte göster.
/// Profil araçlarına hızlı erişim.
class AdminProfileToolbar extends ConsumerWidget {
  const AdminProfileToolbar({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);

    if (!access.canAccessAdminHome) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemeColors.accentPurple.withValues(alpha: 0.1),
            AppThemeColors.accentCyan.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppThemeColors.accentPink.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppThemeColors.accentPink,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Admin Paneli',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppThemeColors.accentPink,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.payments_rounded,
                  label: 'Ödemeler',
                  onTap: () => context.push('/admin'),
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Kullanıcılar',
                  onTap: () => context.push('/admin/users'),
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () => context.push('/admin/dashboard'),
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  icon: Icons.settings_rounded,
                  label: 'Panel',
                  onTap: () => context.push('/admin/panel'),
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  icon: Icons.apps_rounded,
                  label: 'Tüm araçlar',
                  onTap: () => context.push('/admin/tools'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppThemeColors.accentCyan, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
