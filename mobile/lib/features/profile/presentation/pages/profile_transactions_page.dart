import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_providers.dart';

class ProfileTransactionsPage extends ConsumerWidget {
  const ProfileTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(allPaymentRequestsProvider);
    final activity = ref.watch(profileActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'İşlemler',
          subtitle: 'Ödeme talepleri ve site hareketleri',
          onRefresh: () async {
            ref.invalidate(allPaymentRequestsProvider);
            ref.invalidate(profileActivityProvider);
          },
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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
      child: DiscoverGlassCard(
        padding: const EdgeInsets.all(12),
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
      child: DiscoverGlassCard(
        padding: const EdgeInsets.all(12),
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
