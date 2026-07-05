import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../domain/gift_leaderboard_entry.dart';
import '../providers/gift_insights_providers.dart';

/// Hediye Liderlik Merkezi — gönderenler/alıcılar; TR/Dünya; dönem; kategori.
class GiftLeaderboardCenterPage extends ConsumerWidget {
  const GiftLeaderboardCenterPage({super.key});

  static const _periods = <(String, String)>[
    ('daily', 'Günlük'),
    ('weekly', 'Haftalık'),
    ('monthly', 'Aylık'),
    ('yearly', 'Yıllık'),
    ('all', 'Tümü'),
  ];

  static const _contexts = <(String, String)>[
    ('all', 'Tümü'),
    ('live_stream', 'Canlı Yayın'),
    ('voice_room', 'Sesli Sohbet'),
    ('video', 'Videolar'),
    ('short_video', 'Kısa Video'),
    ('fortune', 'Falcılar'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(giftLeaderboardFilterProvider);
    final data = ref.watch(giftLeaderboardProvider(filter));
    final notifier = ref.read(giftLeaderboardFilterProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12082A),
        title: const Text('Hediye Liderlik Merkezi'),
        actions: [
          IconButton(
            tooltip: 'Hediye Merkezi',
            icon: const Icon(Icons.workspaces_rounded),
            onPressed: () => context.push('/gifts/hub'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Gönderenler / Alanlar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'senders', label: Text('Gönderenler')),
                    ButtonSegment(value: 'receivers', label: Text('Alanlar')),
                  ],
                  selected: {filter.type},
                  onSelectionChanged: (s) =>
                      notifier.state = filter.copyWith(type: s.first),
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: 6),
              // TR / Dünya + dönem
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _chip('🇹🇷 Türkiye', filter.scope == 'tr',
                        () => notifier.state = filter.copyWith(scope: 'tr')),
                    _chip('🌍 Dünya', filter.scope == 'world',
                        () => notifier.state = filter.copyWith(scope: 'world')),
                    const SizedBox(width: 12),
                    for (final p in _periods)
                      _chip(p.$2, filter.period == p.$1,
                          () => notifier.state = filter.copyWith(period: p.$1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Kategori
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                for (final c in _contexts)
                  _chip(c.$2, filter.context == c.$1,
                      () => notifier.state = filter.copyWith(context: c.$1)),
              ],
            ),
          ),
          Expanded(
            child: data.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Yüklenemedi',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'Bu dönemde kayıt yok',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(giftLeaderboardProvider(filter)),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _RankRow(entry: entries[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: const Color(0xFF1E1030),
        selectedColor: const Color(0xFF7C3AED),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final GiftLeaderboardEntry entry;

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  Color get _rankColor => switch (entry.rank) {
        1 => const Color(0xFFFFD54F),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => Colors.white54,
      };

  @override
  Widget build(BuildContext context) {
    final loc = [entry.city, entry.country]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(', ');
    final container = Container(
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
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2A1A45),
            backgroundImage:
                entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                    ? canlifalImageProvider(entry.avatarUrl!)
                    : null,
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white54, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (entry.level != null) ...[
                      const SizedBox(width: 6),
                      _pill('Lv${entry.level}', const Color(0xFF7C3AED)),
                    ],
                    if (entry.badge != null && entry.badge!.trim().isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _pill(entry.badge!, const Color(0xFFB8860B)),
                    ],
                  ],
                ),
                if (loc.isNotEmpty)
                  Text(
                    loc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: Color(0xFFFFD54F), size: 14),
                  const SizedBox(width: 3),
                  Text(
                    _fmt(entry.totalCoins),
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '${entry.giftCount} hediye',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (entry.userId == null || entry.userId!.trim().isEmpty) return container;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () =>
          context.push('/gifts/collection?userId=${entry.userId}'),
      child: container,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
