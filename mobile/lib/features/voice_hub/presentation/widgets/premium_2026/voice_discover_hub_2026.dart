import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_room_card.dart';
import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../../../../../core/performance/list_perf.dart';
import '../../../../../core/performance/scroll_perf.dart';
import '../../../../../core/widgets/lazy_list_views.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/pk/pk_opponent_room_filter.dart';
import 'package:canlifal_social/features/vip_gold/domain/voice_room_access.dart';
import 'package:canlifal_social/features/vip_gold/presentation/theme/vip_gold_tokens.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import '../../providers/voice_room_ranking_provider.dart';
import '../../providers/voice_rooms_presence_provider.dart';
import '../../sheets/voice_room_preview_sheet.dart';
import '../../sheets/voice_room_ranking_sheet.dart';
import '../../utils/open_voice_chat_room_flow.dart';
import 'voice_discover_header_band.dart';
import '../../utils/voice_discover_ranking.dart';
import '../voice_room_online_count.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_discover_2026.dart';

/// Keşfet — referans görsel (header, sekmeler, hikaye, banner, popüler, canlı, grid, VIP).
class VoiceDiscoverHub2026 extends ConsumerStatefulWidget {
  const VoiceDiscoverHub2026({
    super.key,
    required this.rooms,
    required this.liveStreams,
    required this.onRoomTap,
    required this.onSearchChanged,
    this.onLoadMore,
    this.topPadding = 0,
  });

  final List<VoiceRoomEntity> rooms;
  final List<LiveStreamEntity> liveStreams;
  final ValueChanged<VoiceRoomEntity> onRoomTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onLoadMore;
  final double topPadding;

  @override
  ConsumerState<VoiceDiscoverHub2026> createState() =>
      _VoiceDiscoverHub2026State();
}

