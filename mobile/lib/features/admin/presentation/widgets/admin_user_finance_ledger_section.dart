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

/// Defter satırı: etiket + tutar (+ adet).
typedef AdminLedgerRow = ({String label, num amount, int? count});

Future<Map<String, dynamic>> _fetchSection(Ref ref, String path, String range) async {
  final res = await ref.watch(dioProvider).safeGet<dynamic>(
        path,
        query: {if (range != 'all') 'range': range},
      );
  final body = asJsonMap(res.data);
  return body['data'] is Map ? asJsonMap(body['data']) : const {};
}

num _num(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

List<AdminLedgerRow> _byType(dynamic raw) => [
      for (final r in asJsonList(raw))
        (
          label: r['type']?.toString() ?? 'diğer',
          amount: _num(asJsonMap(r['_sum'])['amount']).abs(),
          count: asInt(r['_count']),
        ),
    ];

/// `section=earnings` — hediye geliri, falcı/ajans kazancı, jeton gelir türleri.
List<AdminLedgerRow> parseAdminEarnings(Map<String, dynamic> d) => [
      (
        label: 'Hediye geliri',
        amount: _num(d['gift_income_jeton']),
        count: asInt(d['gift_income_count']),
      ),
      (label: 'Falcı toplam kazanç', amount: _num(d['teller_total_earnings']), count: null),
      (label: 'Ajans kazancı', amount: _num(d['agency_earnings']), count: null),
      (label: 'Toplam jeton geliri', amount: _num(d['jeton_earned_total']), count: null),
      ..._byType(d['by_type']),
    ];

/// `section=spending` — hediye harcaması, jeton gider türleri.
List<AdminLedgerRow> parseAdminSpending(Map<String, dynamic> d) => [
      (
        label: 'Hediye harcaması',
        amount: _num(d['gift_spent_jeton']),
        count: asInt(d['gift_spent_count']),
      ),
      (label: 'Toplam jeton harcaması', amount: _num(d['jeton_spent_total']), count: null),
      ..._byType(d['by_type']),
    ];

final adminUserEarningsProvider = FutureProvider.autoDispose
    .family<List<AdminLedgerRow>, (String userId, AdminFinanceRange range)>(
  (ref, key) async => parseAdminEarnings(
    await _fetchSection(ref, ApiEndpoints.adminUserEarnings(key.$1), key.$2.query),
  ),
);

final adminUserSpendingProvider = FutureProvider.autoDispose
    .family<List<AdminLedgerRow>, (String userId, AdminFinanceRange range)>(
  (ref, key) async => parseAdminSpending(
    await _fetchSection(ref, ApiEndpoints.adminUserSpending(key.$1), key.$2.query),
  ),
);

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
  final AsyncValue<List<AdminLedgerRow>> async;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('tr');
    return async.when(
      loading: () => Text('$title…'),
      error: (_, __) => Text('$title yüklenemedi (yetki gerekebilir)'),
      data: (rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final r in rows)
            ListTile(
              dense: true,
              title: Text(r.label, style: const TextStyle(fontSize: 12)),
              trailing: Text(
                r.count == null
                    ? fmt.format(r.amount)
                    : '${fmt.format(r.amount)} · ${r.count} işlem',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
