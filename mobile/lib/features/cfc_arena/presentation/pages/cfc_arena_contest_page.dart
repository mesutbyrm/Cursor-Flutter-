import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

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
            ],
          );
        },
      ),
    );
  }
}
