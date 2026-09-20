import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_activity_monitoring_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin activity monitoring — suspicious user behaviors & moderation actions.
class AdminActivityMonitoringPage extends ConsumerStatefulWidget {
  const AdminActivityMonitoringPage({super.key});

  @override
  ConsumerState<AdminActivityMonitoringPage> createState() =>
      _AdminActivityMonitoringPageState();
}

class _AdminActivityMonitoringPageState
    extends ConsumerState<AdminActivityMonitoringPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminSuspiciousActivityProvider);
    ref.invalidate(adminWarnedUsersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canModerate) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Activity monitoring yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final suspiciousAsync = ref.watch(adminSuspiciousActivityProvider);
    final warnedAsync = ref.watch(adminWarnedUsersProvider);
    final suspiciousCount = ref.watch(adminSuspiciousActivityCountProvider);
    final warnedCount = ref.watch(adminWarnedUsersCountProvider);

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
                      title: 'Activity Monitoring',
                      subtitle: 'Suspicious behavior & moderation',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TabBar(
                controller: _tabs,
                indicatorColor: AppThemeColors.accentPink,
                labelColor: Colors.white,
                unselectedLabelColor: context.colors.onSurfaceMuted,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Suspicious'),
                        if (suspiciousCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.liveRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$suspiciousCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Uyarılı/Yasak'),
                        if (warnedCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.accentCyan,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$warnedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SuspiciousActivityTab(
                    activitiesAsync: suspiciousAsync,
                    onRefresh: _refresh,
                  ),
                  _WarnedUsersTab(
                    usersAsync: warnedAsync,
                    onRefresh: _refresh,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuspiciousActivityTab extends StatelessWidget {
  const _SuspiciousActivityTab({
    required this.activitiesAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> activitiesAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.shield_rounded,
              message: 'Suspicious activity yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: activities.length,
            itemBuilder: (context, i) {
              final activity = activities[i];
              return _SuspiciousActivityCard(activity: activity);
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
          message: 'Activity yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _WarnedUsersTab extends StatelessWidget {
  const _WarnedUsersTab({
    required this.usersAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> usersAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return usersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.done_all_rounded,
              message: 'Uyarılı/yasak kullanıcı yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return _WarnedUserCard(user: user);
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
          message: 'Kullanıcı yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _SuspiciousActivityCard extends StatelessWidget {
  const _SuspiciousActivityCard({required this.activity});

  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final username = activity['username'] as String?;
    final activityType = activity['type'] as String?;
    final severity = activity['severity'] as String? ?? 'medium';
    final details = activity['details'] as String?;
    final createdAt = activity['created_at'] as String?;
    final reviewed = activity['reviewed'] as bool? ?? false;

    final type = parseSuspiciousType(activityType);
    final severityColor = severity == 'high'
        ? AppThemeColors.liveRed
        : severity == 'medium'
            ? AppThemeColors.accentPink
            : AppThemeColors.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reviewed
            ? context.colors.surfaceContainer.withValues(alpha: 0.5)
            : context.colors.surfaceContainer,
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: severityColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      activityTypeLabel(type),
                      style: TextStyle(
                        fontSize: 11,
                        color: severityColor,
                        fontWeight: FontWeight.w600,
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
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (createdAt != null)
                Text(
                  createdAt.substring(0, 10),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
              if (reviewed)
                Chip(
                  label: const Text('Gözden geçirildi'),
                  labelStyle: const TextStyle(fontSize: 9),
                  backgroundColor: AppThemeColors.accentCyan.withValues(alpha: 0.2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarnedUserCard extends StatelessWidget {
  const _WarnedUserCard({required this.user});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final username = user['username'] as String?;
    final status = user['status'] as String? ?? 'warned';
    final reason = user['moderation_reason'] as String?;
    final warningsCount = user['warnings_count'] as int? ?? 0;
    final moderatedAt = user['moderated_at'] as String?;

    final isLocked = status == 'banned';
    final color = isLocked ? AppThemeColors.liveRed : AppThemeColors.accentPink;

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
                isLocked ? Icons.block_rounded : Icons.info_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  username ?? 'Bilinmiyor',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: context.colors.onSurface,
                  ),
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
                  isLocked ? 'YASAKLI' : 'UYARILI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Neden: $reason',
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (warningsCount > 0)
                Chip(
                  label: Text('$warningsCount uyarı'),
                  labelStyle: const TextStyle(fontSize: 9),
                  backgroundColor:
                      AppThemeColors.accentPink.withValues(alpha: 0.2),
                ),
              if (moderatedAt != null)
                Text(
                  moderatedAt.substring(0, 10),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
