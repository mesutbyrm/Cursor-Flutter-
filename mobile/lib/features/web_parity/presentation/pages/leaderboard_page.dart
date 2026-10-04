import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/parity_models.dart';
import '../providers/parity_providers.dart';
import '../widgets/parity_widgets.dart';

const _periods = <(String, String)>[
  ('hourly', 'Saatlik'),
  ('daily', 'Günlük'),
  ('weekly', 'Haftalık'),
  ('monthly', 'Aylık'),
];

/// Liderlik: Top 100 (sesli oda / canlı yayın), VIP ve destekçi seviyeleri.
class LeaderboardsPage extends ConsumerStatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  ConsumerState<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends ConsumerState<LeaderboardsPage> {
  int _tab = 0;
  String _period = 'daily';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MockScaffold(
      title: 'Liderlik',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Sesli Oda')),
                ButtonSegment(value: 1, label: Text('Yayın')),
                ButtonSegment(value: 2, label: Text('VIP')),
                ButtonSegment(value: 3, label: Text('Destek')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          if (_tab < 2)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final p in _periods)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p.$2),
                        selected: _period == p.$1,
                        onSelected: (_) => setState(() => _period = p.$1),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: _content(c)),
        ],
      ),
    );
  }

  Widget _content(dynamic c) {
    if (_tab < 2) {
      final key = (_tab == 0 ? 'voice_room' : 'live_stream', _period);
      final v = ref.watch(top100Provider(key));
      return ParityAsync<LeaderboardResult>(
        value: v,
        onRetry: () => ref.invalidate(top100Provider(key)),
        isEmpty: (d) => d.entries.isEmpty,
        emptyIcon: Icons.emoji_events_outlined,
        emptyText: 'Bu dönemde sıralama yok',
        builder: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(top100Provider(key)),
          child: _list(d.entries, 'puan'),
        ),
      );
    }
    if (_tab == 2) {
      final v = ref.watch(vipLeaderboardProvider);
      return ParityAsync<LeaderboardResult>(
        value: v,
        onRetry: () => ref.invalidate(vipLeaderboardProvider),
        isEmpty: (d) => d.entries.isEmpty,
        emptyIcon: Icons.workspace_premium_outlined,
        emptyText: 'VIP sıralaması boş',
        builder: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(vipLeaderboardProvider),
          child: _list(d.entries, 'XP'),
        ),
      );
    }
    final v = ref.watch(mySupporterLevelsProvider);
    return ParityAsync<List<SupporterLevelRow>>(
      value: v,
      onRetry: () => ref.invalidate(mySupporterLevelsProvider),
      isEmpty: (d) => d.isEmpty,
      emptyIcon: Icons.favorite_border_rounded,
      emptyText: 'Henüz destekçi seviyen yok',
      builder: (d) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
        itemCount: d.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => ParityCard(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.accentPurple.withValues(alpha: 0.2),
                child: Text('${d[i].level}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  d[i].levelName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${d[i].totalContributed}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<LeaderboardEntry> items, String unit) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = items[i];
        final medal = switch (e.rank) {
          1 => const Color(0xFFFFC53D),
          2 => const Color(0xFFC0C6D0),
          3 => const Color(0xFFD08A4E),
          _ => null,
        };
        return ParityCard(
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: medal != null
                    ? Icon(Icons.emoji_events_rounded, color: medal)
                    : Text(
                        '${e.rank}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
              UserAvatar(url: e.image, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: e.isSelf ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                    if (e.subtitle != null)
                      Text(e.subtitle!, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              Text('${e.score} $unit',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}