class _VoiceDiscoverHub2026State extends ConsumerState<VoiceDiscoverHub2026> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  String _tab = 'discover';
  int _visibleRooms = ListPerf.defaultPageSize;
  List<VoiceRoomEntity>? _cachedFiltered;
  List<VoiceRoomEntity>? _cachedRoomsRef;
  String _cachedTab = '';
  String _cachedSearch = '';
  Map<String, int>? _cachedCatCounts;
  Map<String, int>? _cachedHourlyRanks;
  List<VoiceRoomRankEntry>? _cachedHourlyRankingRef;

  static const _tabs = [
    _DiscoverTab(id: 'discover', label: 'Keşfet', icon: Icons.explore_rounded),
    _DiscoverTab(id: 'popular', label: 'Popüler', icon: Icons.local_fire_department_rounded),
    _DiscoverTab(id: 'live', label: 'Canlı', icon: Icons.live_tv_rounded),
    _DiscoverTab(id: 'game', label: 'Oyun', icon: Icons.sports_esports_rounded),
    _DiscoverTab(id: 'music', label: 'Müzik', icon: Icons.music_note_rounded),
    _DiscoverTab(id: 'pk', label: 'PK', icon: Icons.flash_on_rounded),
    _DiscoverTab(id: 'more', label: 'Daha Fazla', icon: Icons.more_horiz_rounded),
  ];

  static const _gridCats = [
    _GridCat('night', 'Gece Sohbeti', Icons.nightlight_round, Color(0xFF7C4DFF)),
    _GridCat('game', 'Oyun', Icons.sports_esports_rounded, Color(0xFF00E5C3)),
    _GridCat('music', 'Müzik', Icons.music_note_rounded, Color(0xFFFF2D7A)),
    _GridCat('fortune', 'Fal & Tarot', Icons.auto_awesome_rounded, Color(0xFFFFD54F)),
    _GridCat('pk', 'PK Odaları', Icons.flash_on_rounded, Color(0xFFB832FF)),
    _GridCat('fun', 'Eğlence', Icons.celebration_rounded, Color(0xFF5B8CFF)),
    _GridCat('social', 'Flört', Icons.favorite_rounded, Color(0xFFFF6B9D)),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncVisiblePresence());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - ListPerf.preloadThresholdPx) {
      final total = _filtered.length;
      if (_visibleRooms < total) {
        setState(() {
          _visibleRooms = (_visibleRooms + ListPerf.defaultPageSize)
              .clamp(0, total);
        });
        _syncVisiblePresence();
      } else {
        widget.onLoadMore?.call();
      }
    }
  }

  void _syncVisiblePresence() {
    final spotlight = _popularRooms.take(3).toList(growable: false);
    final visible = _filtered
        .take(_visibleRooms.clamp(0, _filtered.length))
        .toList(growable: false);
    final track = pickDiscoverPresenceTrackRooms(
      spotlight: spotlight,
      visible: visible,
    );
    if (track.isEmpty) return;
    ref.read(voiceRoomsPresenceProvider.notifier).mergeTrackRooms(track);
  }

  void _resetVisibleRooms() {
    _visibleRooms = ListPerf.defaultPageSize.clamp(0, _filtered.length);
  }

  List<VoiceRoomEntity> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (_cachedFiltered != null &&
        identical(_cachedRoomsRef, widget.rooms) &&
        _cachedTab == _tab &&
        _cachedSearch == q) {
      return _cachedFiltered!;
    }
    var list = widget.rooms;
    if (q.isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.displayTitle.toLowerCase().contains(q) ||
                r.slug.toLowerCase().contains(q) ||
                (r.ownerName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    final liveCounts = ref.read(voiceRoomsPresenceProvider).counts;
    final result = switch (_tab) {
      'popular' => orderDiscoverRoomsByProxyRanking(
          list,
          livePresenceCounts: liveCounts,
        ),
      'pk' => filterPkEligibleOpponentRooms(list),
      'game' => list.where((r) {
        final t = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
        return t.contains('oyun');
      }).toList(),
      'music' => list.where((r) {
        final t = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
        return t.contains('müzik') || t.contains('music');
      }).toList(),
      'live' => list.where((r) => r.displayOnline > 0).toList(),
      _ => list,
    };
    _cachedRoomsRef = widget.rooms;
    _cachedTab = _tab;
    _cachedSearch = q;
    _cachedFiltered = result;
    _cachedCatCounts = null;
    return result;
  }

  List<VoiceRoomEntity> get _popularRooms {
    final liveCounts = ref.read(voiceRoomsPresenceProvider).counts;
    return orderDiscoverRoomsByProxyRanking(
      widget.rooms,
      livePresenceCounts: liveCounts,
    );
  }

  Map<String, int> _hourlyRankMap(List<VoiceRoomRankEntry> hourly) {
    if (_cachedHourlyRankingRef == hourly && _cachedHourlyRanks != null) {
      return _cachedHourlyRanks!;
    }
    final map = <String, int>{};
    for (final entry in hourly) {
      if (entry.rank > 10) break;
      final key = entry.room.apiRoomKey.isNotEmpty
          ? entry.room.apiRoomKey
          : entry.room.id;
      if (key.isEmpty) continue;
      map[key] = entry.rank;
      map[entry.room.id] = entry.rank;
    }
    _cachedHourlyRankingRef = hourly;
    _cachedHourlyRanks = map;
    return map;
  }

  _DiscoverMetrics _metrics(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 360;
    final tablet = w >= 600;
    return _DiscoverMetrics(
      horizontalPad: tablet ? 24.0 : (compact ? 12.0 : 16.0),
      popularCardWidth: (w * 0.44).clamp(148.0, 200.0),
      popularRowHeight: tablet ? 240.0 : 220.0,
      bannerHeight: (w * 0.36).clamp(128.0, 168.0),
      gridColumns: tablet ? 4 : (w >= 400 ? 4 : 3),
      storiesHeight: tablet ? 116.0 : 108.0,
      sectionTitleSize: tablet ? 20.0 : 18.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics(context);
    final hourlyRanking =
        ref.watch(voiceRoomRankingProvider.select((s) => s.hourly));
    final rankMap = _hourlyRankMap(hourlyRanking);
    final popular = _popularRooms;
    final live = widget.liveStreams.where((s) => s.isLive).toList();

    ref.listen(voiceRoomRankingProvider.select((s) => s.lastUpdated), (
      prev,
      next,
    ) {
      if (prev != next) {
        _cachedFiltered = null;
        _cachedHourlyRanks = null;
      }
    });
    ref.listen(voiceRoomsPresenceProvider.select((s) => s.counts), (_, __) {
      _cachedFiltered = null;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: widget.topPadding),
        VoiceDiscoverHeaderBand(horizontalPad: metrics.horizontalPad),
        Padding(
          padding: EdgeInsets.fromLTRB(metrics.horizontalPad, 12, metrics.horizontalPad, 0),
          child: _SearchBar(
            controller: _searchCtrl,
            onChanged: (v) {
              widget.onSearchChanged(v);
              setState(_resetVisibleRooms);
            },
          ),
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPad),
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = _tabs[i];
                final active = _tab == t.id;
                return _TabChip(
                  tab: t,
                  active: active,
                  onTap: () {
                    setState(() {
                      _tab = t.id;
                      _resetVisibleRooms();
                    });
                    _syncVisiblePresence();
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        RepaintBoundary(
          child: _LiveStoriesRow(
            live: live,
            hotRooms: popular
                .where((r) => r.displayOnline > 0 || r.isPkLive || r.hasMusicActivity)
                .take(4)
                .toList(growable: false),
            height: metrics.storiesHeight,
            horizontalPad: metrics.horizontalPad,
            onOpenRoom: () => showOpenVoiceChatRoomFlow(context, ref),
            onStreamTap: (s) => openLiveFromDiscover(context, ref, s),
            onRoomTap: widget.onRoomTap,
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollCacheExtent: ScrollPerf.scrollCache(ListPerf.cacheExtent),
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPad,
              16,
              metrics.horizontalPad,
              100,
            ),
            itemCount: _listChildCount(),
            itemBuilder: (context, index) => _buildListChild(
              context,
              index: index,
              metrics: metrics,
              popular: popular,
              live: live,
              rankMap: rankMap,
            ),
          ),
        ),
      ],
    );
  }

  int _listChildCount() {
    const n = 8; // banner, titles, horizontals, grid, footer label
    final roomVisible = _visibleRooms.clamp(0, _filtered.length);
    return n + roomVisible + (_visibleRooms < _filtered.length ? 1 : 0);
  }

  Widget _buildListChild(
    BuildContext context, {
    required int index,
    required _DiscoverMetrics metrics,
    required List<VoiceRoomEntity> popular,
    required List<LiveStreamEntity> live,
    required Map<String, int> rankMap,
  }) {
    var i = index;
    if (i == 0) {
      return _NightBanner(
        height: metrics.bannerHeight,
        onJoin: popular.isNotEmpty ? () => widget.onRoomTap(popular.first) : null,
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: _SectionTitle(
          title: 'Popüler Odalar',
          action: 'Tümü',
          fontSize: metrics.sectionTitleSize,
          onActionTap: () => showVoiceRoomRankingSheet(context, ref),
        ),
      );
    }
    i--;
    if (i == 0) {
      return RepaintBoundary(
        child: SizedBox(
          height: metrics.popularRowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popular.take(10).length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, j) {
              final room = popular[j];
              final rank = rankMap[room.apiRoomKey] ?? rankMap[room.id];
              return DiscoverPremiumRoomCard(
                room: room,
                width: metrics.popularCardWidth,
                hourlyRank: rank,
                onTap: () => widget.onRoomTap(room),
              );
            },
          ),
        ),
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: _SectionTitle(
          title: 'Canlı Yayınlar',
          action: 'Tümü',
          fontSize: metrics.sectionTitleSize,
        ),
      );
    }
    i--;
    if (i == 0) {
      if (live.isEmpty) {
        return Text(
          'Şu an canlı yayın yok',
          style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.9)),
        );
      }
      return RepaintBoundary(
        child: SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: live.length.clamp(0, 12),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, j) => _LiveStreamCard(
              stream: live[j],
              onTap: () => openLiveFromDiscover(context, ref, live[j]),
            ),
          ),
        ),
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: _SectionTitle(
          title: 'Kategoriler',
          action: null,
          fontSize: metrics.sectionTitleSize,
        ),
      );
    }
    i--;
    if (i == 0) {
      const spacing = 10.0;
      final aspectRatio = metrics.gridColumns >= 4 ? 0.82 : 0.88;
      final gridWidth = MediaQuery.sizeOf(context).width -
          metrics.horizontalPad * 2;
      final gridHeight = ListPerf.nestedGridHeight(
        itemCount: _gridCats.length,
        crossAxisCount: metrics.gridColumns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
        crossAxisExtent: gridWidth,
      );
      return SizedBox(
        height: gridHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: metrics.gridColumns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _gridCats.length,
          itemBuilder: (context, j) {
            final c = _gridCats[j];
            final count = _roomCountForCat(c.id);
            return _CategoryIconTile(
              cat: c,
              roomLabel: count > 0
                  ? '${VoiceLiveHeader2026Format.count(count)} oda'
                  : '—',
              onTap: () {
                setState(() {
                  _tab = c.id == 'night' ? 'discover' : c.id;
                  _resetVisibleRooms();
                });
              },
            );
          },
        ),
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(
          'Tüm odalar · ${_filtered.length}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
          ),
        ),
      );
    }
    i--;
    final roomIndex = i;
    final visible = _visibleRooms.clamp(0, _filtered.length);
    if (roomIndex < visible) {
      final r = _filtered[roomIndex];
      final rank = rankMap[r.apiRoomKey] ?? rankMap[r.id];
      return ListPerf.repaint(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CompactRoomRow(
            room: r,
            hourlyRank: rank,
            onTap: () => widget.onRoomTap(r),
            onLongPress: () => showVoiceRoomPreviewSheet(context, ref, room: r),
          ),
        ),
      );
    }
    if (roomIndex == visible && _visibleRooms < _filtered.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  int _roomCountForCat(String id) {
    _cachedCatCounts ??= {
      for (final c in _gridCats) c.id: _computeCatCount(c.id),
    };
    return _cachedCatCounts![id] ?? 0;
  }

  int _computeCatCount(String id) {
    return switch (id) {
      'pk' => filterPkEligibleOpponentRooms(widget.rooms).length,
      'game' => widget.rooms.where((r) {
          final t = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
          return t.contains('oyun');
        }).length,
      _ => (widget.rooms.length / 4).ceil(),
    };
  }
}

