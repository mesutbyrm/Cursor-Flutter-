import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

final cfcContestScoresProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, contestId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res =
        await dio.safeGet<dynamic>(ApiEndpoints.cfcArenaContestScores(contestId));
    final body = res.data;
    if (body is Map) {
      final items = body['items'] ?? body['data'];
      if (items is List) {
        return items.whereType<Map>().map((e) => asJsonMap(e)).toList();
      }
    }
  } catch (_) {}
  return const [];
});

final cfcContestDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, contestId) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(ApiEndpoints.cfcArenaContest(contestId));
    final body = res.data;
    if (body is Map) {
      final map = asJsonMap(body);
      if (map['contest'] is Map) return asJsonMap(map['contest']);
      return map;
    }
  } catch (_) {}
  return null;
});

class CfcArenaContestPage extends ConsumerWidget {
  const CfcArenaContestPage({super.key, required this.contestId});

  final String contestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cfcContestDetailProvider(contestId));
    final scores = ref.watch(cfcContestScoresProvider(contestId));
    return Scaffold(
      appBar: AppBar(title: const Text('Yarışma')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (c) {
          if (c == null) {
            return const Center(child: Text('Yarışma bulunamadı'));
          }
          final name = (c['name'] ?? 'Yarışma').toString();
          final status = (c['status'] ?? '').toString();
          final desc = (c['description'] ?? '').toString();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              Text('Durum: $status'),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(desc),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioProvider);
                    await dio.safePost<dynamic>(
                      ApiEndpoints.cfcArenaJoin,
                      data: {'contestId': contestId},
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yarışmaya katıldınız')),
                      );
                      ref.invalidate(cfcContestDetailProvider(contestId));
                      ref.invalidate(cfcContestScoresProvider(contestId));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ApiException.userMessage(e))),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Yarışmaya katıl'),
              ),
              const SizedBox(height: 24),
              Text(
                'Sıralama',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._participants(c).map(
                (p) => ListTile(
                  dense: true,
                  title: Text(
                    (p['userId'] ?? p['displayName'] ?? 'Katılımcı')
                        .toString(),
                  ),
                  trailing: Text('${pick(p, ['score']) ?? 0} p'),
                ),
              ),
              if (_participants(c).isEmpty)
                const Text('Henüz katılımcı yok.'),
              const SizedBox(height: 16),
              Text(
                'Son skor kayıtları',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              scores.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Text('Skor kaydı yok.');
                  }
                  return Column(
                    children: logs.take(8).map((log) {
                      final metric = (log['metric'] ?? '').toString();
                      final delta = pick(log, ['delta']);
                      return ListTile(
                        dense: true,
                        title: Text(metric.isEmpty ? 'Skor' : metric),
                        subtitle: Text(
                          (log['reason'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('+$delta'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static List<Map<String, dynamic>> _participants(Map<String, dynamic> c) {
    final raw = c['participants'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => asJsonMap(e)).toList();
  }
}
