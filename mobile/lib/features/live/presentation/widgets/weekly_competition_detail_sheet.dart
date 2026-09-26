import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/pk/weekly_broadcaster_competition_models.dart';
import '../providers/weekly_broadcaster_competition_provider.dart';

/// Yarışma detayı — katılımcılar, sıralama, puanlar ve kalan süre.
///
/// Kutuya dokununca açılır. Veriler sunucudan gelir; yüklenemezse sahte
/// katılımcı veya puan gösterilmez, durum açıkça bildirilir.
Future<void> showWeeklyCompetitionDetailSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WeeklyCompetitionDetailSheet(),
  );
}

class _WeeklyCompetitionDetailSheet extends ConsumerWidget {
  const _WeeklyCompetitionDetailSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(weeklyBroadcasterCompetitionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const _SheetGrabber(),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _MessageBody(
                    icon: Icons.wifi_off_rounded,
                    title: 'Yarışma bilgisi alınamadı',
                    detail: 'Bağlantınızı kontrol edip tekrar deneyin.',
                    onRetry: () => _refresh(ref),
                  ),
                  data: (competition) {
                    if (competition == null) {
                      return _MessageBody(
                        icon: Icons.emoji_events_outlined,
                        title: 'Aktif yarışma yok',
                        detail: 'Yeni yarışma başladığında burada görünecek.',
                        onRetry: () => _refresh(ref),
                      );
                    }
                    return _CompetitionBody(
                      competition: competition,
                      scrollController: scrollController,
                      onRefresh: () => _refresh(ref),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(weeklyBroadcasterCompetitionCacheProvider);
    ref.invalidate(weeklyBroadcasterCompetitionProvider);
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CompetitionBody extends ConsumerWidget {
  const _CompetitionBody({
    required this.competition,
    required this.scrollController,
    required this.onRefresh,
  });

  final WeeklyBroadcasterCompetition competition;
  final ScrollController scrollController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final phase = competition.phaseAt(now);
    final userId = ref.watch(authControllerProvider).valueOrNull?.id;
    final mine = competition.entryFor(userId);
    final participants = competition.participants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  competition.displayTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Yenile',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(phase: phase),
              _InfoChip(
                icon: Icons.groups_rounded,
                label: '${participants.length} katılımcı',
              ),
              if (phase != WeeklyCompetitionPhase.finished)
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: _remainingLabel(competition, now),
                ),
            ],
          ),
        ),
        if (competition.startsAt != null || competition.endsAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              _rangeLabel(competition),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (mine != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _MyRankCard(entry: mine),
          ),
        const Divider(height: 1),
        Expanded(
          child: participants.isEmpty
              ? _MessageBody(
                  icon: Icons.emoji_events_outlined,
                  title: 'Henüz katılımcı yok',
                  detail: phase == WeeklyCompetitionPhase.upcoming
                      ? 'Yarışma başladığında sıralama burada görünecek.'
                      : 'Sıralama oluştuğunda burada görünecek.',
                  onRetry: onRefresh,
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: participants.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return _ParticipantTile(
                      entry: p,
                      highlight: userId != null && p.userId == userId,
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _remainingLabel(
    WeeklyBroadcasterCompetition competition,
    DateTime now,
  ) {
    final left = competition.remainingAt(now);
    if (left == null) return 'Süre bilgisi yok';
    if (left.inDays >= 1) return '${left.inDays} gün kaldı';
    if (left.inHours >= 1) return '${left.inHours} saat kaldı';
    if (left.inMinutes >= 1) return '${left.inMinutes} dakika kaldı';
    return 'Bitmek üzere';
  }

  static String _rangeLabel(WeeklyBroadcasterCompetition competition) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final start = competition.startsAt;
    final end = competition.endsAt;
    if (start != null && end != null) return '${fmt(start)} — ${fmt(end)}';
    if (start != null) return 'Başlangıç: ${fmt(start)}';
    return 'Bitiş: ${fmt(end!)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.phase});

  final WeeklyCompetitionPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (phase) {
      WeeklyCompetitionPhase.upcoming => ('Yakında', scheme.tertiary),
      WeeklyCompetitionPhase.running => ('Devam ediyor', scheme.primary),
      WeeklyCompetitionPhase.finished => ('Sona erdi', scheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({required this.entry});

  final WeeklyBroadcasterCompetitionParticipant entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sizin sıranız',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
          Text(
            '${entry.score} puan',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.entry, required this.highlight});

  final WeeklyBroadcasterCompetitionParticipant entry;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final avatar = entry.avatarUrl?.trim() ?? '';
    return Container(
      color: highlight ? scheme.primary.withValues(alpha: 0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              _rankLabel(entry.rank),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: entry.rank <= 3 ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.surfaceContainerHighest,
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Icon(Icons.person, size: 18, color: scheme.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName?.trim().isNotEmpty == true
                  ? entry.displayName!.trim()
                  : 'Katılımcı',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.score}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static String _rankLabel(int rank) => switch (rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '#$rank',
      };
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.icon,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yenile'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
