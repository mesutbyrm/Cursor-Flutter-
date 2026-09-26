import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/cfc_arena_repository.dart';
import '../../domain/cfc_arena_contest_detail.dart';
import '../providers/cfc_arena_providers.dart';

/// Katılımcılar ve puan durumu — sesli oda ve canlı yayında aynı popup.
Future<void> showCfcArenaContestSheet(
  BuildContext context,
  WidgetRef ref, {
  required String contestId,
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CfcArenaContestSheet(contestId: contestId, title: title),
  );
}

class _CfcArenaContestSheet extends ConsumerStatefulWidget {
  const _CfcArenaContestSheet({required this.contestId, required this.title});

  final String contestId;
  final String title;

  @override
  ConsumerState<_CfcArenaContestSheet> createState() =>
      _CfcArenaContestSheetState();
}

class _CfcArenaContestSheetState extends ConsumerState<_CfcArenaContestSheet> {
  var _joining = false;

  Future<void> _join() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      await ref.read(cfcArenaRepositoryProvider).joinContest(widget.contestId);
      ref.invalidate(cfcArenaContestDetailProvider(widget.contestId));
      ref.invalidate(cfcArenaContestsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yarışmaya katıldınız')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(cfcArenaContestDetailProvider(widget.contestId));
    final myId = ref.watch(authControllerProvider).valueOrNull?.id;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yenile',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.invalidate(
                        cfcArenaContestDetailProvider(widget.contestId),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _Message(
                    icon: Icons.cloud_off_rounded,
                    // Veri gelmediğinde sahte katılımcı/puan gösterilmez.
                    text: 'Sıralama yüklenemedi.\n${ApiException.userMessage(e)}',
                  ),
                  data: (detail) => _Body(
                    detail: detail,
                    myId: myId,
                    controller: controller,
                    joining: _joining,
                    onJoin: _join,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.detail,
    required this.myId,
    required this.controller,
    required this.joining,
    required this.onJoin,
  });

  final CfcArenaContestDetail detail;
  final String? myId;
  final ScrollController controller;
  final bool joining;
  final Future<void> Function() onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = detail.ranked;
    final joined = detail.hasJoined(myId);
    final myRank = detail.rankFor(myId);
    final myEntry = detail.entryFor(myId);
    final remaining = cfcContestRemaining(detail.contest, DateTime.now());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Row(
            children: [
              _Chip(
                icon: Icons.groups_rounded,
                label: '${ranked.length} katılımcı',
              ),
              const SizedBox(width: 8),
              if (remaining != null)
                _Chip(
                  icon: Icons.timer_outlined,
                  label: formatCfcRemaining(remaining),
                ),
              const Spacer(),
              if (!joined)
                FilledButton(
                  onPressed: joining ? null : () => onJoin(),
                  child: joining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Katıl'),
                )
              else
                _Chip(
                  icon: Icons.check_circle_rounded,
                  label: myRank != null ? '$myRank. sıradasın' : 'Katıldın',
                ),
            ],
          ),
        ),
        if (joined && myEntry != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    myRank != null ? '#$myRank' : '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Senin puanın',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    '${myEntry.score}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ranked.isEmpty
              ? const _Message(
                  icon: Icons.emoji_events_outlined,
                  text: 'Bu yarışmada henüz katılımcı yok.',
                )
              : ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: ranked.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = ranked[i];
                    final rank = e.rank ?? (i + 1);
                    final mine = myId != null && e.userId == myId;
                    return ListTile(
                      dense: true,
                      leading: _RankBadge(rank: rank, image: e.image),
                      title: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              mine ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                      trailing: Text(
                        '${e.score}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, this.image});

  final int rank;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return SizedBox(
      width: 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 18))
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 14,
            backgroundImage: (image != null && image!.isNotEmpty)
                ? NetworkImage(image!)
                : null,
            child: (image == null || image!.isEmpty)
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