void openLiveFromDiscover(
  BuildContext context,
  WidgetRef ref,
  LiveStreamEntity stream,
) {
  openLiveStreamNative(context, ref, stream);
}

class _DiscoverMetrics {
  const _DiscoverMetrics({
    required this.horizontalPad,
    required this.popularCardWidth,
    required this.popularRowHeight,
    required this.bannerHeight,
    required this.gridColumns,
    required this.storiesHeight,
    required this.sectionTitleSize,
  });

  final double horizontalPad;
  final double popularCardWidth;
  final double popularRowHeight;
  final double bannerHeight;
  final int gridColumns;
  final double storiesHeight;
  final double sectionTitleSize;
}

class _DiscoverTab {
  const _DiscoverTab({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

class _GridCat {
  const _GridCat(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
      blur: DiscoverPremiumVisual.glassBlur,
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.65)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Oda, kullanıcı veya kategori ara…',
                hintStyle: TextStyle(
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.45)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.tab, required this.active, required this.onTap});

  final _DiscoverTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: active ? DiscoverPremiumVisual.brandGradient : null,
            color: active ? null : DiscoverPremiumVisual.glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? DiscoverPremiumVisual.secondary.withValues(alpha: 0.35)
                  : DiscoverPremiumVisual.glassBorder,
            ),
            boxShadow: active ? DiscoverPremiumVisual.cardGlow(pressed: true) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: active ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStoriesRow extends StatelessWidget {
  const _LiveStoriesRow({
    required this.live,
    required this.hotRooms,
    required this.height,
    required this.horizontalPad,
    required this.onOpenRoom,
    required this.onStreamTap,
    required this.onRoomTap,
  });

  final List<LiveStreamEntity> live;
  final List<VoiceRoomEntity> hotRooms;
  final double height;
  final double horizontalPad;
  final VoidCallback onOpenRoom;
  final ValueChanged<LiveStreamEntity> onStreamTap;
  final ValueChanged<VoiceRoomEntity> onRoomTap;

  @override
  Widget build(BuildContext context) {
    final streams = live.take(6).toList(growable: false);
    final rooms = hotRooms.take(4).toList(growable: false);
    final itemCount = 1 + rooms.length + streams.length;
    return SizedBox(
      height: height,
      child: LazyHorizontalListView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StoryOpenRoom(onTap: onOpenRoom);
          }
          var i = index - 1;
          if (i < rooms.length) {
            final room = rooms[i];
            return Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _StoryVoiceRoomItem(
                room: room,
                onTap: () => onRoomTap(room),
              ),
            );
          }
          i -= rooms.length;
          final stream = streams[i];
          return Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _StoryLiveItem(stream: stream, onTap: () => onStreamTap(stream)),
          );
        },
      ),
    );
  }
}

