import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/images/canlifal_network_image.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/discover/discover_tab_pages.dart';
import '../data/football_remote_datasource.dart';
import '../domain/football_models.dart';

/// `/football` — maçlar, puan durumu ve gol krallığı.
class FootballPage extends StatelessWidget {
  const FootballPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: DiscoverSubPage(
        title: 'Futbol',
        subtitle: 'Maçlar, puan durumu, gol krallığı',
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Maçlar'),
                Tab(text: 'Puan durumu'),
                Tab(text: 'Gol krallığı'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _MatchesTab(),
                  _CompetitionTab(builder: (code) => _StandingsView(code: code)),
                  _CompetitionTab(builder: (code) => _ScorersView(code: code)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchesTab extends ConsumerStatefulWidget {
  const _MatchesTab();

  @override
  ConsumerState<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<_MatchesTab>
    with AutomaticKeepAliveClientMixin {
  var _offset = 0;

  @override
  bool get wantKeepAlive => true;

  DateTime get _day {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + _offset);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final day = _day;
    final async = ref.watch(footballMatchesProvider(day));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              for (final (offset, label) in const [(-1, 'Dün'), (0, 'Bugün'), (1, 'Yarın')])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _offset == offset,
                    onSelected: (_) => setState(() => _offset = offset),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(footballMatchesProvider(day).future),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _Empty(text: ApiException.userMessage(e)),
              data: (matches) {
                if (matches.isEmpty) {
                  return const _Empty(text: 'Bu tarihte maç yok.');
                }
                final groups = <String, List<FootballMatch>>{};
                for (final m in matches) {
                  groups
                      .putIfAbsent('${m.competitionFlag} ${m.competitionName}', () => [])
                      .add(m);
                }
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      for (final m in entry.value) _MatchTile(match: m),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final FootballMatch match;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = match.utcDate?.toLocal();
    final center = match.hasScore && (match.isLive || match.isFinished)
        ? '${match.homeGoals} - ${match.awayGoals}'
        : t == null
            ? '—'
            : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: _TeamLabel(team: match.home, alignEnd: true)),
            SizedBox(
              width: 86,
              child: Column(
                children: [
                  Text(
                    center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: match.isLive ? Colors.red : c.onSurface,
                    ),
                  ),
                  if (match.statusLabel.isNotEmpty)
                    Text(
                      match.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: match.isLive ? Colors.red : c.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _TeamLabel(team: match.away)),
          ],
        ),
      ),
    );
  }
}

class _TeamLabel extends StatelessWidget {
  const _TeamLabel({required this.team, this.alignEnd = false});

  final FootballTeam team;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final name = Flexible(
      child: Text(
        team.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    final crest = _Crest(url: team.crest);
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [name, const SizedBox(width: 6), crest]
          : [crest, const SizedBox(width: 6), name],
    );
  }
}

class _Crest extends StatelessWidget {
  const _Crest({required this.url, this.size = 22});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = url;
    // football-data SVG armaları raster yükleyicide açılmaz.
    if (u == null || !u.startsWith('http') || u.toLowerCase().endsWith('.svg')) {
      return Icon(Icons.shield_outlined, size: size);
    }
    return CanlifalNetworkImage(
      url: u,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorWidget: Icon(Icons.shield_outlined, size: size),
    );
  }
}

class _CompetitionTab extends StatefulWidget {
  const _CompetitionTab({required this.builder});

  final Widget Function(String code) builder;

  @override
  State<_CompetitionTab> createState() => _CompetitionTabState();
}

class _CompetitionTabState extends State<_CompetitionTab>
    with AutomaticKeepAliveClientMixin {
  var _code = footballCompetitions.first.$1;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: DropdownButtonFormField<String>(
            initialValue: _code,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Lig'),
            items: [
              for (final (code, name, flag) in footballCompetitions)
                DropdownMenuItem(value: code, child: Text('$flag  $name')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _code = v);
            },
          ),
        ),
        Expanded(child: widget.builder(_code)),
      ],
    );
  }
}

class _StandingsView extends ConsumerWidget {
  const _StandingsView({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(footballStandingsProvider(code));
    final c = context.colors;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(footballStandingsProvider(code).future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Empty(text: ApiException.userMessage(e)),
        data: (rows) {
          if (rows.isEmpty) {
            return const _Empty(text: 'Bu lig için puan durumu yok.');
          }
          final head = TextStyle(
            color: c.onSurfaceMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          );
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Row(
                children: [
                  SizedBox(width: 26, child: Text('#', style: head)),
                  Expanded(child: Text('Takım', style: head)),
                  for (final h in const ['O', 'G', 'B', 'M', 'AV', 'P'])
                    SizedBox(
                      width: 30,
                      child: Text(h, textAlign: TextAlign.center, style: head),
                    ),
                ],
              ),
              const Divider(),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${r.position}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _Crest(url: r.team.crest, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      for (final v in [r.played, r.won, r.draw, r.lost, r.goalDifference])
                        SizedBox(
                          width: 30,
                          child: Text('$v', textAlign: TextAlign.center),
                        ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${r.points}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ScorersView extends ConsumerWidget {
  const _ScorersView({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(footballScorersProvider(code));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(footballScorersProvider(code).future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Empty(text: ApiException.userMessage(e)),
        data: (rows) {
          if (rows.isEmpty) {
            return const _Empty(text: 'Bu lig için gol krallığı verisi yok.');
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final s = rows[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(
                  s.player,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(s.team.name),
                trailing: Text(
                  '${s.goals} gol',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(Icons.sports_soccer_rounded, size: 48, color: context.colors.onSurfaceMuted),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
