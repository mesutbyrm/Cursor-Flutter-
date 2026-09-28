import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover/discover_tab_pages.dart';
import '../../domain/dream_contest.dart';
import '../providers/dream_contest_providers.dart';

String _day(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}.${l.year}';
}

/// `/dreams/contest` — aktif rüya yorumlama yarışmaları.
class DreamContestListPage extends ConsumerWidget {
  const DreamContestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dreamContestsProvider);
    Future<void> refresh() async {
      ref.invalidate(dreamContestsProvider);
      await ref.read(dreamContestsProvider.future);
    }

    return DiscoverSubPage(
      title: 'Rüya Yarışması',
      subtitle: 'Rüyayı yorumla, oyları topla',
      onRefresh: refresh,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            icon: Icons.cloud_off_rounded,
            text: ApiException.userMessage(e),
            onRetry: refresh,
          ),
          data: (contests) {
            if (contests.isEmpty) {
              return _Message(
                icon: Icons.nights_stay_rounded,
                text: 'Şu an aktif rüya yarışması yok.',
                onRetry: refresh,
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: contests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _ContestCard(contest: contests[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ContestCard extends StatelessWidget {
  const _ContestCard({required this.contest});

  final DreamContest contest;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/dreams/contest/${contest.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contest.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusChip(contest: contest),
                ],
              ),
              if (contest.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  contest.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '${_day(contest.startDate)} – ${_day(contest.endDate)} · ${contest.entryCount} yorum',
                style: TextStyle(
                  color: c.onSurfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.contest});

  final DreamContest contest;

  @override
  Widget build(BuildContext context) {
    final (label, color) = contest.isEnded
        ? ('Bitti', context.colors.onSurfaceMuted)
        : contest.isOngoing
            ? ('Devam ediyor', Colors.green)
            : ('Yakında', context.colors.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// `/dreams/contest/:id` — rüya metni, yorum gönderme ve oylama.
class DreamContestDetailPage extends ConsumerStatefulWidget {
  const DreamContestDetailPage({super.key, required this.contestId});

  final String contestId;

  @override
  ConsumerState<DreamContestDetailPage> createState() =>
      _DreamContestDetailPageState();
}

class _DreamContestDetailPageState
    extends ConsumerState<DreamContestDetailPage> {
  static const _minLength = 20;

  final _controller = TextEditingController();
  var _submitting = false;
  final _voting = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh() async {
    ref.invalidate(dreamContestEntriesProvider(widget.contestId));
    ref.invalidate(dreamContestsProvider);
    await ref.read(dreamContestEntriesProvider(widget.contestId).future);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.length < _minLength) {
      _toast('Yorum en az $_minLength karakter olmalı.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(dreamsRemoteDataSourceProvider)
          .postContestEntry(widget.contestId, {'interpretation': text});
      _controller.clear();
      _toast('Yorumun yarışmaya eklendi.');
      await _refresh();
    } catch (e) {
      _toast(ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _vote(String entryId) async {
    if (_voting.contains(entryId)) return;
    setState(() => _voting.add(entryId));
    try {
      await ref
          .read(dreamsRemoteDataSourceProvider)
          .voteContest(widget.contestId, {'entryId': entryId});
      await _refresh();
    } catch (e) {
      _toast(ApiException.userMessage(e));
    } finally {
      if (mounted) setState(() => _voting.remove(entryId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final contests = ref.watch(dreamContestsProvider).valueOrNull ?? const [];
    DreamContest? contest;
    for (final c in contests) {
      if (c.id == widget.contestId) contest = c;
    }
    final entriesAsync = ref.watch(dreamContestEntriesProvider(widget.contestId));
    final myId = ref.watch(currentUserIdProvider);
    final c = context.colors;

    return DiscoverSubPage(
      title: contest?.title ?? 'Rüya Yarışması',
      subtitle: contest == null
          ? null
          : '${_day(contest.startDate)} – ${_day(contest.endDate)}',
      onRefresh: _refresh,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (contest != null) ...[
              if (contest.description.isNotEmpty)
                Text(
                  contest.description,
                  style: TextStyle(color: c.onSurfaceVariant, height: 1.35),
                ),
              if (contest.dreamPrompt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yorumlanacak rüya',
                        style: TextStyle(
                          color: c.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contest.dreamPrompt,
                        style: TextStyle(color: c.onSurface, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (contest.acceptsEntries) _entryForm(context),
            ],
            const SizedBox(height: 8),
            Text(
              'Yorumlar',
              style: TextStyle(
                color: c.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            entriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(ApiException.userMessage(e)),
              data: (data) {
                if (data.entries.isEmpty) {
                  return Text(
                    'Henüz yorum yok. İlk yorumu sen yaz!',
                    style: TextStyle(color: c.onSurfaceVariant),
                  );
                }
                final canVote = contest?.acceptsEntries ?? true;
                return Column(
                  children: [
                    for (var i = 0; i < data.entries.length; i++)
                      _EntryTile(
                        rank: i + 1,
                        entry: data.entries[i],
                        voted: data.votedEntryIds.contains(data.entries[i].id),
                        busy: _voting.contains(data.entries[i].id),
                        onVote: canVote &&
                                myId != null &&
                                data.entries[i].userId != myId
                            ? () => _vote(data.entries[i].id)
                            : null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 8,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'Bu rüyayı sen nasıl yorumlarsın? (en az 20 karakter)',
                border: InputBorder.none,
              ),
            ),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: const Text('Yorumu gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.rank,
    required this.entry,
    required this.voted,
    required this.busy,
    required this.onVote,
  });

  final int rank;
  final DreamContestEntry entry;
  final bool voted;
  final bool busy;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final image = entry.userImage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                ClipOval(
                  child: image != null && image.startsWith('http')
                      ? CanlifalNetworkImage(
                          url: image,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 28,
                          height: 28,
                          color: c.surfaceContainer,
                          child: const Icon(Icons.person_rounded, size: 18),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onVote,
                  icon: Icon(
                    voted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: voted ? context.accentPink : null,
                    size: 18,
                  ),
                  label: Text('${entry.voteCount}'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(entry.interpretation, style: const TextStyle(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 48, color: context.colors.onSurfaceMuted),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene'),
            ),
          ),
        ],
      ],
    );
  }
}