class _StoryVoiceRoomItem extends ConsumerWidget {
  const _StoryVoiceRoomItem({required this.room, required this.onTap});

  final VoiceRoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showPk = room.isPkLive;
    final showMusic = room.hasMusicActivity;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: showPk
                        ? [const Color(0xFFFF5252), VoiceRoomTokens.neonPink]
                        : [VoiceRoomTokens.neonPurple, VoiceRoomTokens.neonBlue],
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white12,
                  child: Text(
                    room.icon ?? '🎤',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              if (showPk || showMusic)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: showPk
                          ? AppThemeColors.liveRed
                          : const Color(0xFFFFD54F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      showPk ? 'PK' : '♪',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 72,
            child: Text(
              room.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          VoiceRoomOnlineCount(
            room: room,
            builder: (context, count) => Text(
              VoiceLiveHeader2026Format.count(count),
              style: TextStyle(
                fontSize: 9,
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryOpenRoom extends StatelessWidget {
  const _StoryOpenRoom({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DiscoverPremiumVisual.brandGradient,
              boxShadow: DiscoverPremiumVisual.cardGlow(),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 6),
          const Text(
            'Oda Aç',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StoryLiveItem extends StatelessWidget {
  const _StoryLiveItem({required this.stream, required this.onTap});

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = stream.streamerName ?? stream.title;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppThemeColors.liveRed, VoiceRoomTokens.neonPink],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              backgroundImage: stream.thumbnailUrl != null &&
                      stream.thumbnailUrl!.isNotEmpty
                  ? canlifalImageProvider(stream.thumbnailUrl!)
                  : null,
              child: stream.thumbnailUrl == null || stream.thumbnailUrl!.isEmpty
                  ? Text(name.isNotEmpty ? name[0] : '?')
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppThemeColors.liveRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 72,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            VoiceLiveHeader2026Format.count(stream.viewerCount),
            style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _NightBanner extends StatelessWidget {
  const _NightBanner({required this.height, required this.onJoin});

  final double height;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        gradient: const LinearGradient(
          colors: [
            DiscoverPremiumVisual.primary,
            DiscoverPremiumVisual.backgroundMid,
          ],
        ),
        boxShadow: DiscoverPremiumVisual.cardGlow(),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.mic_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GECE MUHABBETİ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sesli sohbet — hemen katıl',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: VoiceRoomTokens.neonPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Hemen Katıl',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.fontSize = 18,
    this.onActionTap,
  });

  final String title;
  final String? action;
  final double fontSize;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: fontSize),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onActionTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                action!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: DiscoverPremiumVisual.secondary.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PopularRoomCard extends StatelessWidget {
  const _PopularRoomCard({
    required this.room,
    required this.index,
    required this.width,
    required this.onTap,
  });

  final VoiceRoomEntity room;
  final int index;
  final double width;
  final VoidCallback onTap;

  String get _badge => switch (room.resolvedRoomType) {
        'VIP' => 'VIP',
        'FREE' => 'Ücretsiz',
        _ => switch (index % 3) {
            0 => 'Sıcak',
            1 => 'Gece',
            _ => 'Oyun',
          },
      };

  Color get _badgeColor => switch (_badge) {
        'VIP' => VipGoldTokens.goldMid,
        'Ücretsiz' => const Color(0xFF22C55E),
        'Sıcak' => AppThemeColors.liveRed,
        'Gece' => VoiceRoomTokens.neonPurple,
        _ => VoiceRoomTokens.neonBlue,
      };

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              color: DiscoverPremiumVisual.glassFill,
              boxShadow: DiscoverPremiumVisual.cardGlow(),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (bg != null && bg.isNotEmpty)
                          CanlifalNetworkImage(
                            url: bg,
                            width: width,
                            thumbnailWidth: (width * 1.5).round().clamp(160, 400),
                            fit: BoxFit.cover,
                          )
                        else
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4C1D95), Color(0xFF1E1033)],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _badgeColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _badge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded,
                                size: 12, color: AppThemeColors.onlineGreen),
                            const SizedBox(width: 4),
                            VoiceRoomOnlineCount(
                              room: room,
                              builder: (context, count) => Text(
                                VoiceLiveHeader2026Format.count(count),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: VoiceRoomTokens.fabGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Katıl',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.onTap});

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 200.0;
    final name = stream.streamerName ?? stream.title;
    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              boxShadow: DiscoverPremiumVisual.cardGlow(
                color: AppThemeColors.liveRed,
              ),
            ),
            child: ClipRRect(
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty)
                  CanlifalNetworkImage(
                    url: stream.thumbnailUrl!,
                    width: cardWidth,
                    thumbnailWidth: (cardWidth * 1.5).round().clamp(160, 400),
                    fit: BoxFit.cover,
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A1458), Color(0xFF0D0820)],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.liveRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            VoiceLiveHeader2026Format.count(stream.viewerCount),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Müzik Keyfi 🎵',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIconTile extends StatelessWidget {
  const _CategoryIconTile({
    required this.cat,
    required this.roomLabel,
    required this.onTap,
  });

  final _GridCat cat;
  final String roomLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DiscoverPremiumVisual.glassFill,
            borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            border: Border.all(color: DiscoverPremiumVisual.glassBorder),
            boxShadow: DiscoverPremiumVisual.cardGlow(color: cat.color),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.icon, color: cat.color, size: 26),
              const SizedBox(height: 6),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                roomLabel,
                style: TextStyle(
                  fontSize: 8,
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactRoomRow extends StatelessWidget {
  const _CompactRoomRow({
    required this.room,
    required this.onTap,
    this.onLongPress,
    this.hourlyRank,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int? hourlyRank;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DiscoverPremiumVisual.glassFill,
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            border: Border.all(color: DiscoverPremiumVisual.glassBorder),
            boxShadow: DiscoverPremiumVisual.cardGlow(),
          ),
          child: Row(
            children: [
              Text(room.icon ?? '🎤', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hourlyRank != null && hourlyRank! <= 3) ...[
                          _DiscoverRankChip(rank: hourlyRank!),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            room.displayTitle,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    VoiceRoomOnlineCount(
                      room: room,
                      builder: (context, count) => Text(
                        '${VoiceLiveHeader2026Format.count(count)} çevrimiçi',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverRankChip extends StatelessWidget {
  const _DiscoverRankChip({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.55)),
      ),
      child: Text(
        medal,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}
