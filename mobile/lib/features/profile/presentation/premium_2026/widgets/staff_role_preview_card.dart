import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';

/// Yetkili rol önizleme — StaffAccess bayrakları (salt okunur).
class StaffRolePreviewCard extends ConsumerWidget {
  const StaffRolePreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isStaffMember) return const SizedBox.shrink();

    final flags = <({String label, bool on})>[
      (label: 'Moderasyon', on: access.canModerate),
      (label: 'Sesli oda', on: access.canManageVoiceRooms),
      (label: 'Canlı yayın', on: access.canManageLiveStreams),
      (label: 'Kullanıcılar', on: access.canManageUsers),
      (label: 'Raporlar', on: access.canViewReports),
      (label: 'Finans', on: access.canManagePayments),
      (label: 'Hediyeler', on: access.canManageGifts),
      (label: 'Destek', on: access.isSupportStaff),
    ];

    return ProfileGlass(
      padding: const EdgeInsets.all(12),
      borderRadius: ProfilePremiumTheme.radiusLg,
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rol önizleme',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in flags)
                _FlagChip(label: f.label, enabled: f.on),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color =
        enabled ? AppThemeColors.accentCyan : Colors.white.withValues(alpha: 0.25);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: enabled
            ? AppThemeColors.accentCyan.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
