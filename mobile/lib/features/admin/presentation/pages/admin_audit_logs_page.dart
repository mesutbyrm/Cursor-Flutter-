import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

/// Admin — Tam denetim günlüğü (tüm admin işlemleri).
class AdminAuditLogsPage extends ConsumerStatefulWidget {
  const AdminAuditLogsPage({super.key});

  @override
  ConsumerState<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends ConsumerState<AdminAuditLogsPage> {
  Future<List<Map<String, dynamic>>>? _future;
  String? _selectedAction;
  String? _selectedUser;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _future = _load());
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    // Mock data — API yazılana kadar
    return [
      {
        'id': 'audit_001',
        'admin': 'admin_user_1',
        'action': 'User Ban',
        'targetUser': 'user_xyz',
        'details': 'Uygunsuz davranış sebebiyle kalıcı yasaklama',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'ipAddress': '192.168.1.100',
        'status': 'Başarılı',
      },
      {
        'id': 'audit_002',
        'admin': 'admin_user_2',
        'action': 'Payment Approve',
        'targetUser': 'psychic_001',
        'details': '2500 TL ödeme onaylandı',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
        'ipAddress': '192.168.1.101',
        'status': 'Başarılı',
      },
      {
        'id': 'audit_003',
        'admin': 'admin_user_1',
        'action': 'Content Remove',
        'targetUser': 'user_abc',
        'details': 'Müstehcen içerik kaldırıldı',
        'timestamp': DateTime.now().subtract(const Duration(hours: 12)),
        'ipAddress': '192.168.1.100',
        'status': 'Başarılı',
      },
      {
        'id': 'audit_004',
        'admin': 'admin_user_3',
        'action': 'Gift Refund',
        'targetUser': 'user_def',
        'details': 'Hatalı hediye işlemi geri alındı',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'ipAddress': '192.168.1.102',
        'status': 'Başarılı',
      },
      {
        'id': 'audit_005',
        'admin': 'admin_user_2',
        'action': 'Membership Update',
        'targetUser': 'user_ghi',
        'details': 'VIP üyelik 30 gün uzatıldı',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'ipAddress': '192.168.1.101',
        'status': 'Başarılı',
      },
    ];
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments && !access.canModerate) {
      return Scaffold(
        body: DiscoverBackground(
          child: Center(
            child: DiscoverEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Denetim günlüğü yalnızca yöneticiler tarafından erişilir.',
              actionLabel: 'Geri',
              action: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

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
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: DiscoverTabHeader(
                      title: 'Denetim Günlüğü',
                      subtitle: 'Tüm admin işlemlerinin kaydı',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            // Filtreler
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Chip(
                      label: const Text('Tümü'),
                      onDeleted:
                          _selectedAction == null ? null : () => setState(() => _selectedAction = null),
                      deleteIcon: _selectedAction == null ? null : const Icon(Icons.clear, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('Kullanıcı'),
                      onDeleted:
                          _selectedUser == null ? null : () => setState(() => _selectedUser = null),
                      deleteIcon: _selectedUser == null ? null : const Icon(Icons.clear, size: 16),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (_future == null || snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: DiscoverAccentLoader());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.error_outline_rounded,
                        message: ApiException.userMessage(snap.error!),
                        actionLabel: 'Yenile',
                        action: _refresh,
                      ),
                    );
                  }
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return const Center(
                      child: DiscoverEmptyState(
                        icon: Icons.history_rounded,
                        message: 'Denetim kaydı bulunamadı.',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppThemeColors.accentPink,
                    onRefresh: () async => _refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final log = rows[i];
                        return _AuditLogCard(log: log);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});
  final Map<String, dynamic> log;

  Color _getActionColor(String action) {
    if (action.contains('Ban') || action.contains('Remove')) return AppThemeColors.liveRed;
    if (action.contains('Approve') || action.contains('Update')) return Colors.green;
    if (action.contains('Refund')) return Colors.orange;
    return AppThemeColors.accentCyan;
  }

  @override
  Widget build(BuildContext context) {
    final action = log['action']?.toString() ?? '—';
    final admin = log['admin']?.toString() ?? '—';
    final timestamp = log['timestamp'] as DateTime?;
    final details = log['details']?.toString() ?? '—';
    final ipAddress = log['ipAddress']?.toString() ?? '—';

    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getActionColor(action).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getActionColor(action).withValues(alpha: 0.4)),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: _getActionColor(action),
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: log['status'] == 'Başarılı' ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            details,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Admin: $admin',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Text(
                ipAddress,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timestamp != null
                ? DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toLocal())
                : '—',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
