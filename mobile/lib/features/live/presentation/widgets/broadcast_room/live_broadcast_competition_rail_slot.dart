import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cfc_arena/data/cfc_arena_repository.dart';
import '../../../../cfc_arena/domain/cfc_arena_contest_filters.dart';
import '../../../../cfc_arena/domain/cfc_arena_context.dart';
import '../../../../cfc_arena/domain/cfc_arena_contest_detail.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import '../../../../cfc_arena/presentation/providers/cfc_arena_providers.dart';
import '../../../../cfc_arena/presentation/widgets/cfc_arena_contest_sheet.dart';
import '../../../../cfc_arena/presentation/widgets/cfc_arena_room_banner.dart';
import '../../../../live/presentation/providers/weekly_broadcaster_competition_provider.dart';
import '../../../../live/presentation/providers/weekly_broadcaster_visibility_provider.dart';
import '../../../../live/presentation/widgets/weekly_competition_detail_sheet.dart';
import '../../../../voice_hub/presentation/theme/voice_room_tokens.dart';

/// Canlı yayın sağ rail — sezon + haftalık (sesli oda ile aynı kutu stili).
class LiveBroadcastCompetitionRailSlot extends ConsumerWidget {
  const LiveBroadcastCompetitionRailSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _LiveCfcRailButton(),
        if (ref.watch(weeklyBroadcasterCompetitionVisibleProvider)) ...[
          const SizedBox(height: 12),
          const _LiveWeeklyRailButton(),
        ],
      ],
    );
  }
}

class _LiveWeeklyRailButton extends ConsumerWidget {
  const _LiveWeeklyRailButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyBroadcasterCompetitionProvider);
    return async.maybeWhen(
      data: (comp) {
        if (comp == null || comp.participants.isEmpty) {
          return const SizedBox.shrink();
        }
        final sorted = [...comp.participants]
          ..sort((a, b) => b.score.compareTo(a.score));
        final lead = sorted.first;
        return LiveCompetitionRailCard(
          icon: Icons.emoji_events_outlined,
          title: 'Haftalık',
          line:
              '1. ${shortCompetitionName(lead.displayName ?? '—')} ${formatCompetitionScore(lead.score)}',
          color: VoiceRoomTokens.gold,
          onTap: () => showWeeklyCompetitionDetailSheet(context),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _LiveCfcRailButton extends ConsumerStatefulWidget {
  const _LiveCfcRailButton();

  @override
  ConsumerState<_LiveCfcRailButton> createState() => _LiveCfcRailButtonState();
}

class _LiveCfcRailButtonState extends ConsumerState<_LiveCfcRailButton> {
  var _joining = false;

  Future<void> _open() async {
    final contests = ref
        .read(
          cfcArenaContestsForSurfaceProvider(CfcArenaSurface.liveBroadcast),
        )
        .valueOrNull;
    if (contests == null || contests.isEmpty) return;
    final primary = contests.first;
    final contestId = cfcContestId(primary);
    if (contestId.isEmpty) return;
    final name = (primary['name'] ?? 'Sezon yarışması').toString().trim();

    // Katılım durumu yüklenmeden karar verilirse (valueOrNull == null) katılmış
    // kullanıcıya da her seferinde «Katıl» sorulurdu — önce detayı bekle.
    CfcArenaContestDetail? detail;
    try {
      detail = await ref.read(cfcArenaContestDetailProvider(contestId).future);
    } catch (_) {
      detail = null;
    }
    if (!mounted) return;
    final myId = ref.read(authControllerProvider).valueOrNull?.id;
    // Detay alınamadıysa soru sorma (yanlış «Katıl» istemini önler).
    final joined = detail == null || detail.hasJoined(myId);
    final dismissed =
        ref.read(cfcArenaDismissedInvitesProvider).contains(contestId);

    if (!joined && !dismissed && mounted) {
      final join = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(name),
          content: Text(
            'Sezon yarışmasına katılmak ister misiniz?\n'
            '${cfcContestParticipantCount(primary)} katılımcı',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Sonra'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Katıl'),
            ),
          ],
        ),
      );
      if (join == true && mounted) {
        setState(() => _joining = true);
        try {
          await ref.read(cfcArenaRepositoryProvider).joinContest(contestId);
          ref.invalidate(cfcArenaContestDetailProvider(contestId));
          ref.invalidate(cfcArenaContestsProvider);
          ref.read(cfcArenaDismissedInvitesProvider.notifier).state = {
            ...ref.read(cfcArenaDismissedInvitesProvider),
            contestId,
          };
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sezon yarışmasına katıldınız')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
        } finally {
          if (mounted) setState(() => _joining = false);
        }
      } else if (join == false) {
        ref.read(cfcArenaDismissedInvitesProvider.notifier).state = {
          ...ref.read(cfcArenaDismissedInvitesProvider),
          contestId,
        };
      }
    }

    if (!mounted) return;
    await showCfcArenaContestSheet(
      context,
      ref,
      contestId: contestId,
      title: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      cfcArenaContestsForSurfaceProvider(CfcArenaSurface.liveBroadcast),
    );
    final contests = async.valueOrNull;
    if (contests == null || contests.isEmpty) return const SizedBox.shrink();

    // Puan satırı: katıldıysan «#sıra · puan», değilse lider.
    final contestId = cfcContestId(contests.first);
    final detail = contestId.isEmpty
        ? null
        : ref.watch(cfcArenaContestDetailProvider(contestId)).valueOrNull;
    final myId = ref.watch(authControllerProvider).valueOrNull?.id;
    String? line;
    if (detail != null && detail.entries.isNotEmpty) {
      final mine = detail.entryFor(myId);
      if (mine != null) {
        line = '#${detail.rankFor(myId) ?? '-'} · ${formatCompetitionScore(mine.score)}';
      } else {
        final lead = detail.ranked.first;
        line = '1. ${shortCompetitionName(lead.name)} ${formatCompetitionScore(lead.score)}';
      }
    }

    return LiveCompetitionRailCard(
      icon: Icons.military_tech_rounded,
      title: _joining ? '…' : 'Sezon',
      line: line,
      color: VoiceRoomTokens.neonPink,
      onTap: _joining ? () {} : _open,
    );
  }
}

String formatCompetitionScore(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return '$v';
}

String shortCompetitionName(String n) {
  final t = n.trim();
  return t.length <= 7 ? t : '${t.substring(0, 6)}…';
}

/// Yarışma rail kutusu — ikon + başlık + tek satır puan/sıra bilgisi.
class LiveCompetitionRailCard extends StatelessWidget {
  const LiveCompetitionRailCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.line,
  });

  final IconData icon;
  final String title;
  final String? line;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 84,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              if (line != null) ...[
                const SizedBox(height: 2),
                Text(
                  line!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
