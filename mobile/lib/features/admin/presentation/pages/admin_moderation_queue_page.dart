import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_moderation_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin moderation queue — user reports & content reports.
class AdminModerationQueuePage extends ConsumerStatefulWidget {
  const AdminModerationQueuePage({super.key});

  @override
  ConsumerState<AdminModerationQueuePage> createState() =>
      _AdminModerationQueuePageState();
}

class _AdminModerationQueuePageState
    extends ConsumerState<AdminModerationQueuePage>
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
    ref.invalidate(adminUserReportsProvider);
    ref.invalidate(adminContentReportsProvider);
  }

  Future<void> _handleReport(
    String reportId,
    String action, {
    String? reason,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.safePost<dynamic>(
        '${ApiEndpoints.adminUserReports}/$reportId/action',
        data: {
          'action': action, // 'approve', 'reject', 'ignore'
          'reason': reason,
        },
      );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor $action yapıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
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
              message: 'Moderasyon yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final userReportsAsync = ref.watch(adminUserReportsProvider);
    final contentReportsAsync = ref.watch(adminContentReportsProvider);
    final userCount = ref.watch(adminPendingReportsCountProvider);
    final contentCount = ref.watch(adminPendingContentReportsCountProvider);

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
                      title: 'Moderation',
                      subtitle: 'User & content reports',
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
                        const Text('Kullanıcı'),
                        if (userCount > 0) ...[
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
                              '$userCount',
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
                        const Text('İçerik'),
                        if (contentCount > 0) ...[
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
                              '$contentCount',
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
                  _UserReportsTab(
                    reportsAsync: userReportsAsync,
                    onRefresh: _refresh,
                    onHandle: _handleReport,
                  ),
                  _ContentReportsTab(
                    reportsAsync: contentReportsAsync,
                    onRefresh: _refresh,
                    onHandle: _handleReport,
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

class _UserReportsTab extends StatelessWidget {
  const _UserReportsTab({
    required this.reportsAsync,
    required this.onRefresh,
    required this.onHandle,
  });

  final AsyncValue<List<Map<String, dynamic>>> reportsAsync;
  final VoidCallback onRefresh;
  final Function(String, String, {String? reason}) onHandle;

  @override
  Widget build(BuildContext context) {
    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.done_all_rounded,
              message: 'Hiç rapor yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final report = reports[i];
              return _ReportCard(
                report: report,
                onApprove: () => onHandle(
                  report['id'] ?? '',
                  'approve',
                ),
                onReject: () => onHandle(
                  report['id'] ?? '',
                  'reject',
                  reason: report['reason'] ?? '',
                ),
                onIgnore: () => onHandle(
                  report['id'] ?? '',
                  'ignore',
                ),
              );
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
          message: 'Rapor yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _ContentReportsTab extends StatelessWidget {
  const _ContentReportsTab({
    required this.reportsAsync,
    required this.onRefresh,
    required this.onHandle,
  });

  final AsyncValue<List<Map<String, dynamic>>> reportsAsync;
  final VoidCallback onRefresh;
  final Function(String, String, {String? reason}) onHandle;

  @override
  Widget build(BuildContext context) {
    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.done_all_rounded,
              message: 'Hiç rapor yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final report = reports[i];
              return _ReportCard(
                report: report,
                onApprove: () => onHandle(
                  report['id'] ?? '',
                  'approve',
                ),
                onReject: () => onHandle(
                  report['id'] ?? '',
                  'reject',
                  reason: report['reason'] ?? '',
                ),
                onIgnore: () => onHandle(
                  report['id'] ?? '',
                  'ignore',
                ),
              );
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
          message: 'Rapor yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onApprove,
    required this.onReject,
    required this.onIgnore,
  });

  final Map<String, dynamic> report;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final reason = report['reason'] as String?;
    final reportedUser = report['reported_user'] as String?;
    final reportType = report['type'] as String? ?? 'unknown';
    final createdAt = report['created_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: AppThemeColors.liveRed.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_rounded,
                color: AppThemeColors.liveRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportedUser ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      reportType,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (createdAt != null)
                Text(
                  createdAt.substring(0, 10),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurface,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onIgnore,
                  label: const Text('Yoksay'),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  label: const Text('Reddet'),
                  icon: const Icon(Icons.cancel, size: 16),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemeColors.accentCyan,
                    side: BorderSide(
                      color: AppThemeColors.accentCyan.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  label: const Text('Onayla'),
                  icon: const Icon(Icons.check, size: 16),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppThemeColors.liveRed,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
