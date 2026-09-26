import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../providers/cfc_arena_providers.dart';

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
    final async = ref.watch(cfcArenaContestDetailProvider(widget.contestId));
    final myId = ref.watch(authControllerProvider).valueOrNull?.id;
    return PlatformSocialScaffold(
      title: 'Yarışma detayı',
      subtitle: 'Canlı sıralama ve skor geçmişi',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => PlatformSocialEmptyState(
          icon: Icons.error_outline,
          message: ApiException.userMessage(e),
        ),
        data: (detail) {
          if (detail.isEmpty) {
            return const PlatformSocialEmptyState(
              icon: Icons.search_off_rounded,
              message: 'Yarışma bulunamadı',
            );
          }
          final c = detail.contest;
          final name = (c['name'] ?? 'Yarışma').toString();
          final status = (c['status'] ?? '').toString();
          final desc = (c['description'] ?? '').toString();
          final participants = detail.ranked;
          final joined = detail.hasJoined(myId);
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
              if (!joined)
                PlatformSocialPrimaryButton(
                  label: 'Yarışmaya katıl',
                  icon: Icons.emoji_events_outlined,
                  loading: _joining,
                  onPressed: () => _join(context),
                )
              else
                PlatformSocialStatusPill(
                  label: detail.rankFor(myId) != null
                      ? '${detail.rankFor(myId)}. sıradasın'
                      : 'Yarışmadasın',
                  icon: Icons.check_circle_rounded,
                  tone: PlatformSocialPillTone.gold,
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
                  final rank = p.rank ?? (e.key + 1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PlatformSocialRankTile(
                      rank: rank,
                      highlight: rank <= 3,
                      title: p.name,
                      subtitle: myId != null && p.userId == myId
                          ? 'Sen'
                          : 'Katılımcı',
                      score: '${p.score} p',
                    ),
                  );
                }),
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
        ref.invalidate(cfcArenaContestDetailProvider(widget.contestId));
        ref.invalidate(cfcArenaContestsProvider);
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

}
