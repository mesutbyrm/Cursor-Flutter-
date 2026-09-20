import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_team_management_providers.dart';
import '../providers/staff_access_provider.dart';

/// Takım yönetimi - admin rolleri ve izinleri.
class AdminTeamManagementPage extends ConsumerStatefulWidget {
  const AdminTeamManagementPage({super.key});

  @override
  ConsumerState<AdminTeamManagementPage> createState() =>
      _AdminTeamManagementPageState();
}

class _AdminTeamManagementPageState
    extends ConsumerState<AdminTeamManagementPage>
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
    ref.invalidate(adminTeamMembersProvider);
    ref.invalidate(adminTeamActivityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.isFounder) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Takım yönetimi yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final membersAsync = ref.watch(adminTeamMembersProvider);
    final activityAsync = ref.watch(adminTeamActivityProvider);

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
                      title: 'Takım Yönetimi',
                      subtitle: 'Admin rolleri ve izinleri',
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
                tabs: const [
                  Tab(child: Text('Takım Üyeleri')),
                  Tab(child: Text('Aktivite')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TeamMembersTab(
                    membersAsync: membersAsync,
                    onRefresh: _refresh,
                  ),
                  _TeamActivityTab(
                    activityAsync: activityAsync,
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

class _TeamMembersTab extends StatelessWidget {
  const _TeamMembersTab({
    required this.membersAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> membersAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.people_outline_rounded,
              message: 'Takım üyesi yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: members.length,
            itemBuilder: (context, i) {
              final member = members[i];
              return _TeamMemberCard(member: member);
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
          message: 'Üyeler yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _TeamActivityTab extends StatelessWidget {
  const _TeamActivityTab({
    required this.activityAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> activityAsync;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.history_rounded,
              message: 'Aktivite yok.',
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
              return _ActivityCard(activity: activity);
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
          message: 'Aktiviteler yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.member});

  final Map<String, dynamic> member;

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'founder':
      case 'kurucu':
        return Colors.amber;
      case 'siteadmin':
      case 'site_admin':
        return AppThemeColors.accentPink;
      case 'moderator':
      case 'moderatör':
        return AppThemeColors.accentCyan;
      case 'financial':
      case 'finans':
        return Colors.green;
      default:
        return AppThemeColors.liveRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String?;
    final email = member['email'] as String?;
    final role = member['role'] as String?;
    final permissionCount = member['permission_count'] as int? ?? 0;
    final lastActivity = member['last_activity'] as String?;
    final isActive = member['is_active'] as bool? ?? false;

    final roleColor = _getRoleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: roleColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      email ?? '',
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
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text('$permissionCount izin',
                        style: const TextStyle(fontSize: 9)),
                    backgroundColor:
                        AppThemeColors.accentCyan.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(fontSize: 9),
                  ),
                  const SizedBox(width: 8),
                  if (isActive)
                    Chip(
                      label: const Text('Aktif',
                          style: TextStyle(fontSize: 9)),
                      backgroundColor:
                          Colors.green.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(fontSize: 9),
                    )
                  else
                    Chip(
                      label: const Text('Pasif',
                          style: TextStyle(fontSize: 9)),
                      backgroundColor:
                          context.colors.onSurfaceMuted.withValues(alpha: 0.2),
                      labelStyle: const TextStyle(fontSize: 9),
                    ),
                ],
              ),
              if (lastActivity != null)
                Text(
                  lastActivity,
                  style: TextStyle(
                    fontSize: 9,
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final adminName = activity['admin_name'] as String?;
    final action = activity['action'] as String?;
    final targetName = activity['target_name'] as String?;
    final timestamp = activity['timestamp'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.accentPink.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: AppThemeColors.accentPink,
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
                    Text(
                      action ?? 'Unknown action',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (targetName != null && targetName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Hedef: $targetName',
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (timestamp != null)
            Text(
              timestamp,
              style: TextStyle(
                fontSize: 9,
                color: context.colors.onSurfaceMuted,
              ),
            ),
        ],
      ),
    );
  }
}
