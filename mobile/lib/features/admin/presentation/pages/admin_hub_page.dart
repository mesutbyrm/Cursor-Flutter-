import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/json_util.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';

final adminPaymentRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.safeGet<dynamic>(ApiEndpoints.adminPaymentRequests);
  dynamic data = res.data;
  if (data is Map && data['success'] == true) data = data['data'];
  if (data is Map) {
    final list = data['requests'];
    if (list is List) return list.map((e) => asJsonMap(e)).toList();
  }
  return const [];
});

/// Admin / yönetici / moderatör / destek / yardım paneli.
class AdminHubPage extends ConsumerWidget {
  const AdminHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(adminPaymentRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Yönetim',
          subtitle: 'Ödeme talepleri ve site bildirimleri',
          onRefresh: () async => ref.invalidate(adminPaymentRequestsProvider),
          body: payments.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.shield_outlined,
              message: e.toString(),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'Bekleyen ödeme talebi yok.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final r = rows[i];
                  final method = (r['method'] ?? '').toString();
                  return DiscoverGlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['userName']?.toString() ?? 'Kullanıcı',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_methodTr(method)} · ${r['packageTitle'] ?? r['coins'] ?? ''}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Durum: ${r['status'] ?? 'pending'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accentCyan.withValues(alpha: 0.9),
                          ),
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

  static String _methodTr(String m) {
    return switch (m) {
      'whatsapp' => 'WhatsApp',
      'papara' => 'Papara',
      'havale' => 'Havale/EFT',
      _ => m,
    };
  }
}
