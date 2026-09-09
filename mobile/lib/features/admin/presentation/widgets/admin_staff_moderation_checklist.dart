import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_providers.dart';
import '../providers/staff_access_provider.dart';

/// Günlük moderasyon / admin görev checklist (dashboard KPI).
class AdminStaffModerationChecklist extends ConsumerWidget {
  const AdminStaffModerationChecklist({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isStaffMember) return const SizedBox.shrink();

    final stats = ref.watch(adminDashboardStatsProvider).valueOrNull ??
        const AdminDashboardStats();
    final activities = ref.watch(adminRecentActivitiesProvider).valueOrNull ?? [];

    final openReports = activities.where((a) {
      final type =
          (a['activityType'] ?? a['type'] ?? '').toString().toLowerCase();
      return type.contains('report') && !type.contains('resolved');
    }).length;

    final tasks = <_Task>[
      if (access.canManagePayments)
        _Task(
          label: 'Bekleyen ödeme',
          count: stats.pendingPayments,
          urgent: stats.pendingPayments > 0,
          route: '/admin',
          icon: Icons.payments_outlined,
        ),
      if (access.canModerate || access.canViewReports)
        _Task(
          label: 'Açık rapor (aktivite)',
          count: openReports,
          urgent: openReports > 0,
          route: '/admin/reports',
          icon: Icons.flag_outlined,
        ),
      if (access.canManageVoiceRooms)
        _Task(
          label: 'Aktif sesli oda',
          count: stats.activeVoiceRooms,
          urgent: false,
          route: '/admin/voice-rooms',
          icon: Icons.meeting_room_outlined,
        ),
      if (access.canManageLiveStreams)
        _Task(
          label: 'Aktif yayın',
          count: stats.activeLiveStreams,
          urgent: false,
          route: '/admin/live-streams',
          icon: Icons.live_tv_outlined,
        ),
      if (access.canManagePayments && stats.pendingWithdrawals > 0)
        _Task(
          label: 'Bekleyen çekim',
          count: stats.pendingWithdrawals,
          urgent: true,
          route: '/admin',
          icon: Icons.account_balance_outlined,
        ),
    ];

    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Günlük görevler',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push(t.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        t.icon,
                        size: 18,
                        color: t.urgent
                            ? AppThemeColors.liveRed
                            : AppThemeColors.accentCyan,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (t.count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: t.urgent
                                ? AppThemeColors.liveRed.withValues(alpha: 0.2)
                                : AppThemeColors.accentPink
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${t.count}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: t.urgent
                                  ? AppThemeColors.liveRed
                                  : AppThemeColors.accentPink,
                            ),
                          ),
                        ),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Task {
  const _Task({
    required this.label,
    required this.count,
    required this.urgent,
    required this.route,
    required this.icon,
  });

  final String label;
  final int count;
  final bool urgent;
  final String route;
  final IconData icon;
}
