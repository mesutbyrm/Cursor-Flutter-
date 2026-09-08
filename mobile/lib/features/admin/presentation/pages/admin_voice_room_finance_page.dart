import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/staff_access_provider.dart';

/// Admin — sesli oda finans denetim kayıtları.
class AdminVoiceRoomFinancePage extends ConsumerWidget {
  const AdminVoiceRoomFinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canManagePayments && !access.canManageVoiceRooms) {
      return _locked(context);
    }

    final auditAsync = ref.watch(adminVoiceRoomFinanceAuditProvider);

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
                      title: 'Oda Finans Denetimi',
                      subtitle: 'Sesli oda jeton/CFC hareketleri',
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () =>
                        ref.invalidate(adminVoiceRoomFinanceAuditProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: auditAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppThemeColors.accentPink,
                  ),
                ),
                error: (e, _) => Center(
                  child: DiscoverEmptyState(
                    icon: Icons.error_outline_rounded,
                    message: ApiException.userMessage(e),
                    actionLabel: 'Tekrar',
                    action: () =>
                        ref.invalidate(adminVoiceRoomFinanceAuditProvider),
                  ),
                ),
                data: (rows) {
                  if (rows.isEmpty) {
                    return Center(
                      child: DiscoverEmptyState(
                        icon: Icons.receipt_long_outlined,
                        message:
                            'Denetim kaydı bulunamadı veya bu uç nokta henüz aktif değil.',
                        actionLabel: 'Geri',
                        action: () => context.pop(),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppThemeColors.accentPink,
                    onRefresh: () async {
                      ref.invalidate(adminVoiceRoomFinanceAuditProvider);
                      await ref.read(adminVoiceRoomFinanceAuditProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return _AuditRow(row: row);
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

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Finans denetimi için yetkiniz yok.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final room = row['roomName']?.toString() ??
        row['roomId']?.toString() ??
        'Oda';
    final user = row['username']?.toString() ??
        row['userId']?.toString() ??
        '—';
    final amount = row['amount']?.toString() ??
        row['jeton']?.toString() ??
        row['cfc']?.toString() ??
        '—';
    final type = row['type']?.toString() ?? row['action']?.toString() ?? '';
    final created = row['createdAt']?.toString();
    final when = created != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(
            DateTime.tryParse(created)?.toLocal() ?? DateTime.now(),
          )
        : '—';

    return DiscoverGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kullanıcı: $user',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          if (type.isNotEmpty)
            Text(
              'İşlem: $type · $amount',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          Text(
            when,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
