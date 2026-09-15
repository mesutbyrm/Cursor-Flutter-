import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/util/json_util.dart';
import '../providers/cfc_arena_providers.dart';

/// CFC Arena — puan/rozet odaklı yarışmalar (§21–25); ödül para/jeton değil.
class CfcArenaHubPage extends ConsumerWidget {
  const CfcArenaHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cfcArenaContestsProvider);
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
              final id = pick(c, ['id', 'contestId', '_id'])?.toString() ?? '';
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(status),
                  trailing: const Icon(Icons.emoji_events_outlined),
                  onTap: id.isEmpty
                      ? null
                      : () => context.push('/cfc-arena/$id'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
