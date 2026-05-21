import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

final adminCfcPaymentRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.safeGet<dynamic>(
    ApiEndpoints.adminCfcPaymentRequests,
    query: {'status': 'pending', 'limit': 30},
  );
  dynamic data = res.data;
  if (data is Map && data['requests'] is List) {
    return (data['requests'] as List).map((e) => asJsonMap(e)).toList();
  }
  if (data is Map && data['success'] == true && data['data'] is Map) {
    final inner = data['data'] as Map;
    final list = inner['requests'];
    if (list is List) return list.map((e) => asJsonMap(e)).toList();
  }
  return const [];
});

/// Admin — CFC ödeme talepleri (onay / red).
class AdminHubPage extends ConsumerWidget {
  const AdminHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(adminCfcPaymentRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Yönetim',
          subtitle: 'CFC ödeme talepleri',
          onRefresh: () async => ref.invalidate(adminCfcPaymentRequestsProvider),
          body: payments.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.shield_outlined,
              message: ApiException.userMessage(e),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'Bekleyen CFC talebi yok.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final r = rows[i];
                  final id = r['id']?.toString() ?? '';
                  final amount = r['amount'] ?? '';
                  final method = (r['method'] ?? '').toString();
                  final user = r['user'] is Map ? asJsonMap(r['user']) : null;
                  final name = user?['name']?.toString() ??
                      r['senderInfo']?.toString() ??
                      'Kullanıcı';

                  return DiscoverGlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$amount CFC · ${_methodTr(method)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        if (r['notes'] != null)
                          Text(
                            r['notes'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: id.isEmpty
                                    ? null
                                    : () => _review(
                                          context,
                                          ref,
                                          id,
                                          'reject',
                                        ),
                                child: const Text('Reddet'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: id.isEmpty
                                    ? null
                                    : () => _review(
                                          context,
                                          ref,
                                          id,
                                          'approve',
                                        ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentCyan,
                                ),
                                child: const Text('Onayla'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    String requestId,
    String action,
  ) async {
    try {
      await ref.read(dioProvider).safePatch<dynamic>(
        ApiEndpoints.adminCfcPaymentPatch,
        data: {
          'requestId': requestId,
          'action': action,
          if (action == 'approve') 'reviewNote': 'Onaylandı',
        },
      );
      ref.invalidate(adminCfcPaymentRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approve' ? 'Talep onaylandı' : 'Talep reddedildi',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }
  }

  static String _methodTr(String m) => switch (m) {
        'whatsapp' => 'WhatsApp',
        'papara' => 'Papara',
        'bank_transfer' => 'Havale/EFT',
        _ => m,
      };
}
