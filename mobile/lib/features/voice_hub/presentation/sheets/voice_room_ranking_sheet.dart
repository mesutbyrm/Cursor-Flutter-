import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import 'voice_room_preview_sheet.dart';
import '../providers/voice_room_ranking_provider.dart';
import '../providers/voice_rooms_presence_provider.dart';
import '../utils/voice_room_ranking_labels.dart';

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

  Future<void> _refresh() =>
      ref.read(voiceRoomRankingProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final ranking = ref.watch(voiceRoomRankingProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final updatedLabel = ranking.lastUpdated == null
        ? null
        : 'Güncellendi · ${DateFormat('HH:mm').format(ranking.lastUpdated!)}';

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
          if (updatedLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              updatedLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                _RankList(
                  entries: ranking.hourly,
                  scroll: scroll,
                  period: VoiceRoomRankingPeriod.hourly,
                  onRefresh: _refresh,
                  onRoomTap: (room) => _openRoom(context, room),
                ),
                _RankList(
                  entries: ranking.daily,
                  scroll: scroll,
                  period: VoiceRoomRankingPeriod.daily,
                  onRefresh: _refresh,
                  onRoomTap: (room) => _openRoom(context, room),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
            child: Text(
              'Skor proxy: çevrimiçi (SSE keşfet) + PK + müzik. Üretim ROOM_RANK API ile güncellenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRoom(BuildContext context, VoiceRoomEntity room) async {
    Navigator.of(context).pop();
    if (!context.mounted) return;
    await openVoiceRoomWithVipGate(context, ref, room);
  }
}

class _RankList extends ConsumerWidget {
  const _RankList({
    required this.entries,
    required this.scroll,
    required this.period,
    required this.onRefresh,
    required this.onRoomTap,
  });

  final List<VoiceRoomRankEntry> entries;
  final ScrollController scroll;
  final VoiceRoomRankingPeriod period;
  final Future<void> Function() onRefresh;
  final ValueChanged<VoiceRoomEntity> onRoomTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCounts = ref.watch(
      voiceRoomsPresenceProvider.select((s) => s.counts),
    );
    final resetLabel = voiceRoomRankingResetLabel(period);

    if (entries.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFB832FF),
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'Sıralama yükleniyor…',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFB832FF),
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: _listItemCount(entries),
        itemBuilder: (_, i) => _buildListItem(
          context,
          index: i,
          entries: entries,
          liveCounts: liveCounts,
          resetLabel: resetLabel,
          onRoomTap: onRoomTap,
          onPreview: (room) => showVoiceRoomPreviewSheet(context, ref, room: room),
        ),
      ),
    );
  }
}

int _listItemCount(List<VoiceRoomRankEntry> entries) {
  final podium = entries.length >= 3 ? 1 : 0;
  final rest = entries.length >= 3 ? entries.length - 3 : entries.length;
  return 1 + podium + rest;
}

Widget _buildListItem(
  BuildContext context, {
  required int index,
  required List<VoiceRoomRankEntry> entries,
  required Map<String, int> liveCounts,
  required String resetLabel,
  required ValueChanged<VoiceRoomEntity> onRoomTap,
  required ValueChanged<VoiceRoomEntity> onPreview,
}) {
  if (index == 0) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        resetLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  if (entries.length >= 3 && index == 1) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _RankPodium(
        topThree: entries.take(3).toList(growable: false),
        liveCounts: liveCounts,
        onTap: onRoomTap,
      ),
    );
  }
  final offset = entries.length >= 3 ? index - 2 : index - 1;
  final entryIndex = entries.length >= 3 ? offset + 3 : offset;
  final entry = entries[entryIndex];
  return _RankRow(
    entry: entry,
    liveOnline: resolveLiveOnlineCount(entry.room, liveCounts),
    onTap: () => onRoomTap(entry.room),
    onPreview: () => onPreview(entry.room),
  );
}

class _RankPodium extends StatelessWidget {
  const _RankPodium({
    required this.topThree,
    required this.liveCounts,
    required this.onTap,
  });

  final List<VoiceRoomRankEntry> topThree;
  final Map<String, int> liveCounts;
  final ValueChanged<VoiceRoomEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final first = topThree[0];
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null)
          Expanded(
            child: _PodiumTile(
              entry: second,
              liveOnline: resolveLiveOnlineCount(second.room, liveCounts),
              height: 72,
              onTap: () => onTap(second.room),
            ),
          ),
        Expanded(
          child: _PodiumTile(
            entry: first,
            liveOnline: resolveLiveOnlineCount(first.room, liveCounts),
            height: 92,
            highlight: true,
            onTap: () => onTap(first.room),
          ),
        ),
        if (third != null)
          Expanded(
            child: _PodiumTile(
              entry: third,
              liveOnline: resolveLiveOnlineCount(third.room, liveCounts),
              height: 64,
              onTap: () => onTap(third.room),
            ),
          ),
      ],
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
    required this.entry,
    required this.liveOnline,
    required this.height,
    required this.onTap,
    this.highlight = false,
  });

  final VoiceRoomRankEntry entry;
  final int liveOnline;
  final double height;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}',
    };
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(medal, style: TextStyle(fontSize: highlight ? 26 : 20)),
          const SizedBox(height: 4),
          Text(
            entry.room.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 12 : 10,
            ),
          ),
          Text(
            '$liveOnline · ${entry.score}p',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: highlight
                    ? [const Color(0xFFFFD54F), const Color(0xFFB832FF)]
                    : [const Color(0xFF3D2066), const Color(0xFF1A0D33)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(
                color: highlight
                    ? const Color(0xFFFFD54F).withValues(alpha: 0.5)
                    : Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.entry,
    required this.liveOnline,
    required this.onTap,
    required this.onPreview,
  });

  final VoiceRoomRankEntry entry;
  final int liveOnline;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}.',
    };
    final room = entry.room;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onPreview,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                    color: entry.rank <= 3
                        ? const Color(0xFFFFD54F)
                        : Colors.white70,
                    fontSize: entry.rank <= 3 ? 18 : 13,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (room.ownerName?.trim().isNotEmpty == true)
                      Text(
                        room.ownerName!,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    if (room.isPkLive || room.hasMusicActivity)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: [
                            if (room.isPkLive) const _RankMiniBadge(label: 'PK'),
                            if (room.hasMusicActivity)
                              const _RankMiniBadge(label: 'Müzik'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$liveOnline',
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
              IconButton(
                onPressed: onPreview,
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                tooltip: 'Önizleme',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankMiniBadge extends StatelessWidget {
  const _RankMiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFB832FF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB832FF).withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE1BEE7),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
