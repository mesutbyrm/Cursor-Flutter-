import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../cfc_arena/data/cfc_arena_repository.dart';
import '../../../../cfc_arena/domain/cfc_arena_contest_filters.dart';
import '../../../../cfc_arena/domain/cfc_arena_context.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import '../../../../cfc_arena/presentation/providers/cfc_arena_providers.dart';
import '../../../../cfc_arena/presentation/widgets/cfc_arena_contest_sheet.dart';
import '../../../../cfc_arena/presentation/widgets/cfc_arena_room_banner.dart';
import '../../../../live/presentation/providers/weekly_broadcaster_competition_provider.dart';
import '../../../../live/presentation/providers/weekly_broadcaster_visibility_provider.dart';
import '../../../../live/presentation/widgets/weekly_competition_detail_sheet.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_room_side_action_rail.dart';

/// Sağ rail — sezon + haftalık yarışma (Ayarlar/Müzik ile aynı kutu stili).
class VoiceRoomCompetitionRailSlot extends ConsumerWidget {
  const VoiceRoomCompetitionRailSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _CfcArenaRailButton(),
        if (ref.watch(weeklyBroadcasterCompetitionVisibleProvider)) ...[
          const SizedBox(height: 12),
          const _WeeklyBroadcasterRailButton(),
        ],
      ],
    );
  }
}

class _WeeklyBroadcasterRailButton extends ConsumerWidget {
  const _WeeklyBroadcasterRailButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyBroadcasterCompetitionProvider);
    return async.maybeWhen(
      data: (comp) {
        if (comp == null || comp.participants.isEmpty) {
          return const SizedBox.shrink();
        }
        return VoiceRoomRailIconButton(
          icon: Icons.emoji_events_outlined,
          label: 'Haftalık',
          color: VoiceRoomTokens.gold,
          onTap: () => showWeeklyCompetitionDetailSheet(context),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _CfcArenaRailButton extends ConsumerStatefulWidget {
  const _CfcArenaRailButton();

  @override
  ConsumerState<_CfcArenaRailButton> createState() =>
      _CfcArenaRailButtonState();
}

class _CfcArenaRailButtonState extends ConsumerState<_CfcArenaRailButton> {
  var _joining = false;

  Future<void> _open() async {
    final contests = ref
        .read(cfcArenaContestsForSurfaceProvider(CfcArenaSurface.voiceRoom))
        .valueOrNull;
    if (contests == null || contests.isEmpty) return;
    final primary = contests.first;
    final contestId = cfcContestId(primary);
    if (contestId.isEmpty) return;
    final name = (primary['name'] ?? 'Sezon yarışması').toString().trim();

    final detail =
        ref.read(cfcArenaContestDetailProvider(contestId)).valueOrNull;
    final myId = ref.read(authControllerProvider).valueOrNull?.id;
    final joined = detail?.hasJoined(myId) ?? false;
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
    final async =
        ref.watch(cfcArenaContestsForSurfaceProvider(CfcArenaSurface.voiceRoom));
    final contests = async.valueOrNull;
    if (contests == null || contests.isEmpty) return const SizedBox.shrink();

    return VoiceRoomRailIconButton(
      icon: Icons.military_tech_rounded,
      label: _joining ? '…' : 'Sezon',
      color: VoiceRoomTokens.neonPink,
      onTap: _joining ? () {} : _open,
    );
  }
}
