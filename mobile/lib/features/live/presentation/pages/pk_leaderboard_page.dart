import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../admin/presentation/widgets/admin_user_hub_launcher.dart';
import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
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

    return PlatformSocialScaffold(
      title: 'PK Liderlik',
      subtitle: 'Haftalık · aylık · sezon',
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
              error: (_, __) => const Center(
                child: Text('Liderlik yüklenemedi.',
                    style: TextStyle(color: Color(0x99FFFFFF))),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: PlatformSocialGlassCard(
      gradient: PlatformSocialPalette.heroGradient,
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

class _RankRow extends ConsumerWidget {
  const _RankRow({required this.entry, required this.metric});
  final PkLeaderboardEntry entry;
  final String metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = metric == 'wins' ? '${entry.wins} galibiyet' : _fmt(entry.score);
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PlatformSocialRankTile(
        rank: entry.rank,
        title: entry.displayName ?? 'Yayıncı',
        subtitle: metric == 'wins' ? 'Galibiyet sıralaması' : 'Puan sıralaması',
        score: value,
        highlight: entry.rank <= 3,
      ),
    );
    if (entry.userId.isEmpty) return tile;
    return GestureDetector(
      onLongPress: () {
        final access = ref.read(staffAccessProvider);
        if (AdminUserHubLauncher.canOpen(access)) {
          AdminUserHubLauncher.open(context, userId: entry.userId);
        }
      },
      child: tile,
    );
  }
}
