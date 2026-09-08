import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../admin/presentation/providers/admin_dashboard_providers.dart';
import '../../../../admin/presentation/providers/admin_providers.dart';
import '../../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../widgets/premium/profile_glass.dart';
import '../profile_theme.dart';
import 'profile_action_tile.dart';
import 'staff_role_preview_card.dart';

/// Yetkili kullanıcı girişi — rol bazlı menü (admin panelinden ayrı).
class StaffProfileCard extends ConsumerWidget {
  const StaffProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.showStaffProfileEntry) return const SizedBox.shrink();

    final pending = ref.watch(adminPendingPaymentsCountProvider);
    final roomsAsync = ref.watch(voiceRoomsListNotifierProvider);
    final streamsAsync = ref.watch(liveStreamsListNotifierProvider);
    final staffActs = ref.watch(staffFilteredActivitiesProvider);

    final activeRooms = roomsAsync.valueOrNull?.length ?? 0;
    final activeStreams =
        streamsAsync.valueOrNull?.where((s) => s.isLive).length ?? 0;

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
        _StaffKpiRow(
          pendingPayments: pending,
          activeRooms: activeRooms,
          activeStreams: activeStreams,
        ),
        const SizedBox(height: 10),
        const StaffRolePreviewCard(),
        const SizedBox(height: 10),
        staffActs.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (rows) {
            if (rows.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ProfileGlass(
                padding: const EdgeInsets.all(12),
                borderRadius: ProfilePremiumTheme.radiusLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son yetkili aktivite',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final row in rows.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _activityLine(row),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
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

  static String _activityLine(Map<String, dynamic> row) {
    final type = (row['activityType'] ?? row['type'] ?? 'aktivite').toString();
    final user = row['user'] is Map
        ? (row['user'] as Map)['username']?.toString()
        : row['username']?.toString();
    if (user != null && user.isNotEmpty) return '@$user · $type';
    return type;
  }
}

class _StaffKpiRow extends StatelessWidget {
  const _StaffKpiRow({
    required this.pendingPayments,
    required this.activeRooms,
    required this.activeStreams,
  });

  final int pendingPayments;
  final int activeRooms;
  final int activeStreams;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            label: 'Bekleyen ödeme',
            value: pendingPayments > 0 ? '$pendingPayments' : '—',
            highlight: pendingPayments > 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            label: 'Aktif oda',
            value: activeRooms > 0 ? '$activeRooms' : '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiTile(
            label: 'Canlı yayın',
            value: activeStreams > 0 ? '$activeStreams' : '—',
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppThemeColors.liveRed.withValues(alpha: 0.5)
              : AppThemeColors.accentCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: highlight ? AppThemeColors.liveRed : Colors.white,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
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
