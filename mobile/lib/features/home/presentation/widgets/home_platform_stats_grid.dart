import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../feed/domain/entities/platform_stats_entity.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Genişletilmiş canlı istatistik ızgarası — `GET /api/public-stats`.
class HomePlatformStatsGrid extends ConsumerWidget {
  const HomePlatformStatsGrid({super.key});

  static String _format(int n) =>
      NumberFormat.compact(locale: 'tr').format(n);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider);
    return stats.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final tiles = _tilesFor(data);
        if (tiles.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '📊',
              title: 'Canlı İstatistikler',
              actionLabel: 'Detay >',
              onAction: () => context.push('/profile/broadcaster-stats'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final tileW = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final tile in tiles)
                        SizedBox(
                          width: tileW,
                          child: _StatTile(tile: tile),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static List<_StatTileData> _tilesFor(PlatformStatsEntity data) {
    final tiles = <_StatTileData>[
      if (data.inGames > 0)
        _StatTileData(
          icon: Icons.sports_esports_rounded,
          color: const Color(0xFFFF8A3D),
          label: 'Oyunlarda',
          value: _format(data.inGames),
        ),
      if (data.inSocial > 0)
        _StatTileData(
          icon: Icons.people_rounded,
          color: const Color(0xFFFF4D8D),
          label: 'Sosyalde',
          value: _format(data.inSocial),
        ),
      if (data.fortuneActive > 0)
        _StatTileData(
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF9B5CFF),
          label: 'Fal Baktıran',
          value: _format(data.fortuneActive),
        ),
      if (data.browsing > 0)
        _StatTileData(
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF3DFF8A),
          label: 'Dolaşanlar',
          value: _format(data.browsing),
        ),
      if (data.todayLogins > 0)
        _StatTileData(
          icon: Icons.trending_up_rounded,
          color: HomeApprovedDesign.gold,
          label: 'Bugünkü Giriş',
          value: _format(data.todayLogins),
        ),
    ];
    return tiles.take(4).toList();
  }
}

class _StatTileData {
  const _StatTileData({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.tile});

  final _StatTileData tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tile.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tile.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(tile.icon, size: 18, color: tile.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tile.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: tile.color,
                    height: 1,
                  ),
                ),
                Text(
                  tile.label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: HomeApprovedDesign.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
