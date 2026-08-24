import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../feed/domain/entities/platform_stats_entity.dart';
import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../theme/home_approved_design.dart';

/// Kompakt şerit + genişletilmiş istatistik ızgarası — `GET /api/public-stats`.
class HomePlatformStatsSection extends ConsumerStatefulWidget {
  const HomePlatformStatsSection({super.key});

  @override
  ConsumerState<HomePlatformStatsSection> createState() =>
      _HomePlatformStatsSectionState();
}

class _HomePlatformStatsSectionState extends ConsumerState<HomePlatformStatsSection> {
  var _expanded = false;

  static String _format(int n) =>
      NumberFormat.compact(locale: 'tr').format(n);

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(platformStatsProvider);
    return stats.when(
      loading: () => const SizedBox(height: 4),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        final hasStrip = data.onlineUsers > 0 ||
            data.onLive > 0 ||
            data.inVoiceChat > 0;
        final extraTiles = _extraTilesFor(data);
        if (!hasStrip && extraTiles.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            if (hasStrip)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HomeApprovedDesign.hPad,
                  0,
                  HomeApprovedDesign.hPad,
                  8,
                ),
                child: Row(
                  children: [
                    if (data.onlineUsers > 0)
                      Expanded(
                        child: _StripPill(
                          icon: Icons.groups_rounded,
                          color: HomeApprovedDesign.purple,
                          label: 'Çevrimiçi',
                          value: _format(data.onlineUsers),
                        ),
                      ),
                    if (data.onlineUsers > 0 && data.onLive > 0)
                      const SizedBox(width: 8),
                    if (data.onLive > 0)
                      Expanded(
                        child: _StripPill(
                          icon: Icons.sensors_rounded,
                          color: HomeApprovedDesign.liveRed,
                          label: 'Canlı',
                          value: _format(data.onLive),
                        ),
                      ),
                    if (data.onLive > 0 && data.inVoiceChat > 0)
                      const SizedBox(width: 8),
                    if (data.inVoiceChat > 0)
                      Expanded(
                        child: _StripPill(
                          icon: Icons.mic_rounded,
                          color: const Color(0xFF4DA6FF),
                          label: 'Sesli',
                          value: _format(data.inVoiceChat),
                        ),
                      ),
                  ],
                ),
              ),
            if (extraTiles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                child: Row(
                  children: [
                    const Text(
                      '📊 Canlı İstatistikler',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _expanded ? 'Gizle' : 'Detay',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HomeApprovedDesign.purple,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/profile/broadcaster-stats'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Tümü >',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HomeApprovedDesign.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    HomeApprovedDesign.hPad,
                    0,
                    HomeApprovedDesign.hPad,
                    8,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 8.0;
                      final tileW = (constraints.maxWidth - spacing) / 2;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final tile in extraTiles)
                            SizedBox(
                              width: tileW,
                              child: _GridTile(tile: tile),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  static List<_StatTileData> _extraTilesFor(PlatformStatsEntity data) {
    return [
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
    ].take(4).toList();
  }
}

class _StripPill extends StatelessWidget {
  const _StripPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
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

class _GridTile extends StatelessWidget {
  const _GridTile({required this.tile});

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
