import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';

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

class CfcArenaContestPage extends ConsumerStatefulWidget {
  const CfcArenaContestPage({super.key, required this.contestId});

  final String contestId;

  @override
  ConsumerState<CfcArenaContestPage> createState() => _CfcArenaContestPageState();
}

class _CfcArenaContestPageState extends ConsumerState<CfcArenaContestPage> {
  var _joining = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cfcContestDetailProvider(widget.contestId));
    final scores = ref.watch(cfcContestScoresProvider(widget.contestId));
    return PlatformSocialScaffold(
      title: 'Yarışma detayı',
      subtitle: 'Canlı sıralama ve skor geçmişi',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PlatformSocialEmptyState(
          icon: Icons.error_outline,
          message: ApiException.userMessage(e),
        ),
        data: (c) {
          if (c == null) {
            return const PlatformSocialEmptyState(
              icon: Icons.search_off_rounded,
              message: 'Yarışma bulunamadı',
            );
          }
          final name = (c['name'] ?? 'Yarışma').toString();
          final status = (c['status'] ?? '').toString();
          final desc = (c['description'] ?? '').toString();
          final participants = _participants(c);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              PlatformSocialGlassCard(
                gradient: PlatformSocialPalette.heroGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PlatformSocialStatusPill(
                      label: status.isEmpty ? 'aktif' : status,
                      icon: Icons.bolt_rounded,
                      tone: PlatformSocialPillTone.gold,
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        desc,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PlatformSocialPrimaryButton(
                label: 'Yarışmaya katıl',
                icon: Icons.emoji_events_outlined,
                loading: _joining,
                onPressed: () => _join(context),
              ),
              const SizedBox(height: 24),
              PlatformSocialSectionTitle(
                'Sıralama',
                trailing: Text(
                  '${participants.length} katılımcı',
                  style: const TextStyle(
                    fontSize: 11,
                    color: PlatformSocialPalette.textMuted,
                  ),
                ),
              ),
              if (participants.isEmpty)
                const PlatformSocialEmptyState(
                  icon: Icons.people_outline,
                  message: 'Henüz katılımcı yok — ilk sen ol!',
                )
              else
                ...participants.asMap().entries.map((e) {
                  final p = e.value;
                  final rank = e.key + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PlatformSocialRankTile(
                      rank: rank,
                      highlight: rank <= 3,
                      title: (p['userId'] ?? p['displayName'] ?? 'Katılımcı')
                          .toString(),
                      subtitle: 'Aktif',
                      score: '${pick(p, ['score']) ?? 0} p',
                    ),
                  );
                }),
              const SizedBox(height: 20),
              const PlatformSocialSectionTitle('Son skor kayıtları'),
              scores.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Text(
                      'Skor kaydı yok.',
                      style: TextStyle(color: PlatformSocialPalette.textMuted),
                    );
                  }
                  return Column(
                    children: logs.take(8).map((log) {
                      final metric = (log['metric'] ?? 'Skor').toString();
                      final delta = pick(log, ['delta']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PlatformSocialGlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      metric,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      (log['reason'] ?? '').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: PlatformSocialPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+$delta',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: PlatformSocialPalette.success,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Future<void> _join(BuildContext context) async {
    setState(() => _joining = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.safePost<dynamic>(
        ApiEndpoints.cfcArenaJoin,
        data: {'contestId': widget.contestId},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yarışmaya katıldınız')),
        );
        ref.invalidate(cfcContestDetailProvider(widget.contestId));
        ref.invalidate(cfcContestScoresProvider(widget.contestId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  static List<Map<String, dynamic>> _participants(Map<String, dynamic> c) {
    final raw = c['participants'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => asJsonMap(e)).toList();
  }
}
