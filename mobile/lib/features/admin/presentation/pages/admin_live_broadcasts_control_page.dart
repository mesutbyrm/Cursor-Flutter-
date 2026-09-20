import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_live_broadcasts_providers.dart';
import '../providers/staff_access_provider.dart';

/// Canlı yayın kontrol - aktif yayınları yönet ve moderasyon.
class AdminLiveBroadcastsControlPage extends ConsumerStatefulWidget {
  const AdminLiveBroadcastsControlPage({super.key});

  @override
  ConsumerState<AdminLiveBroadcastsControlPage> createState() =>
      _AdminLiveBroadcastsControlPageState();
}

class _AdminLiveBroadcastsControlPageState
    extends ConsumerState<AdminLiveBroadcastsControlPage>
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
    ref.invalidate(adminActiveBroadcastsProvider);
    ref.invalidate(adminFlaggedBroadcastsProvider);
  }

  Future<void> _handleBroadcastAction(
    String broadcastId,
    String action,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.safePost<dynamic>(
        '${ApiEndpoints.liveStreams}/$broadcastId/admin-action',
        data: {'action': action},
      );
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yayın işlemi başarılı: $action')),
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
    if (!access.canManageLiveStreams) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Canlı yayın yönetim yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final activeBroadcastsAsync = ref.watch(adminActiveBroadcastsProvider);
    final flaggedBroadcastsAsync = ref.watch(adminFlaggedBroadcastsProvider);
    final activeCount = ref.watch(adminActiveBroadcastCountProvider);
    final flaggedCount = ref.watch(adminFlaggedBroadcastCountProvider);

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
                      title: 'Yayın Kontrolü',
                      subtitle: 'Canlı yayınları yönet',
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
                        const Text('Aktif Yayınlar'),
                        if (activeCount > 0) ...[
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
                              '$activeCount',
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
                        const Text('Uyarılı Yayınlar'),
                        if (flaggedCount > 0) ...[
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
                              '$flaggedCount',
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
                  _ActiveBroadcastsTab(
                    broadcastsAsync: activeBroadcastsAsync,
                    onRefresh: _refresh,
                    onAction: _handleBroadcastAction,
                  ),
                  _FlaggedBroadcastsTab(
                    broadcastsAsync: flaggedBroadcastsAsync,
                    onRefresh: _refresh,
                    onAction: _handleBroadcastAction,
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

class _ActiveBroadcastsTab extends StatelessWidget {
  const _ActiveBroadcastsTab({
    required this.broadcastsAsync,
    required this.onRefresh,
    required this.onAction,
  });

  final AsyncValue<List<Map<String, dynamic>>> broadcastsAsync;
  final VoidCallback onRefresh;
  final Function(String, String) onAction;

  @override
  Widget build(BuildContext context) {
    return broadcastsAsync.when(
      data: (broadcasts) {
        if (broadcasts.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.live_tv_rounded,
              message: 'Aktif yayın yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: broadcasts.length,
            itemBuilder: (context, i) {
              final broadcast = broadcasts[i];
              return _BroadcastCard(
                broadcast: broadcast,
                onAction: onAction,
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
          message: 'Yayınlar yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _FlaggedBroadcastsTab extends StatelessWidget {
  const _FlaggedBroadcastsTab({
    required this.broadcastsAsync,
    required this.onRefresh,
    required this.onAction,
  });

  final AsyncValue<List<Map<String, dynamic>>> broadcastsAsync;
  final VoidCallback onRefresh;
  final Function(String, String) onAction;

  @override
  Widget build(BuildContext context) {
    return broadcastsAsync.when(
      data: (broadcasts) {
        if (broadcasts.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.verified_rounded,
              message: 'Uyarılı yayın yok.',
            ),
          );
        }
        return RefreshIndicator(
          color: AppThemeColors.accentPink,
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: broadcasts.length,
            itemBuilder: (context, i) {
              final broadcast = broadcasts[i];
              return _BroadcastCard(
                broadcast: broadcast,
                onAction: onAction,
                isFlagged: true,
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
          message: 'Yayınlar yüklenemedi',
          actionLabel: 'Tekrar Dene',
          action: onRefresh,
        ),
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({
    required this.broadcast,
    required this.onAction,
    this.isFlagged = false,
  });

  final Map<String, dynamic> broadcast;
  final Function(String, String) onAction;
  final bool isFlagged;

  @override
  Widget build(BuildContext context) {
    final broadcastId = broadcast['id'] as String?;
    final broadcasterName = broadcast['broadcaster_name'] as String?;
    final title = broadcast['title'] as String?;
    final viewerCount = broadcast['viewer_count'] as int? ?? 0;
    final duration = broadcast['duration'] as String?;
    final reason = broadcast['flag_reason'] as String?;
    final startedAt = broadcast['started_at'] as String?;

    final borderColor = isFlagged
        ? AppThemeColors.liveRed
        : AppThemeColors.accentCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.live_tv_rounded,
                color: borderColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broadcasterName ?? 'Bilinmiyor',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: context.colors.onSurface,
                      ),
                    ),
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people_rounded,
                size: 14,
                color: context.colors.onSurfaceMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '$viewerCount izleyici',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: 16),
              if (duration != null)
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
            ],
          ),
          if (isFlagged && reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Neden: $reason',
              style: TextStyle(
                fontSize: 10,
                color: AppThemeColors.liveRed,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isFlagged)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: broadcastId != null
                        ? () => onAction(broadcastId, 'warning')
                        : null,
                    label: const Text('Uyar', style: TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.warning_rounded, size: 16),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: broadcastId != null
                        ? () => onAction(broadcastId, 'clear_flag')
                        : null,
                    label: const Text('Temizle', style: TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.done_rounded, size: 16),
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
                child: OutlinedButton.icon(
                  onPressed: broadcastId != null
                      ? () => onAction(broadcastId, 'suspend')
                      : null,
                  label: const Text('Askıya Al', style: TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.pause_rounded, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: broadcastId != null
                      ? () => onAction(broadcastId, 'terminate')
                      : null,
                  label: const Text('Sonlandır', style: TextStyle(fontSize: 12)),
                  icon: const Icon(Icons.stop_rounded, size: 16),
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
