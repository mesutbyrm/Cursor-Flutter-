import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

final cfcArenaListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    final dio = ref.watch(dioProvider);
    try {
      final res = await dio.safeGet<dynamic>(ApiEndpoints.cfcArena);
      final body = res.data;
      if (body is List) {
        return body.whereType<Map>().map((e) => asJsonMap(e)).toList();
      }
      if (body is Map) {
        final map = asJsonMap(body);
        final data = map['data'] is Map ? asJsonMap(map['data']) : map;
        final list = data['contests'] ?? data['items'] ?? [];
        if (list is List) {
          return list.whereType<Map>().map((e) => asJsonMap(e)).toList();
        }
      }
    } catch (_) {}
    return const [];
  },
);

/// CFC Arena — puan/rozet odaklı yarışmalar (§21–25); ödül para/jeton değil.
class CfcArenaHubPage extends ConsumerWidget {
  const CfcArenaHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cfcArenaListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('CFC Arena')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aktif yarışma yok veya sunucu henüz '
                  '`GET /api/cfc-arena` döndürmüyor.\n'
                  'Ödüller rozet, unvan ve görünürlük ile verilir.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final c = rows[i];
              final name = (c['name'] ?? c['title'] ?? 'Yarışma').toString();
              final status = (c['status'] ?? c['phase'] ?? '').toString();
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(status),
                  trailing: const Icon(Icons.emoji_events_outlined),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
