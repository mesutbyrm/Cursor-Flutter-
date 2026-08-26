import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/pk/pk_leaderboard_models.dart';
import '../providers/pk_room_providers.dart';

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// PK Liderlik — haftalık/aylık/sezon/tüm zamanlar · puan/galibiyet + kendi istatistiğim.
class PkLeaderboardPage extends ConsumerStatefulWidget {
  const PkLeaderboardPage({super.key});

  @override
  ConsumerState<PkLeaderboardPage> createState() => _PkLeaderboardPageState();
}

class _PkLeaderboardPageState extends ConsumerState<PkLeaderboardPage> {
  String _period = 'weekly';
  String _metric = 'score';

  static const _periods = [
    ('weekly', 'Haftalık'),
    ('monthly', 'Aylık'),
    ('season', 'Sezon'),
    ('alltime', 'Tüm Zamanlar'),
  ];

  @override
  Widget build(BuildContext context) {
    final key = (period: _period, metric: _metric);
    final board = ref.watch(pkLeaderboardProvider(key));
    final myStats = ref.watch(pkStatsProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('PK Liderlik'),
      ),
      body: Column(
        children: [
          myStats.maybeWhen(
            data: (s) => s.total > 0 ? _MyStatsCard(stats: s) : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'score', label: Text('Puan')),
                ButtonSegment(value: 'wins', label: Text('Galibiyet')),
              ],
              selected: {_metric},
              onSelectionChanged: (v) => setState(() => _metric = v.first),
              showSelectedIcon: false,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final p in _periods)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p.$2),
                      selected: _period == p.$1,
                      onSelected: (_) => setState(() => _period = p.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: board.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ApiException.userMessage(e),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0x99FFFFFF)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(pkLeaderboardProvider(key)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (rows) => rows.isEmpty
                  ? const Center(
                      child: Text('Bu dönemde henüz veri yok.',
                          style: TextStyle(color: Color(0x99FFFFFF))))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(pkLeaderboardProvider(key)),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: rows.length,
                        itemBuilder: (_, i) =>
                            _RankRow(entry: rows[i], metric: _metric),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyStatsCard extends StatelessWidget {
  const _MyStatsCard({required this.stats});
  final PkStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2A1660), Color(0xFF14093A)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${stats.wins}G', 'Galibiyet', const Color(0xFF66E36F)),
          _stat('${stats.losses}M', 'Mağlubiyet', const Color(0xFFFF6E6E)),
          _stat('%${stats.computedWinRate}', 'Oran', const Color(0xFFB388FF)),
          _stat('${stats.streak}', 'Seri', const Color(0xFFFFD54F)),
          _stat(_fmt(stats.bestScore), 'En İyi', const Color(0xFF40C4FF)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5)),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.metric});
  final PkLeaderboardEntry entry;
  final String metric;

  Color get _rankColor => switch (entry.rank) {
        1 => const Color(0xFFFFD54F),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => Colors.white54,
      };

  @override
  Widget build(BuildContext context) {
    final value = metric == 'wins' ? '${entry.wins} galibiyet' : _fmt(entry.score);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1030),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${entry.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _rankColor, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A1A45),
            backgroundImage: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                ? canlifalImageProvider(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white54, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.displayName ?? 'Yayıncı',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Row(
            children: [
              Icon(metric == 'wins' ? Icons.emoji_events_rounded : Icons.bolt_rounded,
                  color: const Color(0xFFFFD54F), size: 14),
              const SizedBox(width: 3),
              Text(value,
                  style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
