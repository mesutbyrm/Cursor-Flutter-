import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_activity_log_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin activity log — audit trail of who did what and when.
class AdminActivityLogPage extends ConsumerStatefulWidget {
  const AdminActivityLogPage({super.key});

  @override
  ConsumerState<AdminActivityLogPage> createState() =>
      _AdminActivityLogPageState();
}

class _AdminActivityLogPageState extends ConsumerState<AdminActivityLogPage> {
  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canViewActivityLog) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Aktivite günlüğü görüntüleme yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final logsAsync = ref.watch(adminActivityLogProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: DiscoverTabHeader(
                      title: 'Activity Log',
                      subtitle: 'Audit trail & action history',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      ref.invalidate(adminActivityLogProvider);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.history_rounded,
                        message: 'Aktivite günlüğü boş.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppThemeColors.accentPink,
                    onRefresh: () async {
                      ref.invalidate(adminActivityLogProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      itemCount: logs.length,
                      itemBuilder: (context, i) {
                        final log = logs[i];
                        return _ActivityLogCard(log: log);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: 'Günlük yüklenemedi',
                    actionLabel: 'Tekrar Dene',
                    action: () {
                      ref.invalidate(adminActivityLogProvider);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final adminName = log['admin_name'] as String?;
    final adminEmail = log['admin_email'] as String?;
    final activityType = log['activity_type'] as String?;
    final targetUser = log['target_user'] as String?;
    final details = log['details'] as String?;
    final createdAt = log['created_at'] as String?;

    final type = parseAdminActivityType(activityType);
    final typeLabel = adminActivityTypeLabel(type);

    final color = _getActivityColor(type, context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getActivityIcon(type),
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    if (adminEmail != null)
                      Text(
                        adminEmail,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (targetUser != null) ...[
            const SizedBox(height: 8),
            Text(
              'Hedef: $targetUser',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurface,
              ),
            ),
          ],
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurface,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (createdAt != null)
            Text(
              createdAt,
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurfaceMuted,
              ),
            ),
        ],
      ),
    );
  }

  Color _getActivityColor(AdminActivityType type, BuildContext context) {
    switch (type) {
      case AdminActivityType.userBanned:
      case AdminActivityType.paymentRejected:
      case AdminActivityType.reportRejected:
      case AdminActivityType.giftDeleted:
        return AppThemeColors.liveRed;
      case AdminActivityType.userWarned:
      case AdminActivityType.tokenRemoved:
        return AppThemeColors.accentPink;
      case AdminActivityType.userUnbanned:
      case AdminActivityType.reportApproved:
      case AdminActivityType.paymentApproved:
      case AdminActivityType.tokenAdded:
      case AdminActivityType.giftCreated:
      case AdminActivityType.giftEdited:
        return AppThemeColors.accentCyan;
      case AdminActivityType.other:
        return context.colors.onSurfaceMuted;
    }
  }

  IconData _getActivityIcon(AdminActivityType type) {
    switch (type) {
      case AdminActivityType.userWarned:
        return Icons.warning_rounded;
      case AdminActivityType.userBanned:
        return Icons.block_rounded;
      case AdminActivityType.userUnbanned:
        return Icons.check_circle_rounded;
      case AdminActivityType.reportApproved:
        return Icons.done_all_rounded;
      case AdminActivityType.reportRejected:
        return Icons.cancel_rounded;
      case AdminActivityType.paymentApproved:
        return Icons.check_rounded;
      case AdminActivityType.paymentRejected:
        return Icons.close_rounded;
      case AdminActivityType.tokenAdded:
        return Icons.add_circle_rounded;
      case AdminActivityType.tokenRemoved:
        return Icons.remove_circle_rounded;
      case AdminActivityType.giftCreated:
        return Icons.card_giftcard_rounded;
      case AdminActivityType.giftEdited:
        return Icons.edit_rounded;
      case AdminActivityType.giftDeleted:
        return Icons.delete_rounded;
      case AdminActivityType.other:
        return Icons.info_rounded;
    }
  }
}
