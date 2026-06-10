import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/discover/discover_segmented_tabs.dart';
import '../../../../../core/widgets/discover_tab_layout.dart';
import '../../../domain/game_center_models.dart';
import '../providers/game_center_providers.dart';

class GameCenterLeaderboardPage extends ConsumerStatefulWidget {
  const GameCenterLeaderboardPage({super.key});

  @override
  ConsumerState<GameCenterLeaderboardPage> createState() =>
      _GameCenterLeaderboardPageState();
}

class _GameCenterLeaderboardPageState
    extends ConsumerState<GameCenterLeaderboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) setState(() {});
      });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  LeaderboardPeriod get _period =>
      LeaderboardPeriod.values[_tabs.index];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameCenterLeaderboardProvider(_period));

    return DiscoverSubPage(
      title: 'Liderlik Tablosu',
      subtitle: _period.label,
      onRefresh: () async {
        ref.invalidate(gameCenterLeaderboardProvider(_period));
        await ref.read(gameCenterLeaderboardProvider(_period).future);
      },
      body: Column(
        children: [
          DiscoverSegmentedTabs(
            controller: _tabs,
            tabs: const [
              (label: 'Günlük', icon: Icons.today_rounded),
              (label: 'Haftalık', icon: Icons.date_range_rounded),
              (label: 'Aylık', icon: Icons.calendar_month_rounded),
            ],
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Liste yüklenemedi')),
              data: (entries) {
                final top3 = entries.take(3).toList();
                final rest = entries.length > 3
                    ? entries.sublist(3)
                    : <LeaderboardEntry>[];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                  children: [
                    if (top3.isNotEmpty) _Podium(entries: top3),
                    const SizedBox(height: 16),
                    ...rest.map((e) => _RankTile(entry: e)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ordered = <LeaderboardEntry?>[
      entries.length > 1 ? entries[1] : null,
      entries.isNotEmpty ? entries[0] : null,
      entries.length > 2 ? entries[2] : null,
    ];
    const heights = [72.0, 96.0, 64.0];
    const medals = ['🥈', '🥇', '🥉'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final entry = ordered[i];
        return Expanded(
          child: Column(
            children: [
              Text(medals[i], style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              if (entry != null) ...[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.2),
                  child: Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                Text(
                  NumberFormat.decimalPattern('tr').format(entry.score),
                  style: TextStyle(
                    color: context.coinGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
              SizedBox(height: heights[i]),
              Container(
                height: heights[i],
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.colors.primary.withValues(alpha: 0.35),
                      context.colors.primary.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${entry.rank ?? '-'}'),
        ),
        title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: Text(
          NumberFormat.decimalPattern('tr').format(entry.score),
          style: TextStyle(
            color: context.coinGold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
