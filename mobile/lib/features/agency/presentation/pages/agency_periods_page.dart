import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/agency_management_models.dart';
import '../providers/agency_management_providers.dart';
import '../widgets/agency_mgmt_widgets.dart';

/// PR #33 — `GET /api/agency/periods`
class AgencyPeriodsPage extends ConsumerWidget {
  const AgencyPeriodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(agencyPeriodsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dönem geçmişi')),
      body: AsyncSection<List<AgencyPeriodView>>(
        value: async,
        onRetry: () => ref.invalidate(agencyPeriodsProvider),
        builder: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Henüz kapanmış dönem yok.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = rows[i];
              return ListTile(
                tileColor: Colors.white.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(p.period, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  '${p.memberCount} üye · ${p.totalJeton} jeton'
                  '${p.closedAt != null ? '\nKapanış: ${fmtDate(p.closedAt)}' : ''}'
                  '${p.status.isNotEmpty ? ' · ${p.status}' : ''}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
