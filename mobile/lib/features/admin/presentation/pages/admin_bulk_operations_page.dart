import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_bulk_operations_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin bulk operations — manage multiple users/items efficiently.
class AdminBulkOperationsPage extends ConsumerStatefulWidget {
  const AdminBulkOperationsPage({super.key});

  @override
  ConsumerState<AdminBulkOperationsPage> createState() =>
      _AdminBulkOperationsPageState();
}

class _AdminBulkOperationsPageState
    extends ConsumerState<AdminBulkOperationsPage> {
  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManageUsers) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Toplu işlem yetkisi gerekli.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final historyAsync = ref.watch(adminBulkOperationHistoryProvider);

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
                      title: 'Bulk Operations',
                      subtitle: 'Manage multiple items efficiently',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      ref.invalidate(adminBulkOperationHistoryProvider);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppThemeColors.accentPink,
                onRefresh: () async {
                  ref.invalidate(adminBulkOperationHistoryProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Quick actions
                    _SectionTitle('Hızlı İşlemler'),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.2,
                      children: [
                        _BulkActionButton(
                          icon: Icons.warning_rounded,
                          label: 'Kullanıcıları Uyar',
                          color: AppThemeColors.accentPink,
                          onTap: () => _showBulkOperationDialog(
                            context,
                            BulkOperationType.warnUsers,
                          ),
                        ),
                        _BulkActionButton(
                          icon: Icons.block_rounded,
                          label: 'Kullanıcıları Yasakla',
                          color: AppThemeColors.liveRed,
                          onTap: () => _showBulkOperationDialog(
                            context,
                            BulkOperationType.banUsers,
                          ),
                        ),
                        _BulkActionButton(
                          icon: Icons.add_circle_rounded,
                          label: 'Jeton Ekle',
                          color: AppThemeColors.accentCyan,
                          onTap: () => _showBulkOperationDialog(
                            context,
                            BulkOperationType.addTokens,
                          ),
                        ),
                        _BulkActionButton(
                          icon: Icons.remove_circle_rounded,
                          label: 'Jeton Kaldır',
                          color: AppThemeColors.accentPink,
                          onTap: () => _showBulkOperationDialog(
                            context,
                            BulkOperationType.removeTokens,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // History
                    _SectionTitle('İşlem Geçmişi'),
                    _OperationHistory(historyAsync: historyAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkOperationDialog(
    BuildContext context,
    BulkOperationType type,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bulkOperationTypeLabel(type)),
        content: const Text('Bu işlem için parametreler girin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${bulkOperationTypeLabel(type)} işlemi başlatıldı',
                  ),
                ),
              );
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationHistory extends StatelessWidget {
  const _OperationHistory({required this.historyAsync});

  final AsyncValue<List<Map<String, dynamic>>> historyAsync;

  @override
  Widget build(BuildContext context) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: DiscoverEmptyState(
              icon: Icons.history_rounded,
              message: 'İşlem geçmişi boş.',
            ),
          );
        }
        return Column(
          children: List.generate(history.length, (i) {
            final operation = history[i];
            return _BulkOperationCard(operation: operation);
          }),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Center(
        child: DiscoverEmptyState(
          icon: Icons.error_outline_rounded,
          message: 'Geçmiş yüklenemedi',
        ),
      ),
    );
  }
}

class _BulkOperationCard extends StatelessWidget {
  const _BulkOperationCard({required this.operation});

  final Map<String, dynamic> operation;

  @override
  Widget build(BuildContext context) {
    final operationType = operation['operation_type'] as String?;
    final adminName = operation['admin_name'] as String?;
    final itemCount = operation['item_count'] as int? ?? 0;
    final status = operation['status'] as String? ?? 'pending';
    final createdAt = operation['created_at'] as String?;
    final completedAt = operation['completed_at'] as String?;

    final opStatus = parseBulkOperationStatus(status);
    final statusColor = _getStatusColor(opStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_rounded,
                color: statusColor,
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
                      operationType ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 11,
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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bulkOperationStatusLabel(opStatus),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Öğe Sayısı: $itemCount',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurface,
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
          if (completedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tamamlanan: $completedAt',
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BulkOperationStatus status) {
    switch (status) {
      case BulkOperationStatus.pending:
        return AppThemeColors.accentCyan;
      case BulkOperationStatus.inProgress:
        return AppThemeColors.accentPink;
      case BulkOperationStatus.completed:
        return AppThemeColors.accentCyan;
      case BulkOperationStatus.failed:
        return AppThemeColors.liveRed;
    }
  }
}
