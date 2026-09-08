import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../providers/admin_panel_providers.dart';

/// Admin — kullanıcı jeton/CFC işlem geçmişi (`GET /api/admin/finance`).
class AdminUserFinanceHistorySheet {
  AdminUserFinanceHistorySheet._();

  static Future<void> show(
    BuildContext context, {
    required WidgetRef ref,
    required String userId,
    required String userLabel,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SheetBody(
        userId: userId,
        userLabel: userLabel,
      ),
    );
  }
}

class _SheetBody extends ConsumerStatefulWidget {
  const _SheetBody({
    required this.userId,
    required this.userLabel,
  });

  final String userId;
  final String userLabel;

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(adminRemoteProvider)
        .fetchUserFinanceHistory(userId: widget.userId);
  }

  void _reload() {
    setState(() {
      _future = ref
          .read(adminRemoteProvider)
          .fetchUserFinanceHistory(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: maxH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jeton / CFC geçmişi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          widget.userLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          ApiException.userMessage(snap.error!),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final rows = snap.data ?? const [];
                  if (rows.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bu kullanıcı için kayıt bulunamadı veya API henüz veri döndürmedi.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = rows[i];
                      return _FinanceRow(row: r);
                    },
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

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final kind = (row['type'] ??
            row['currency'] ??
            row['kind'] ??
            row['transactionType'] ??
            'işlem')
        .toString();
    final amount = row['amount'] ?? row['value'] ?? row['coins'] ?? row['cfc'];
    final note = row['note'] ?? row['description'] ?? row['reason'];
    final at = row['createdAt']?.toString() ?? row['timestamp']?.toString();
    final time = at != null ? DateTime.tryParse(at) : null;

    return ListTile(
      dense: true,
      leading: Icon(
        kind.toLowerCase().contains('cfc')
            ? Icons.toll_outlined
            : Icons.monetization_on_outlined,
        color: AppThemeColors.accentCyan,
      ),
      title: Text(
        '$kind${amount != null ? ' · $amount' : ''}',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      subtitle: note != null && note.toString().isNotEmpty
          ? Text(note.toString(), maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: time != null
          ? Text(
              DateFormat('dd.MM HH:mm').format(time.toLocal()),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            )
          : null,
    );
  }
}
