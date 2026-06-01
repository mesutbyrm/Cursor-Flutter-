import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/payment_requests_notifier.dart';
import '../providers/profile_activity_notifier.dart';

class ProfileTransactionsPage extends ConsumerStatefulWidget {
  const ProfileTransactionsPage({super.key});

  @override
  ConsumerState<ProfileTransactionsPage> createState() =>
      _ProfileTransactionsPageState();
}

class _ProfileTransactionsPageState
    extends ConsumerState<ProfileTransactionsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(paymentRequestsNotifierProvider.notifier).loadMore();
      ref.read(profileActivityNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(paymentRequestsNotifierProvider.notifier).refresh(),
      ref.read(profileActivityNotifierProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentRequestsNotifierProvider);
    final activity = ref.watch(profileActivityNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'İşlemler',
          subtitle: 'Ödeme talepleri ve site hareketleri',
          onRefresh: _refresh,
          body: payments.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (payRows) => activity.when(
              loading: () => const Center(child: DiscoverAccentLoader()),
              error: (e, _) => DiscoverEmptyState(
                icon: Icons.error_outline_rounded,
                message: ApiException.userMessage(e),
              ),
              data: (actRows) {
                if (payRows.isEmpty && actRows.isEmpty) {
                  return const DiscoverEmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'Henüz işlem kaydı yok.',
                  );
                }
                return ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  physics: ListPerf.listPhysics,
                  children: [
                    if (payRows.isNotEmpty) ...[
                      const _SectionTitle('Ödeme talepleri'),
                      ...payRows.map((r) => _PaymentTile(row: r)),
                    ],
                    if (actRows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _SectionTitle('Site hareketleri'),
                      ...actRows.map((r) => _ActivityTile(row: r)),
                    ],
                    if (ref.read(paymentRequestsNotifierProvider.notifier).hasMore ||
                        ref.read(profileActivityNotifierProvider.notifier).hasMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.row});
  final CfcPaymentRequestEntity row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProGlassListTile(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.displayLine,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (row.notes?.isNotEmpty == true)
                    Text(
                      row.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              row.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: row.status == 'approved'
                    ? Colors.greenAccent
                    : AppColors.accentPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.row});
  final ProfileActivityItemEntity row;

  @override
  Widget build(BuildContext context) {
    final when = row.createdAt != null
        ? DateFormat('d MMM HH:mm', 'tr')
            .format(DateTime.tryParse(row.createdAt!) ?? DateTime.now())
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ProGlassListTile(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (row.subtitle?.isNotEmpty == true)
              Text(
                row.subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '$when · ${row.amount > 0 ? "${row.amount} jeton" : row.status}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
