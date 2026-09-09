import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/voice_room_ranking_provider.dart';

/// Saatlik / günlük oda sıralaması — Top 100.
Future<void> showVoiceRoomRankingSheet(
  BuildContext context,
  WidgetRef ref, {
  VoiceRoomRankingPeriod initial = VoiceRoomRankingPeriod.hourly,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _VoiceRoomRankingSheet(initial: initial),
  );
}

class _VoiceRoomRankingSheet extends ConsumerStatefulWidget {
  const _VoiceRoomRankingSheet({required this.initial});

  final VoiceRoomRankingPeriod initial;

  @override
  ConsumerState<_VoiceRoomRankingSheet> createState() =>
      _VoiceRoomRankingSheetState();
}

class _VoiceRoomRankingSheetState extends ConsumerState<_VoiceRoomRankingSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initial == VoiceRoomRankingPeriod.hourly ? 0 : 1,
    );
    Future.microtask(
      () => ref.read(voiceRoomRankingProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(voiceRoomRankingProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            '🏆 Oda Sıralaması',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: const Color(0xFFB832FF),
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFFB832FF),
            tabs: const [
              Tab(text: 'Saatlik'),
              Tab(text: 'Günlük'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _RankList(entries: ranking.hourly, scroll: scroll),
                _RankList(entries: ranking.daily, scroll: scroll),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
            child: Text(
              'Skor proxy: çevrimiçi (SSE keşfet) + PK + müzik. Üretim ROOM_RANK API ile güncellenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({required this.entries, required this.scroll});

  final List<VoiceRoomRankEntry> entries;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('Sıralama yükleniyor…', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: entries.length,
      itemBuilder: (_, i) => _RankRow(entry: entries[i]),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final VoiceRoomRankEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}.',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: entry.rank <= 3 ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.rank <= 3
              ? const Color(0xFFFFD54F).withValues(alpha: 0.35)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              medal,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: entry.rank <= 3 ? const Color(0xFFFFD54F) : Colors.white70,
                fontSize: entry.rank <= 3 ? 18 : 13,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.room.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (entry.room.ownerName?.trim().isNotEmpty == true)
                  Text(
                    entry.room.ownerName!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.room.displayOnline}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                '${entry.score} puan',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
