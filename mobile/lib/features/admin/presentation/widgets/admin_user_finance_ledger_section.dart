import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

enum AdminFinanceRange { today, d7, d30, d90, all }

extension on AdminFinanceRange {
  String get query => switch (this) {
        AdminFinanceRange.today => 'today',
        AdminFinanceRange.d7 => '7d',
        AdminFinanceRange.d30 => '30d',
        AdminFinanceRange.d90 => '90d',
        AdminFinanceRange.all => 'all',
      };
}

final adminUserEarningsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, (String userId, AdminFinanceRange range)>(
  (ref, key) async {
    final dio = ref.watch(dioProvider);
    try {
      final res = await dio.safeGet<dynamic>(
        ApiEndpoints.adminUserEarnings(key.$1),
        query: {'range': key.$2.query},
      );
      return _parseItems(res.data);
    } catch (_) {
      return const [];
    }
  },
);

final adminUserSpendingProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, (String userId, AdminFinanceRange range)>(
  (ref, key) async {
    final dio = ref.watch(dioProvider);
    try {
      final res = await dio.safeGet<dynamic>(
        ApiEndpoints.adminUserSpending(key.$1),
        query: {'range': key.$2.query},
      );
      return _parseItems(res.data);
    } catch (_) {
      return const [];
    }
  },
);

List<Map<String, dynamic>> _parseItems(dynamic body) {
  if (body is! Map) return const [];
  final map = asJsonMap(body);
  final list = map['items'] ?? map['data'];
  if (list is List) {
    return list.whereType<Map>().map((e) => asJsonMap(e)).toList();
  }
  return const [];
}

class AdminUserFinanceLedgerSection extends ConsumerStatefulWidget {
  const AdminUserFinanceLedgerSection({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserFinanceLedgerSection> createState() =>
      _AdminUserFinanceLedgerSectionState();
}

class _AdminUserFinanceLedgerSectionState
    extends ConsumerState<AdminUserFinanceLedgerSection> {
  AdminFinanceRange _range = AdminFinanceRange.d30;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final key = (widget.userId, _range);
    final earnings = ref.watch(adminUserEarningsProvider(key));
    final spending = ref.watch(adminUserSpendingProvider(key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Kazanç / harcama (API ledger)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          DropdownButton<AdminFinanceRange>(
            value: _range,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: AdminFinanceRange.today, child: Text('Bugün')),
              DropdownMenuItem(value: AdminFinanceRange.d7, child: Text('7 gün')),
              DropdownMenuItem(value: AdminFinanceRange.d30, child: Text('30 gün')),
              DropdownMenuItem(value: AdminFinanceRange.d90, child: Text('90 gün')),
              DropdownMenuItem(value: AdminFinanceRange.all, child: Text('Tüm zamanlar')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _range = v);
            },
          ),
          const SizedBox(height: 8),
          _LedgerBlock(title: 'Kazanç', async: earnings),
          const SizedBox(height: 12),
          _LedgerBlock(title: 'Harcama', async: spending),
        ],
      ],
    );
  }
}

class _LedgerBlock extends StatelessWidget {
  const _LedgerBlock({required this.title, required this.async});

  final String title;
  final AsyncValue<List<Map<String, dynamic>>> async;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => Text('$title…'),
      error: (_, __) => Text('$title yüklenemedi'),
      data: (rows) {
        if (rows.isEmpty) {
          return Text('$title: kayıt yok (üretim API bekleniyor)');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ...rows.take(12).map((r) {
              final at = r['createdAt']?.toString();
              final dt = DateTime.tryParse(at ?? '');
              final when = dt != null
                  ? DateFormat('dd.MM.yyyy HH:mm').format(dt.toLocal())
                  : '—';
              return ListTile(
                dense: true,
                title: Text(
                  '${r['amount']} ${r['currency'] ?? ''} · ${r['type'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text(r['description']?.toString() ?? ''),
                trailing: Text(when, style: const TextStyle(fontSize: 10)),
              );
            }),
          ],
        );
      },
    );
  }
}
