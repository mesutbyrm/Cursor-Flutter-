import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';
import 'profile_action_tile.dart';

/// Yetkili kullanıcı girişi — rol bazlı menü (admin panelinden ayrı).
class StaffProfileCard extends ConsumerWidget {
  const StaffProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.showStaffProfileEntry) return const SizedBox.shrink();

    final items = <({IconData icon, String label, VoidCallback onTap})>[];

    if (access.canModerate) {
      items.add((
        icon: Icons.gavel_rounded,
        label: 'Moderasyon',
        onTap: () => context.push('/admin/moderation'),
      ));
      items.add((
        icon: Icons.sports_martial_arts_rounded,
        label: 'PK Moderasyon',
        onTap: () => context.push('/pk/moderation'),
      ));
    }
    if (access.canManageVoiceRooms) {
      items.add((
        icon: Icons.meeting_room_rounded,
        label: 'Sesli Odalar',
        onTap: () => context.push('/admin/voice-rooms'),
      ));
    }
    if (access.canManageLiveStreams) {
      items.add((
        icon: Icons.live_tv_rounded,
        label: 'Canlı Yayınlar',
        onTap: () => context.push('/admin/live-streams'),
      ));
    }
    if (access.canViewReports) {
      items.add((
        icon: Icons.analytics_rounded,
        label: 'Raporlar',
        onTap: () => context.push('/admin/reports'),
      ));
    }
    if (access.isSupportStaff) {
      items.add((
        icon: Icons.support_agent_rounded,
        label: 'Destek Merkezi',
        onTap: () => context.push('/profile/help'),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: 'Yetkili Paneli',
          trailing: Text(
            access.roleLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppThemeColors.accentCyan.withValues(alpha: 0.9),
            ),
          ),
        ),
        ProfileGlass(
          padding: const EdgeInsets.all(14),
          borderRadius: ProfilePremiumTheme.radiusLg,
          borderColor: AppThemeColors.accentCyan.withValues(alpha: 0.35),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              const cols = 3;
              final tileW =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              final tileH = tileW / 0.92;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: tileW,
                      height: tileH,
                      child: ProfileActionTile(
                        icon: item.icon,
                        label: item.label,
                        onTap: item.onTap,
                        gradient: [
                          AppThemeColors.accentCyan.withValues(alpha: 0.28),
                          ProfilePremiumTheme.deepBg,
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Lazy wrapper — profil scroll performansı.
class ProfileLazyStaff extends ConsumerWidget {
  const ProfileLazyStaff({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.showStaffProfileEntry) return const SizedBox.shrink();
    return const StaffProfileCard();
  }
}
